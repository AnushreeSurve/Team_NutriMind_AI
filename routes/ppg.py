# ============================================================
#  routes/ppg.py  —  POST /ppg/analyze  |  POST /ppg/submit-reading
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.ppg_schema import PPGAnalyzeRequest, PPGReadingRequest, PPGResponse
from services.ppg_service import analyze_only, analyze_and_save

router = APIRouter()


@router.post("/analyze", response_model=PPGResponse)
def analyze_ppg(req: PPGAnalyzeRequest):
    """
    Analyze raw PPG signal and return BPM + HRV + Stress.
    Does NOT save to database — use for live feedback during measurement.

    Flutter sends this every ~5 seconds while the user holds their finger.
    """
    result = analyze_only(req.timestamps, req.r_channel, req.g_channel, req.prior_bpm)

    if result.error:
        raise HTTPException(status_code=422, detail=result.error)

    return PPGResponse(
        bpm          = result.bpm,
        bpm_fft      = result.bpm_fft,
        snr          = result.snr,
        fps          = result.fps,
        sdnn_ms      = result.sdnn_ms,
        rmssd_ms     = result.rmssd_ms,
        mean_rr_ms   = result.mean_rr_ms,
        bpm_from_rr  = result.bpm_from_rr,
        num_beats    = result.num_beats,
        stress_level = result.stress_level,
        confidence   = result.confidence,
        metabolic_state = None,
        saved        = False,
    )


@router.post("/submit-reading", response_model=PPGResponse)
def submit_ppg_reading(req: PPGReadingRequest):
    """
    Full pipeline: analyze → update metabolic state → save to Supabase.
    Call this once at the END of a PPG session (when user lifts finger).

    Saves to morning_checkins. Raises alert if stress is HIGH.
    """
    result = analyze_and_save(
        email      = req.email,
        timestamps = req.timestamps,
        r_channel  = req.r_channel,
        g_channel  = req.g_channel,
        prior_bpm  = req.prior_bpm,
    )

    if "error" in result and not result.get("saved"):
        raise HTTPException(status_code=422, detail=result["error"])

    return PPGResponse(**{
        k: result.get(k)
        for k in PPGResponse.model_fields
    })


@router.get("/test")
def ppg_test():
    """Quick health check for the PPG module."""
    return {
        "status": "PPG module active",
        "endpoints": [
            "POST /ppg/analyze       — live feedback (no DB save)",
            "POST /ppg/submit-reading — final save + metabolic update",
        ]
    }
