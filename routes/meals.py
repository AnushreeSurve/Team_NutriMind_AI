# ============================================================
#  routes/meals.py  —  POST /meals/add-meal  |  POST /meals/daily-calories
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.meal_schema import AddMealRequest, DailyCaloriesRequest
from services.meal_service import add_meal, get_daily_summary

router = APIRouter()


@router.post("/add-meal")
def add_meal_route(req: AddMealRequest):
    """Log a meal for a user."""
    result = add_meal(req)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


@router.post("/daily-calories")
def daily_calories(req: DailyCaloriesRequest):
    """Get today's calorie and macro summary for a user."""
    result = get_daily_summary(req.email)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result
