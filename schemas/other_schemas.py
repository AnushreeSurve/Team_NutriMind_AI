# ============================================================
#  schemas/food_schema.py
# ============================================================
from pydantic import BaseModel

class AnalyzeFoodRequest(BaseModel):
    food_name: str
    quantity_g: float = 100.0   # grams


# ============================================================
#  schemas/preference_schema.py
# ============================================================
class SetPreferencesRequest(BaseModel):
    email: str
    diet_type: str      # veg | non-veg | vegan | jain
    budget: str         # low | mid | high
    allergies: list[str] = []
    conditions: list[str] = []   # PCOS | diabetes | thyroid | BP


class GetPreferencesRequest(BaseModel):
    email: str


# ============================================================
#  schemas/recommendation_schema.py
# ============================================================
class MealRecommendationRequest(BaseModel):
    email: str
    slot: str = "lunch"   # breakfast | lunch | snack | dinner


# ============================================================
#  schemas/weather_schema.py
# ============================================================
class WeatherMealsRequest(BaseModel):
    condition: str   # hot | cold | rainy | normal
    diet_type: str = "veg"


# ============================================================
#  schemas/health_schema.py
# ============================================================
class HealthPlanRequest(BaseModel):
    email: str
    condition: str   # PCOS | diabetes | thyroid | BP


# ============================================================
#  schemas/prediction_schema.py
# ============================================================
class PredictRequest(BaseModel):
    feature_1: float
    feature_2: float
    feature_3: float


class MetabolicPredictRequest(BaseModel):
    email: str
    sleep_hours: float
    steps: int
    calories_consumed: int
    heart_rate: int = 72
    mood: str = "neutral"   # stressed | neutral | calm
