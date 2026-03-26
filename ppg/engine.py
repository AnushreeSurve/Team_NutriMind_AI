# ============================================================
#  ppg/engine.py  —  BPM + HRV + Stress computation engine
#
#  Extracted from bpm_feature.py and converted into a clean,
#  importable module. All camera / display / UI code removed.
#  Call run_ppg_pipeline() with raw signal arrays from Flutter.
# ============================================================

import numpy as np
from scipy.signal import butter, filtfilt, detrend, find_peaks, welch, medfilt
from dataclasses import dataclass
from typing import Optional

# ── Constants ────────────────────────────────────────────────────────
HR_LOW_HZ      = 0.67
HR_HIGH_HZ     = 3.50
FILTER_ORDER   = 4
SNR_MIN        = 3.5
BPM_CROSS_TOL  = 12.0
ECTOPIC_THRESH = 0.20
MIN_SAMPLES    = 100   # lowered from 200 — phone sends faster than webcam

HRV_LOW_STRESS   = 50.0
HRV_MED_STRESS   = 30.0
RMSSD_LOW_STRESS = 40.0
RMSSD_MED_STRESS = 20.0


# ── Output dataclass ─────────────────────────────────────────────────

@dataclass
class PPGResult:
    bpm: float
    bpm_fft: float
    snr: float
    fps: float
    sdnn_ms: Optional[float]
    rmssd_ms: Optional[float]
    mean_rr_ms: Optional[float]
    bpm_from_rr: Optional[float]
    num_beats: Optional[int]
    stress_level: Optional[str]      # "LOW" | "MEDIUM" | "HIGH"
    confidence: str                  # "HIGH" | "MEDIUM" | "LOW"
    error: Optional[str] = None


# ── DSP functions (extracted verbatim from bpm_feature.py) ──────────

def _channel_fusion(r_sig, g_sig):
    r = np.array(r_sig, dtype=np.float64)
    g = np.array(g_sig, dtype=np.float64)
    r_n = (r - np.mean(r)) / (np.std(r) + 1e-9)
    g_n = (g - np.mean(g)) / (np.std(g) + 1e-9)
    return 0.4 * r_n + 0.6 * g_n


def _bandpass_filter(signal, fps, lo=None, hi=None):
    lo  = lo if lo is not None else HR_LOW_HZ
    hi  = hi if hi is not None else HR_HIGH_HZ
    nyq = fps / 2.0
    low  = float(np.clip(lo / nyq, 0.01, 0.99))
    high = float(np.clip(hi / nyq, 0.01, 0.99))
    if low >= high:
        high = min(low + 0.05, 0.99)
    b, a = butter(FILTER_ORDER, [low, high], btype='band')
    return filtfilt(b, a, signal)


def _zscore(signal):
    std = np.std(signal)
    if std < 1e-8:
        return None
    return (signal - np.mean(signal)) / std


def _remove_ectopic(rr_ms):
    if len(rr_ms) < 5:
        return rr_ms
    rr   = np.array(rr_ms)
    keep = np.ones(len(rr), dtype=bool)
    for i in range(len(rr)):
        lo_i = max(0, i - 2)
        hi_i = min(len(rr), i + 3)
        med  = np.median(rr[lo_i:hi_i])
        if abs(rr[i] - med) / (med + 1e-6) > ECTOPIC_THRESH:
            keep[i] = False
    return rr[keep]


def _compute_rr(peaks, fps):
    if len(peaks) < 2:
        return np.array([])
    rr = (np.diff(peaks) / fps) * 1000.0
    return rr[(rr >= 250) & (rr <= 2000)]


def _hrv_metrics(rr_raw):
    rr = _remove_ectopic(rr_raw)
    if len(rr) < 5:
        return None
    sdnn    = float(np.std(rr, ddof=1))
    rmssd   = float(np.sqrt(np.mean(np.diff(rr) ** 2))) if len(rr) > 1 else 0.0
    mean_rr = float(np.mean(rr))
    bpm_rr  = 60000.0 / mean_rr if mean_rr > 0 else 0.0
    return {"sdnn": sdnn, "rmssd": rmssd, "mean_rr": mean_rr,
            "bpm_from_rr": bpm_rr, "num_beats": len(rr) + 1}


def _classify_stress(sdnn, rmssd) -> str:
    def sdnn_l(s): return 0 if s > HRV_LOW_STRESS else (1 if s > HRV_MED_STRESS else 2)
    def rmssd_l(r): return 0 if r > RMSSD_LOW_STRESS else (1 if r > RMSSD_MED_STRESS else 2)
    return ["LOW", "MEDIUM", "HIGH"][max(sdnn_l(sdnn), rmssd_l(rmssd))]


def _welch_bpm(filtered, fps, prior_bpm=None):
    n       = len(filtered)
    nperseg = min(n, max(64, int(fps * 8)))
    freqs, psd = welch(filtered, fs=fps, nperseg=nperseg,
                       noverlap=nperseg // 2, window='hann')
    lo = max(HR_LOW_HZ, (prior_bpm - 20) / 60.0) if prior_bpm else HR_LOW_HZ
    hi = min(HR_HIGH_HZ, (prior_bpm + 20) / 60.0) if prior_bpm else HR_HIGH_HZ
    mask = (freqs >= lo) & (freqs <= hi)
    if not np.any(mask):
        mask = (freqs >= HR_LOW_HZ) & (freqs <= HR_HIGH_HZ)
    if not np.any(mask):
        return None, None
    band_psd   = psd[mask]
    band_freqs = freqs[mask]
    pk         = int(np.argmax(band_psd))
    if 0 < pk < len(band_psd) - 1:
        a, b, g = band_psd[pk-1], band_psd[pk], band_psd[pk+1]
        denom   = a - 2*b + g
        fr      = band_freqs[1] - band_freqs[0] if len(band_freqs) > 1 else 0.0
        peak_f  = band_freqs[pk] + (0.5*(a-g)/denom * fr if abs(denom) > 1e-12 else 0)
    else:
        peak_f = band_freqs[pk]
    snr = band_psd[pk] / (np.mean(band_psd) + 1e-12)
    if snr < SNR_MIN:
        return None, float(snr)
    return float(peak_f * 60.0), float(snr)


def _confidence_from_bpm_std(bpm_values: list) -> str:
    if len(bpm_values) < 3:
        return "LOW"
    std = float(np.std(bpm_values))
    if std < 4.0:
        return "HIGH"
    elif std < 9.0:
        return "MEDIUM"
    return "LOW"


# ── Public API ───────────────────────────────────────────────────────

def run_ppg_pipeline(
    timestamps: list[float],
    r_channel:  list[float],
    g_channel:  list[float],
    prior_bpm:  Optional[float] = None,
) -> PPGResult:
    """
    Main entry point called by ppg_service.py.

    Args:
        timestamps : Unix timestamps (seconds) for each sample.
        r_channel  : Red channel mean values per frame.
        g_channel  : Green channel mean values per frame.
        prior_bpm  : Last known BPM for adaptive bandpass (optional).

    Returns:
        PPGResult dataclass with all metrics.
    """
    def fail(msg): return PPGResult(0,0,0,0,None,None,None,None,None,None,"LOW",error=msg)

    if len(timestamps) < MIN_SAMPLES:
        return fail(f"Need {MIN_SAMPLES} samples, got {len(timestamps)}")

    t   = np.array(timestamps, dtype=np.float64)
    dur = t[-1] - t[0]
    if dur < 8.0:
        return fail("Signal too short (need ~10s)")

    fps = len(t) / dur
    if fps < 5:
        return fail(f"FPS too low: {fps:.1f}")

    # 1. Channel fusion
    sig = _channel_fusion(r_channel, g_channel)

    # 2. Median prefilter
    sig = medfilt(sig, kernel_size=5)

    # 3. Detrend
    sig = detrend(sig)

    # 4. Z-score
    sig = _zscore(sig)
    if sig is None:
        return fail("Flat signal — no PPG detected")

    # 5. Adaptive bandpass
    lo = max(HR_LOW_HZ, (prior_bpm - 25) / 60.0) if prior_bpm else HR_LOW_HZ
    hi = min(HR_HIGH_HZ, (prior_bpm + 25) / 60.0) if prior_bpm else HR_HIGH_HZ
    try:
        filtered = _bandpass_filter(sig, fps, lo=lo, hi=hi)
    except Exception as e:
        return fail(f"Filter error: {e}")

    # 6. Amplitude check
    amp = np.percentile(filtered, 95) - np.percentile(filtered, 5)
    if amp < 0.05:
        return fail("Signal amplitude too low")

    # 7. Welch BPM
    bpm_fft, snr = _welch_bpm(filtered, fps, prior_bpm=prior_bpm)
    if bpm_fft is None:
        return fail(f"Low SNR — hold finger still (SNR={snr:.1f})")

    # 8. Peak detect → RR → HRV
    amp_range   = np.percentile(filtered, 95) - np.percentile(filtered, 5)
    prominence  = max(0.15, amp_range * 0.30)
    min_dist    = max(3, int(fps * 60.0 / (HR_HIGH_HZ * 60.0)))
    peaks, _    = find_peaks(filtered, distance=min_dist, prominence=prominence)
    rr_ms       = _compute_rr(peaks, fps)
    hrv         = _hrv_metrics(rr_ms)

    # 9. BPM cross-check
    bpm_final = bpm_fft
    if hrv and hrv["bpm_from_rr"] > 0:
        if abs(bpm_fft - hrv["bpm_from_rr"]) > BPM_CROSS_TOL:
            bpm_final = 0.4 * bpm_fft + 0.6 * hrv["bpm_from_rr"]

    # 10. Confidence (based on last few BPM readings — simplified here)
    confidence = "HIGH" if snr > 6.0 else ("MEDIUM" if snr > SNR_MIN else "LOW")

    return PPGResult(
        bpm         = round(bpm_final, 1),
        bpm_fft     = round(bpm_fft, 1),
        snr         = round(snr, 2),
        fps         = round(fps, 1),
        sdnn_ms     = round(hrv["sdnn"],       1) if hrv else None,
        rmssd_ms    = round(hrv["rmssd"],      1) if hrv else None,
        mean_rr_ms  = round(hrv["mean_rr"],    1) if hrv else None,
        bpm_from_rr = round(hrv["bpm_from_rr"],1) if hrv else None,
        num_beats   = hrv["num_beats"] if hrv else None,
        stress_level= _classify_stress(hrv["sdnn"], hrv["rmssd"]) if hrv else None,
        confidence  = confidence,
    )
