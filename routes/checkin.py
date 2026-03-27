# routes/checkin.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.database import supabase

router = APIRouter()


class CheckinRequest(BaseModel):
    user_id: str
    date: str
    heart_rate: int
    sleep_quality: str
    energy_level: str
    mood: str
    screen_time_mins: int | None = None
    unlock_count: int | None = None
    volume_level: int | None = None


def derive_metabolic_state(sleep: str, energy: str, mood: str, hr: int) -> dict:
    # State names MUST match CheckinResult.emoji/colorHex switch cases in user_model.dart
    if sleep == 'good' and energy == 'energetic':
        state = 'performance'
        label = 'You\'re in peak state! High-performance meals await.'
        calorie_adj = 150
    elif mood == 'stressed' and (sleep == 'bad' or hr > 90):
        state = 'cortisol_buffer'
        label = 'Stress detected. Anti-inflammatory, calming foods recommended.'
        calorie_adj = -100
    elif sleep == 'bad' and energy == 'tired':
        state = 'stress_recovery'
        label = 'Your body needs recovery. Light, nourishing meals suggested.'
        calorie_adj = -150
    elif energy == 'tired' or sleep == 'bad':
        state = 'fat_burn'
        label = 'Low energy mode. Metabolic-boosting meals recommended.'
        calorie_adj = -100
    elif energy == 'energetic' and mood == 'calm':
        state = 'muscle_repair'
        label = 'Great energy! Protein-rich meals for muscle support.'
        calorie_adj = 100
    else:
        state = 'stress_recovery'
        label = 'Balanced day. A well-rounded meal plan is ready.'
        calorie_adj = 0

    return {
        'metabolic_state': state,
        'state_label': label,
        'calorie_adjustment': calorie_adj,
    }


@router.post("/morning")
def morning_checkin(req: CheckinRequest):
    try:
        meta = derive_metabolic_state(
            req.sleep_quality, req.energy_level, req.mood, req.heart_rate
        )
        data = {
            'user_id':            req.user_id,
            'checkin_date':       req.date,
            'heart_rate':         req.heart_rate,
            'sleep_quality':      req.sleep_quality,
            'energy_level':       req.energy_level,
            'mood':               req.mood,
            'metabolic_state':    meta['metabolic_state'],
            'state_label':        meta['state_label'],
            'calorie_adjustment': meta['calorie_adjustment'],
        }
        if req.screen_time_mins is not None:
            data['screen_time_mins'] = req.screen_time_mins
        if req.unlock_count is not None:
            data['unlock_count'] = req.unlock_count
        if req.volume_level is not None:
            data['volume_level'] = req.volume_level

        supabase.table("morning_checkins").upsert(
            data, on_conflict="user_id,checkin_date"
        ).execute()

        return {
            "status":             "success",
            "metabolic_state":    meta['metabolic_state'],
            "state_label":        meta['state_label'],
            "calorie_adjustment": meta['calorie_adjustment'],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/today")
def get_checkin_status(user_id: str, date: str):
    try:
        result = supabase.table("morning_checkins")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("checkin_date", date)\
            .execute()
        if result.data:
            return {"checked_in": True, "data": result.data[0]}
        return {"checked_in": False}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))