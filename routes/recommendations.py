# ============================================================
#  routes/recommendations.py  —  POST /recommend/meal-recommendation
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import MealRecommendationRequest
from services.recommendation_service import recommend_meals, recommend_full_day

router = APIRouter()


@router.post("/meal-recommendation")
def meal_recommendation(req: MealRecommendationRequest):
    """
    Returns up to 3 meal options filtered by the user's
    diet type, budget, and requested meal slot.
    """
    if not req.email:
        raise HTTPException(status_code=400, detail="Email is required.")
    return recommend_meals(req.email, req.slot)

@router.get("/full-day")
def full_day_recommendation(email: str):
    """
    Returns all 4 slots at once for the home screen.
    GET /recommend/full-day?email=user@email.com
    """
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    return recommend_full_day(email)
