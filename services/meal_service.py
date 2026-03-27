# ============================================================
#  services/meal_service.py  —  Meal logging with Supabase
# ============================================================

from datetime import date
from models.database import supabase


def get_user(email: str) -> dict | None:
    res = supabase.table("profiles").select("*").eq("email", email).execute()
    return res.data[0] if res.data else None


def add_meal(req) -> dict:
    user = get_user(req.email)
    if not user:
        return {"error": "User not found. Please signup first."}

    today = str(date.today())

    # Insert into meal_logs table
    log_entry = {
        "user_id":  user["user_id"],
        "meal_id":  req.meal_name.lower().replace(" ", "_"),  # temp slug as ID
        "slot":     req.slot,
        "log_date": today,
        "consumed": True,
    }
    supabase.table("meal_logs").insert(log_entry).execute()

    # Also upsert into meals table so the meal_id FK exists
    meal_row = {
        "meal_id":   req.meal_name.lower().replace(" ", "_"),
        "name":      req.meal_name,
        "calories":  req.calories,
        "protein_g": req.protein_g,
        "carbs_g":   req.carbs_g,
        "fat_g":     req.fat_g,
        "prep_type": "home",
        "is_active": True,
    }
    supabase.table("meals").upsert(meal_row).execute()

    summary = get_daily_summary(req.email)
    return {
        "message":            f"'{req.meal_name}' logged for {req.slot}.",
        "total_logged_today": summary.get("total_calories", 0),
    }


def get_daily_summary(email: str) -> dict:
    user = get_user(email)
    if not user:
        return {"error": "User not found."}

    today = str(date.today())

    # Fetch today's logs joined with meal data
    logs = (
        supabase.table("meal_logs")
        .select("slot, log_date, meals(name, calories, protein_g, carbs_g, fat_g)")
        .eq("user_id", user["user_id"])
        .eq("log_date", today)
        .eq("consumed", True)
        .execute()
    )

    meals_today = []
    total_cal = total_protein = total_carbs = total_fat = 0

    for row in logs.data:
        m = row.get("meals") or {}
        total_cal     += m.get("calories",  0) or 0
        total_protein += m.get("protein_g", 0) or 0
        total_carbs   += m.get("carbs_g",   0) or 0
        total_fat     += m.get("fat_g",     0) or 0
        meals_today.append({"slot": row["slot"], **m})

    cal_target = user.get("daily_calorie_target", 2000)

    return {
        "date":            today,
        "meals_logged":    meals_today,
        "total_calories":  total_cal,
        "total_protein_g": round(total_protein, 1),
        "total_carbs_g":   round(total_carbs, 1),
        "total_fat_g":     round(total_fat, 1),
        "calorie_target":  cal_target,
        "remaining_kcal":  cal_target - total_cal,
        "status":          "on track" if cal_target - total_cal >= 0 else "over budget",
    }
