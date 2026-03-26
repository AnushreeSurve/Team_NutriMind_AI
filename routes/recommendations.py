# ============================================================
#  routes/recommendations.py  —  POST /recommend/meal-recommendation
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import MealRecommendationRequest
from services.recommendation_service import recommend_meals

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
