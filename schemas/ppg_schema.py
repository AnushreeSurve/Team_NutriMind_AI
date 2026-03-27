# ============================================================
#  schemas/ppg_schema.py  —  Request & Response shapes for PPG
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional


class PPGReadingRequest(BaseModel):
    """
    Sent by Flutter after capturing a PPG session.
    Flutter sends pre-extracted channel means per frame
    (not raw video — reduces payload size dramatically).
    """
    email:       str
    timestamps:  list[float] = Field(..., description="Unix timestamps per frame (seconds)")
    r_channel:   list[float] = Field(..., description="Red channel mean per frame")
    g_channel:   list[float] = Field(..., description="Green channel mean per frame")
    prior_bpm:   Optional[float] = None  # last known BPM for adaptive filtering


class PPGAnalyzeRequest(BaseModel):
    """
    Lightweight version — just analyze, don't save to DB.
    Useful for real-time feedback during measurement.
    """
    timestamps: list[float]
    r_channel:  list[float]
    g_channel:  list[float]
    prior_bpm:  Optional[float] = None


class PPGResponse(BaseModel):
    """
    Full response returned to Flutter after processing.
    """
    bpm:          float
    bpm_fft:      float
    snr:          float
    fps:          float
    sdnn_ms:      Optional[float]
    rmssd_ms:     Optional[float]
    mean_rr_ms:   Optional[float]
    bpm_from_rr:  Optional[float]
    num_beats:    Optional[int]
    stress_level: Optional[str]    # LOW | MEDIUM | HIGH
    confidence:   str              # HIGH | MEDIUM | LOW
    metabolic_state: Optional[str] # set when saved to DB
    saved:        bool = False
    error:        Optional[str] = None
