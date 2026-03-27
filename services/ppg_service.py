# ============================================================
#  services/ppg_service.py
#  Orchestrates: PPG engine → metabolic state → Supabase save
# ============================================================

from datetime import date
from models.database import supabase
from ppg.engine import run_ppg_pipeline, PPGResult
from services.other_services import metabolic_predict


def analyze_only(timestamps, r_channel, g_channel, prior_bpm=None) -> PPGResult:
    """Run the DSP pipeline. Does NOT save to database."""
    return run_ppg_pipeline(timestamps, r_channel, g_channel, prior_bpm)


def analyze_and_save(email: str, timestamps, r_channel, g_channel, prior_bpm=None) -> dict:
    """
    Full pipeline:
      1. Run PPG engine → BPM, HRV, stress
      2. Derive metabolic state using PPG outputs
      3. Save to morning_checkins table
      4. Generate alert if stress is HIGH

    Returns a dict ready to send back to Flutter.
    """
    # ── 1. PPG computation ───────────────────────────────────────
    result = run_ppg_pipeline(timestamps, r_channel, g_channel, prior_bpm)

    if result.error:
        return {"error": result.error, "saved": False}

    # ── 2. Fetch user profile ────────────────────────────────────
    profile_res = (
        supabase.table("profiles")
        .select("user_id, daily_calorie_target, diet_type, budget")
        .eq("email", email)
        .execute()
    )
    if not profile_res.data:
        return {"error": "User not found.", "saved": False}

    user       = profile_res.data[0]
    user_id    = user["user_id"]
    today      = str(date.today())

    # ── 3. Derive metabolic state using real heart rate ──────────
    #  metabolic_predict expects: sleep_hours, steps, calories, heart_rate, mood
    #  We don't have sleep/steps here — pull today's checkin if it exists,
    #  otherwise use defaults so at minimum the heart_rate is real.
    existing_checkin = (
        supabase.table("morning_checkins")
        .select("sleep_quality, energy_level, mood")
        .eq("user_id", user_id)
        .eq("checkin_date", today)
        .execute()
    )

    if existing_checkin.data:
        c   = existing_checkin.data[0]
        sleep_hrs = {"bad": 5.0, "okay": 6.5, "good": 8.0}.get(c["sleep_quality"], 6.5)
        steps     = {"tired": 2000, "normal": 5000, "energetic": 9000}.get(c["energy_level"], 5000)
        mood      = c.get("mood", "neutral")
    else:
        sleep_hrs, steps, mood = 6.5, 5000, "neutral"

    metabolic = metabolic_predict(
        sleep_hours      = sleep_hrs,
        steps            = steps,
        calories         = user.get("daily_calorie_target", 2000),
        heart_rate       = int(result.bpm),
        mood             = mood,
    )
    metabolic_state = metabolic["metabolic_state"]

    # ── 4. Sleep quality from HRV ────────────────────────────────
    #  SDNN > 50ms → HRV healthy → proxy good sleep
    if result.sdnn_ms is not None:
        sleep_quality = "good" if result.sdnn_ms > 50 else ("okay" if result.sdnn_ms > 30 else "bad")
    else:
        sleep_quality = "okay"

    # ── 5. Upsert into morning_checkins ─────────────────────────
    checkin = {
        "user_id":            user_id,
        "checkin_date":       today,
        "heart_rate":         int(result.bpm),
        "sleep_quality":      sleep_quality,
        "metabolic_state":    metabolic_state,
        "state_label":        metabolic.get("advice", ""),
        "calorie_adjustment": 0,
    }
    supabase.table("morning_checkins").upsert(
        checkin, on_conflict="user_id,checkin_date"
    ).execute()

    # ── 6. Raise alert if stress is HIGH ─────────────────────────
    if result.stress_level == "HIGH":
        alert = {
            "user_id":    user_id,
            "alert_date": today,
            "type":       "stress",
            "severity":   "high",
            "message":    f"High stress detected — HRV SDNN {result.sdnn_ms:.0f} ms, RMSSD {result.rmssd_ms:.0f} ms.",
            "suggestion": "Consider light meals high in magnesium (nuts, seeds, leafy greens) and avoid caffeine.",
            "is_active":  True,
        }
        supabase.table("alerts").insert(alert).execute()

    return {
        # Raw PPG metrics
        "bpm":           result.bpm,
        "bpm_fft":       result.bpm_fft,
        "snr":           result.snr,
        "fps":           result.fps,
        "sdnn_ms":       result.sdnn_ms,
        "rmssd_ms":      result.rmssd_ms,
        "mean_rr_ms":    result.mean_rr_ms,
        "bpm_from_rr":   result.bpm_from_rr,
        "num_beats":     result.num_beats,
        "stress_level":  result.stress_level,
        "confidence":    result.confidence,
        # Derived outputs
        "metabolic_state": metabolic_state,
        "advice":          metabolic.get("advice", ""),
        "sleep_quality":   sleep_quality,
        "alert_raised":    result.stress_level == "HIGH",
        "saved":           True,
    }
