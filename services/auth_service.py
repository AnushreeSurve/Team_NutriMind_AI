# ============================================================
#  services/auth_service.py  —  Signup with Supabase
# ============================================================

import uuid
from models.database import supabase
from schemas.auth_schema import SignupRequest


def calculate_bmr(req: SignupRequest) -> int:
    base = 10 * req.weight_kg + 6.25 * req.height_cm - 5 * req.age
    bmr  = int(base + 5) if req.gender == "male" else int(base - 161)
    return max(bmr, 1200)


def calculate_tdee(bmr: int, activity_level: str) -> int:
    multipliers = {"sedentary": 1.2, "moderate": 1.55, "active": 1.725}
    return int(bmr * multipliers.get(activity_level, 1.2))


def adjust_for_goal(tdee: int, goal: str) -> int:
    return tdee + {"lose": -400, "maintain": 0, "gain": 400}.get(goal, 0)


def calculate_macros(calories: int, goal: str) -> dict:
    if goal == "lose":
        p, c, f = 0.35, 0.40, 0.25
    elif goal == "gain":
        p, c, f = 0.30, 0.45, 0.25
    else:
        p, c, f = 0.30, 0.40, 0.30
    return {
        "protein_target_g": int((calories * p) / 4),
        "carbs_target_g":   int((calories * c) / 4),
        "fat_target_g":     int((calories * f) / 9),
    }


def signup_user(req: SignupRequest) -> dict:
    # 1. Check if email already exists in profiles
    existing = supabase.table("profiles").select("email").eq("email", req.email).execute()
    if existing.data:
        return {"error": "Email already registered."}

    # 2. Create auth user in Supabase Auth
    auth_response = supabase.auth.sign_up({"email": req.email, "password": req.email + "_nutrisync"})
    if not auth_response.user:
        return {"error": "Auth signup failed. Check your Supabase Auth settings."}

    user_id = str(auth_response.user.id)

    # 3. Calculate nutrition targets
    bmr      = calculate_bmr(req)
    tdee     = calculate_tdee(bmr, req.activity_level)
    cal_goal = adjust_for_goal(tdee, req.goal)
    macros   = calculate_macros(cal_goal, req.goal)

    # 4. Insert into profiles table (matches your schema exactly)
    profile = {
        "user_id":              user_id,
        "name":                 req.name,
        "email":                req.email,
        "age":                  req.age,
        "gender":               req.gender,
        "height_cm":            req.height_cm,
        "weight_kg":            req.weight_kg,
        "goal":                 req.goal,
        "diet_type":            req.diet_type,
        "activity_level":       req.activity_level,
        "budget":               req.budget,
        "bmr":                  bmr,
        "daily_calorie_target": cal_goal,
        "protein_target_g":     macros["protein_target_g"],
        "carbs_target_g":       macros["carbs_target_g"],
        "fat_target_g":         macros["fat_target_g"],
        "onboarding_complete":  True,
    }
    supabase.table("profiles").insert(profile).execute()

    return {
        "message":              "Signup successful!",
        "user_id":              user_id,
        "daily_calorie_target": cal_goal,
        **macros,
    }
