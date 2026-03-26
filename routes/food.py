# ============================================================
#  routes/food.py  —  POST /food/analyze-food
# ============================================================

from fastapi import APIRouter
from schemas.other_schemas import AnalyzeFoodRequest
from services.food_service import analyze_food

router = APIRouter()


@router.post("/analyze-food")
def analyze_food_route(req: AnalyzeFoodRequest):
    """
    Returns calories, protein, carbs, fat, vitamins, and inflammation
    score for a given food item and quantity.
    """
    return analyze_food(req.food_name, req.quantity_g)
