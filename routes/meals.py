# routes/meals.py

from fastapi import APIRouter, HTTPException
from schemas.meal_schema import AddMealRequest, DailyCaloriesRequest, MealLogRequest
from services.meal_service import add_meal, get_daily_summary
from database import supabase
from datetime import date

router = APIRouter()


@router.post("/add-meal")
def add_meal_route(req: AddMealRequest):
    result = add_meal(req)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


@router.post("/daily-calories")
def daily_calories(req: DailyCaloriesRequest):
    result = get_daily_summary(req.email)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


@router.post("/log")
def log_meal(req: MealLogRequest):
    """Log a meal with optional rating — saved for feedback loop."""
    try:
        today = str(date.today())

        # Get today's metabolic state for feedback context
        metabolic_state = _get_todays_metabolic_state(req.user_id, req.date or today)

        record = {
            "user_id":                  req.user_id,
            "meal_id":                  req.meal_id,
            "slot":                     req.slot,
            "log_date":                 req.date or today,
            "consumed":                 req.consumed,
            "metabolic_state_that_day": metabolic_state,
        }

        if req.rating is not None:
            record["rating"] = req.rating

        supabase.table("meal_logs")\
            .upsert(record, on_conflict="user_id,meal_id,log_date,slot")\
            .execute()

        return {"status": "success", "logged": True}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _get_todays_metabolic_state(user_id: str, date_str: str) -> str:
    try:
        res = supabase.table("morning_checkins")\
            .select("metabolic_state")\
            .eq("user_id", user_id)\
            .eq("checkin_date", date_str)\
            .execute()
        return res.data[0]["metabolic_state"] if res.data else "normal"
    except Exception:
        return "normal"