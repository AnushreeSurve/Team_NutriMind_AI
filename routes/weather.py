# ============================================================
#  routes/weather.py  —  POST /weather/weather-meals
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import WeatherMealsRequest
from services.other_services import weather_meals

router = APIRouter()

VALID_CONDITIONS = ["hot", "cold", "rainy", "normal"]


@router.post("/weather-meals")
def weather_meal_suggestions(req: WeatherMealsRequest):
    """
    Returns meal suggestions and food warnings based on
    current weather condition (hot / cold / rainy / normal).
    """
    if req.condition.lower() not in VALID_CONDITIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid condition. Choose from: {VALID_CONDITIONS}"
        )
    return weather_meals(req.condition, req.diet_type)
