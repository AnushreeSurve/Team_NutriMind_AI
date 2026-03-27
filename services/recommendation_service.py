# services/recommendation_service.py

import sys
import os
import requests

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from ml.run_recommendation import get_daily_meal_plan
from models.database import supabase
from datetime import date as date_type
from dotenv import load_dotenv

load_dotenv()

OPENWEATHER_KEY = os.environ.get("OPENWEATHER_API_KEY", "")


def _get_weather(city: str) -> tuple:
    if not OPENWEATHER_KEY:
        return "hot", 32.0
    try:
        url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?q={city}&appid={OPENWEATHER_KEY}&units=metric"
        )
        resp = requests.get(url, timeout=5)
        data = resp.json()
        temp       = data["main"]["temp"]
        weather_id = data["weather"][0]["id"]
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


def _get_user(email: str) -> dict | None:
    res = (
        supabase.table("profiles")
        .select("user_id, location_city, diet_type, budget")
        .eq("email", email)
        .execute()
    )
    return res.data[0] if res.data else None


def recommend_meals(email: str, slot: str) -> dict:
    user = _get_user(email)
    if not user:
        return {"error": "User not found."}

    user_id = str(user["user_id"])
    city    = user.get("location_city") or "Pune"
    today   = str(date_type.today())

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
            "hint":  "Make sure morning check-in is completed before fetching recommendations."
        }

    all_slots = result.get("meals", [])
    slot_plan = next((s for s in all_slots if s["slot"] == slot), None)

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


def recommend_full_day(email: str, date_override: str | None = None) -> dict:
    user = _get_user(email)
    if not user:
        return {"error": "User not found."}

    user_id = str(user["user_id"])           # str cast — uuid safety
    city    = user.get("location_city") or "Pune"

    # Use Flutter's local IST date if provided — avoids UTC vs IST mismatch
    today = date_override or str(date_type.today())

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