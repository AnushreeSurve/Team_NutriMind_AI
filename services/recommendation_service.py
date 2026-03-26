# ============================================================
#  services/recommendation_service.py
#  ML-powered recommendations via NutriSync XGBoost engine
# ============================================================

import sys
import os
import requests

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from ml.run_recommendation import get_daily_meal_plan
from models.database import supabase
from datetime import date
from dotenv import load_dotenv

load_dotenv()

OPENWEATHER_KEY = os.environ.get("OPENWEATHER_API_KEY", "")


# ─────────────────────────────────────────────────────────────
# WEATHER HELPER
# ─────────────────────────────────────────────────────────────

def _get_weather(city: str) -> tuple:
    """
    Fetch current weather from OpenWeatherMap.
    Returns (weather_condition, temperature_c).
    Falls back to ("hot", 32.0) if API key missing or call fails.
    weather_condition matches your ML encodings: hot | cold | rainy | humid
    """
    if not OPENWEATHER_KEY:
        return "hot", 32.0

    try:
        url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?q={city}&appid={OPENWEATHER_KEY}&units=metric"
        )
        resp = requests.get(url, timeout=5)
        data = resp.json()

        temp      = data["main"]["temp"]
        weather_id = data["weather"][0]["id"]

        # Map OpenWeatherMap weather IDs to your ML categories
        # IDs: 200-531 = rain/storm, 800 = clear, 801-804 = clouds
        if weather_id in range(200, 532):
            condition = "rainy"
        elif temp >= 32:
            condition = "hot"
        elif temp <= 18:
            condition = "cold"
        else:
            condition = "humid"

        return condition, round(temp, 1)

    except Exception:
        return "hot", 32.0


# ─────────────────────────────────────────────────────────────
# MAIN RECOMMENDATION FUNCTIONS
# ─────────────────────────────────────────────────────────────

def recommend_meals(email: str, slot: str) -> dict:
    """
    Called by POST /recommend/meal-recommendation
    Keeps the exact same signature the route already uses.
    Returns top 3 meals for a specific slot.
    """

    # Get user_id and city from profiles table
    profile_res = (
        supabase.table("profiles")
        .select("user_id, location_city, diet_type, budget")
        .eq("email", email)
        .execute()
    )
    if not profile_res.data:
        return {"error": "User not found."}

    user    = profile_res.data[0]
    user_id = user["user_id"]
    city    = user.get("location_city") or "Pune"
    today   = str(date.today())

    # Get weather
    weather_condition, temperature_c = _get_weather(city)

    # Call ML engine
    result = get_daily_meal_plan(
        user_id           = user_id,
        date_str          = today,
        weather_condition = weather_condition,
        temperature_c     = temperature_c,
        city              = city,
    )

    # Handle error from ML (usually means check-in not done yet)
    if result.get("status") == "error":
        return {
            "error":   result.get("message"),
            "hint":    "Make sure morning check-in is completed before fetching recommendations."
        }

    # Extract just the requested slot
    all_slots = result.get("meals", [])
    slot_plan = next(
        (s for s in all_slots if s["slot"] == slot),
        None
    )

    if not slot_plan:
        return {"error": f"No recommendations found for slot: {slot}"}

    return {
        "slot":              slot,
        "metabolic_state":   result.get("metabolic_state"),
        "weather_condition": weather_condition,
        "temperature_c":     temperature_c,
        "options":           slot_plan["options"],
        "scheduled_time":    slot_plan["scheduled_time"],
    }


def recommend_full_day(email: str) -> dict:
    """
    Returns all 4 slots at once.
    Call this for the main home screen instead of 4 separate calls.
    Add a route for this if frontend needs the full day at once:
      GET /recommend/full-day?email=...
    """

    profile_res = (
        supabase.table("profiles")
        .select("user_id, location_city")
        .eq("email", email)
        .execute()
    )
    if not profile_res.data:
        return {"error": "User not found."}

    user    = profile_res.data[0]
    user_id = user["user_id"]
    city    = user.get("location_city") or "Pune"
    today   = str(date.today())

    weather_condition, temperature_c = _get_weather(city)

    result = get_daily_meal_plan(
        user_id           = user_id,
        date_str          = today,
        weather_condition = weather_condition,
        temperature_c     = temperature_c,
        city              = city,
    )

    if result.get("status") == "error":
        return {
            "error": result.get("message"),
            "hint":  "Make sure morning check-in is completed first."
        }

    return {
        **result,
        "weather_condition": weather_condition,
        "temperature_c":     temperature_c,
        "city":              city,
    }