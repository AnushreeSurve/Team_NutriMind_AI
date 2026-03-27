# routes/recommendations.py

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import MealRecommendationRequest
from services.recommendation_service import recommend_meals, recommend_full_day

router = APIRouter()


@router.post("/meal-recommendation")
def meal_recommendation(req: MealRecommendationRequest):
    if not req.email:
        raise HTTPException(status_code=400, detail="Email is required.")
    return recommend_meals(req.email, req.slot)


@router.get("/full-day")
def full_day_recommendation(email: str, date: str | None = None):
    """
    GET /recommend/full-day?email=user@email.com&date=2026-03-28
    date param is optional — Flutter sends IST local date to avoid UTC mismatch
    """
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    return recommend_full_day(email, date)