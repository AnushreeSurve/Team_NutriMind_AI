# ============================================================
#  services/weather_service.py
# ============================================================

WEATHER_MEALS = {
    "hot": {
        "advice": "Stay hydrated. Prefer light, cooling foods.",
        "meals": [
            {"name": "Coconut Water + Curd Rice", "calories": 280, "benefit": "Cooling & electrolyte-rich"},
            {"name": "Cucumber Raita + Khichdi",  "calories": 300, "benefit": "Anti-inflammatory"},
            {"name": "Watermelon Slices",          "calories": 80,  "benefit": "Hydration boost"},
        ],
        "avoid": ["Spicy food", "Fried snacks", "Red meat"],
    },
    "cold": {
        "advice": "Eat warm, energy-dense foods to maintain body temperature.",
        "meals": [
            {"name": "Masala Oats + Milk",         "calories": 320, "benefit": "Warming & filling"},
            {"name": "Lentil Soup (Dal)",           "calories": 200, "benefit": "Protein & warmth"},
            {"name": "Ginger Tea + Multigrain Roti","calories": 180, "benefit": "Immunity boost"},
        ],
        "avoid": ["Cold drinks", "Ice cream", "Raw salads"],
    },
    "rainy": {
        "advice": "Prefer cooked, immunity-boosting meals. Avoid raw street food.",
        "meals": [
            {"name": "Moong Dal Soup",             "calories": 180, "benefit": "Light & immunity-rich"},
            {"name": "Khichdi + Ghee",             "calories": 350, "benefit": "Gut-friendly comfort"},
            {"name": "Turmeric Milk",              "calories": 120, "benefit": "Anti-inflammatory"},
        ],
        "avoid": ["Street food", "Raw vegetables", "Cold beverages"],
    },
    "normal": {
        "advice": "Standard balanced meals work well today.",
        "meals": [
            {"name": "Dal + Rice + Sabzi",         "calories": 400, "benefit": "Balanced macros"},
            {"name": "Roti + Paneer Curry",        "calories": 420, "benefit": "High protein veg"},
            {"name": "Egg Wrap + Salad",           "calories": 350, "benefit": "Quick & nutritious"},
        ],
        "avoid": [],
    },
}


def weather_meals(condition: str, diet_type: str) -> dict:
    data = WEATHER_MEALS.get(condition.lower(), WEATHER_MEALS["normal"])
    return {
        "weather_condition": condition,
        "diet_filter":       diet_type,
        "advice":            data["advice"],
        "suggested_meals":   data["meals"],
        "foods_to_avoid":    data["avoid"],
    }


# ============================================================
#  services/health_service.py
# ============================================================

HEALTH_PLANS = {
    "pcos": {
        "condition":   "PCOS",
        "calorie_adj": -200,
        "focus":       "Low GI foods, anti-inflammatory diet, high fibre",
        "foods_to_eat":  ["Oats", "Lentils", "Leafy greens", "Flaxseeds", "Berries"],
        "foods_to_avoid":["Sugar", "White bread", "Fried foods", "Dairy excess"],
        "meal_plan": [
            {"slot": "breakfast", "meal": "Oats + Flaxseed + Berries",  "calories": 280},
            {"slot": "lunch",     "meal": "Moong Dal + Brown Rice",      "calories": 370},
            {"slot": "snack",     "meal": "Handful of nuts + green tea", "calories": 150},
            {"slot": "dinner",    "meal": "Stir-fried veggies + Quinoa", "calories": 340},
        ],
    },
    "diabetes": {
        "condition":   "Type 2 Diabetes",
        "calorie_adj": -300,
        "focus":       "Low glycaemic index, controlled carbs, high protein",
        "foods_to_eat":  ["Bitter gourd", "Methi", "Lentils", "Fish", "Oats"],
        "foods_to_avoid":["White rice", "Sugar", "Fruit juice", "Maida"],
        "meal_plan": [
            {"slot": "breakfast", "meal": "Methi Paratha (small) + Curd", "calories": 260},
            {"slot": "lunch",     "meal": "Brown Rice + Rajma + Salad",   "calories": 380},
            {"slot": "snack",     "meal": "Roasted chana + Cucumber",     "calories": 130},
            {"slot": "dinner",    "meal": "Dal + 2 Roti + Sabzi",         "calories": 350},
        ],
    },
    "thyroid": {
        "condition":   "Hypothyroidism",
        "calorie_adj": -150,
        "focus":       "Iodine-rich, selenium foods; avoid goitrogens",
        "foods_to_eat":  ["Eggs", "Fish", "Brazil nuts", "Dairy", "Iodized salt"],
        "foods_to_avoid":["Raw cabbage", "Soy excess", "Millet excess"],
        "meal_plan": [
            {"slot": "breakfast", "meal": "Egg + whole grain toast + milk", "calories": 300},
            {"slot": "lunch",     "meal": "Fish curry + Rice + Salad",      "calories": 420},
            {"slot": "snack",     "meal": "Yogurt + walnuts",               "calories": 160},
            {"slot": "dinner",    "meal": "Chicken stew + sweet potato",    "calories": 380},
        ],
    },
    "bp": {
        "condition":   "High Blood Pressure",
        "calorie_adj": 0,
        "focus":       "DASH diet: low sodium, high potassium, high fibre",
        "foods_to_eat":  ["Banana", "Spinach", "Oats", "Beets", "Garlic"],
        "foods_to_avoid":["Salt excess", "Pickles", "Processed food", "Alcohol"],
        "meal_plan": [
            {"slot": "breakfast", "meal": "Oats + Banana + low-fat milk", "calories": 300},
            {"slot": "lunch",     "meal": "Spinach dal + Brown rice",     "calories": 370},
            {"slot": "snack",     "meal": "Beet juice + almonds",         "calories": 140},
            {"slot": "dinner",    "meal": "Grilled chicken + sautéed greens", "calories": 380},
        ],
    },
}


def health_plan(email: str, condition: str) -> dict:
    key  = condition.lower().strip()
    plan = HEALTH_PLANS.get(key)
    if not plan:
        return {
            "error":      f"Condition '{condition}' not in database yet.",
            "supported":  list(HEALTH_PLANS.keys()),
        }
    return {"email": email, **plan}


# ============================================================
#  services/prediction_service.py  —  Dummy ML (rule-based now)
# ============================================================

def predict(f1: float, f2: float, f3: float) -> dict:
    """
    Placeholder for an ML model.
    Replace the formula below with: model.predict([[f1, f2, f3]])
    """
    score = round((f1 * 0.4) + (f2 * 0.35) + (f3 * 0.25), 2)
    label = "high" if score > 70 else ("medium" if score > 40 else "low")
    return {
        "input":       {"feature_1": f1, "feature_2": f2, "feature_3": f3},
        "prediction":  score,
        "risk_level":  label,
        "note":        "Dummy linear model. Replace with trained ML model later.",
    }


METABOLIC_STATES = {
    # (good_sleep, active, within_calories) → state
    (True,  True,  True):  ("performance",     "Your body is primed. Push hard today."),
    (True,  True,  False): ("fat_burn",        "Slight deficit + activity = ideal fat-burn window."),
    (True,  False, True):  ("normal",          "Rested but low movement. Add a walk today."),
    (True,  False, False): ("cortisol_buffer", "Low intake detected. Eat a balanced meal soon."),
    (False, True,  True):  ("muscle_repair",   "Fatigued but active. Prioritise protein & rest."),
    (False, True,  False): ("stress_recovery", "Sleep debt + activity deficit. Recover first."),
    (False, False, True):  ("cortisol_buffer", "Poor sleep. Reduce stress, eat light & early."),
    (False, False, False): ("stress_recovery", "Full recovery mode needed. Rest and eat well."),
}


def metabolic_predict(sleep_hours: float, steps: int, calories: int, heart_rate: int, mood: str, email: str = "") -> dict:
    from datetime import date
    from models.database import supabase

    good_sleep      = sleep_hours >= 6.5
    active          = steps >= 6000
    within_calories = calories <= 2200

    state, advice = METABOLIC_STATES[(good_sleep, active, within_calories)]

    if mood == "stressed":
        state  = "stress_recovery"
        advice = "Stress detected. Eat magnesium-rich foods (nuts, seeds, greens) and rest."

    # Save to morning_checkins if we have a real user
    if email:
        profile = supabase.table("profiles").select("user_id, daily_calorie_target").eq("email", email).execute()
        if profile.data:
            user_id    = profile.data[0]["user_id"]
            cal_target = profile.data[0].get("daily_calorie_target", 2200)
            cal_adj    = calories - cal_target  # positive = over, negative = under

            checkin = {
                "user_id":         user_id,
                "checkin_date":    str(date.today()),
                "heart_rate":      heart_rate,
                "sleep_quality":   "good" if sleep_hours >= 7 else ("okay" if sleep_hours >= 5.5 else "bad"),
                "energy_level":    "energetic" if active else ("normal" if steps > 3000 else "tired"),
                "mood":            mood,
                "metabolic_state": state,
                "state_label":     advice,
                "calorie_adjustment": cal_adj,
            }
            # upsert so re-running today doesn't duplicate
            supabase.table("morning_checkins").upsert(checkin, on_conflict="user_id,checkin_date").execute()

    return {
        "inputs": {
            "sleep_hours": sleep_hours,
            "steps":       steps,
            "calories":    calories,
            "heart_rate":  heart_rate,
            "mood":        mood,
        },
        "metabolic_state": state,
        "advice":          advice,
        "meal_tag":        state,
        "saved_to_db":     bool(email),
        "note":            "Rule-based engine. Will be replaced with HRV + biometric ML model.",
    }
