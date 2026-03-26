# run_recommendation.py
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   The single function backend calls for the /meals/today endpoint.
#   Orchestrates: DB fetch → model scoring → save plan → return response.
#
#   Backend imports only this file. They do not need to know about
#   db_connector.py or recommender.py directly.
# ─────────────────────────────────────────────────────────────────────────────

from ml.db_connector import (
    fetch_all_meals,
    fetch_user_profile,
    fetch_todays_checkin,
    fetch_meal_logs,
    save_daily_meal_plan,
)
from ml.recommender import get_top3_meals, build_feedback_lookup

# Slot schedule — when notifications fire for each meal
SLOT_TIMES = {
    "breakfast": "08:00",
    "lunch":     "13:00",
    "snack":     "16:30",
    "dinner":    "20:00",
}

# Cache meals in memory — they don't change often
# Refresh every 6 hours in production (backend can handle cache invalidation)
_meals_cache = None

def _get_meals():
    global _meals_cache
    if _meals_cache is None:
        _meals_cache = fetch_all_meals()
    return _meals_cache


def get_daily_meal_plan(
    user_id:           str,
    date_str:          str,
    weather_condition: str = "hot",
    temperature_c:     float = 30.0,
    city:              str = "",
) -> dict:
    """
    Main function called by the /meals/today FastAPI endpoint.

    Parameters
    ──────────
    user_id          — from auth token
    date_str         — "YYYY-MM-DD" (today's date)
    weather_condition— from OpenWeatherMap call in FastAPI: "hot"|"cold"|"rainy"|"humid"
    temperature_c    — from OpenWeatherMap call in FastAPI
    city             — user's city (for logging only)

    Returns
    ───────
    Dict matching the /meals/today response format in your API contract.
    """

    # ── 1. Fetch user profile ──────────────────────────────────────────────
    try:
        user = fetch_user_profile(user_id)
    except ValueError as e:
        return {"status": "error", "message": str(e)}

    # ── 2. Fetch today's check-in ──────────────────────────────────────────
    checkin = fetch_todays_checkin(user_id, date_str)
    if not checkin:
        return {
            "status": "error",
            "message": "Morning check-in not completed yet. Please complete check-in first."
        }

    # Attach weather to context (backend fetches weather, passes it here)
    checkin["weather_condition"] = weather_condition
    checkin["temperature_c"]     = temperature_c

    metabolic_state = checkin.get("metabolic_state", "normal")

    # ── 3. Fetch meals and user feedback ──────────────────────────────────
    all_meals   = _get_meals()
    meal_logs   = fetch_meal_logs(user_id, days=30)
    feedback    = build_feedback_lookup(meal_logs, all_meals)

    # ── 4. Generate recommendations for all 4 slots ────────────────────────
    slots = ["breakfast", "lunch", "snack", "dinner"]
    meal_plan = []

    for slot in slots:
        # Set slot in context for this iteration
        slot_context = {**checkin, "slot": slot}

        top3 = get_top3_meals(user, slot_context, all_meals, feedback)

        # Save to daily_meal_plans table
        save_daily_meal_plan(
            user_id          = user_id,
            plan_date        = date_str,
            metabolic_state  = metabolic_state,
            weather_condition= weather_condition,
            slot             = slot,
            scheduled_time   = SLOT_TIMES[slot],
            top3_meals       = top3,
        )

        # Format options for API response
        options = []
        for meal in top3:
            options.append({
                "meal_id":            meal["meal_id"],
                "name":               meal["name"],
                "calories":           meal["calories"],
                "protein_g":          meal["protein_g"],
                "carbs_g":            meal["carbs_g"],
                "fat_g":              meal["fat_g"],
                "inflammation_score": meal["inflammation_score"],
                "recovery_impact":    meal["recovery_impact"],
                "prep_type":          meal["prep_type"],
                "image_url":          meal.get("image_url", ""),
                "why_recommended":    meal.get("why_recommended", ""),
                "predicted_score":    meal.get("predicted_score", 0.0),
            })

        meal_plan.append({
            "slot":           slot,
            "scheduled_time": SLOT_TIMES[slot],
            "options":        options,
        })

    # ── 5. Return full response matching API contract ──────────────────────
    return {
        "status":            "success",
        "metabolic_state":   metabolic_state,
        "weather_condition": weather_condition,
        "meals":             meal_plan,
    }


# ─────────────────────────────────────────────────────────────────────────────
# QUICK INTEGRATION TEST — run directly to verify DB + model + recommender
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import json

    # Replace with a real user_id from your Supabase profiles table
    TEST_USER_ID = "PASTE_A_REAL_USER_ID_HERE"
    TEST_DATE    = "2024-03-25"

    print("── Integration test ─────────────────────────────────────")
    print(f"User:    {TEST_USER_ID}")
    print(f"Date:    {TEST_DATE}")
    print()

    result = get_daily_meal_plan(
        user_id           = TEST_USER_ID,
        date_str          = TEST_DATE,
        weather_condition = "hot",
        temperature_c     = 33.0,
        city              = "Pune",
    )

    if result["status"] == "error":
        print(f"ERROR: {result['message']}")
    else:
        print(f"Metabolic state: {result['metabolic_state']}")
        print(f"Weather:         {result['weather_condition']}")
        print()
        for slot_plan in result["meals"]:
            print(f"── {slot_plan['slot'].upper()} ({slot_plan['scheduled_time']}) ──")
            for i, meal in enumerate(slot_plan["options"], 1):
                print(f"  #{i} {meal['name']}  "
                      f"({meal['calories']} kcal, {meal['protein_g']}g protein, "
                      f"inflam {meal['inflammation_score']}/10)  "
                      f"score={meal['predicted_score']}")
                print(f"     {meal['why_recommended']}")
            print()
