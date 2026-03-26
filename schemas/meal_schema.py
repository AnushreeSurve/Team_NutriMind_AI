# ============================================================
#  schemas/meal_schema.py  —  Request & Response shapes for Meals
# ============================================================

from pydantic import BaseModel
from typing import Optional


class AddMealRequest(BaseModel):
    email: str          # used as user identifier (no JWT yet)
    meal_name: str
    calories: int
    protein_g: Optional[float] = 0.0
    carbs_g: Optional[float] = 0.0
    fat_g: Optional[float] = 0.0
    slot: Optional[str] = "snack"   # breakfast | lunch | snack | dinner


class DailyCaloriesRequest(BaseModel):
    email: str


class MealLogEntry(BaseModel):
    meal_name: str
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    slot: str
