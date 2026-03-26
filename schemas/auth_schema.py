# ============================================================
#  schemas/auth_schema.py  —  Request & Response shapes for Auth
# ============================================================

from pydantic import BaseModel, EmailStr


class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    age: int
    gender: str          # "male" | "female" | "other"
    height_cm: float
    weight_kg: float
    goal: str            # "lose" | "maintain" | "gain"
    diet_type: str       # "veg" | "non-veg" | "vegan" | "jain"
    activity_level: str  # "sedentary" | "moderate" | "active"
    budget: str          # "low" | "mid" | "high"


class SignupResponse(BaseModel):
    message: str
    user_id: str
    daily_calorie_target: int
    protein_target_g: int
    carbs_target_g: int
    fat_target_g: int
