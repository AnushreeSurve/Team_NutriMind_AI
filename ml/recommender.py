# recommender.py
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Load the trained XGBoost model and use it to score and rank meals
#   for a real user in a real context. Returns top 3 recommendations.
#   This is the file FastAPI calls inside the /meals/today endpoint.
#
# ML CONCEPTS COVERED:
#   - Inference vs training: using a trained model on new data
#   - Feature consistency: encoding must exactly match training time
#   - Serving pipeline: the steps from raw API input to scored output
#   - Feedback enrichment: pulling user history to fill feedback features
#   - Graceful degradation: fallback when model fails
# ─────────────────────────────────────────────────────────────────────────────

import pandas as pd
import numpy as np
import joblib
import json
from typing import Optional

# ─────────────────────────────────────────────────────────────────────────────
# LOAD MODEL AND ENCODINGS ONCE AT STARTUP
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: inference.
# Training happens once (or periodically). Inference happens on every
# single API request. Loading the model file on every request would be
# extremely slow. Instead, we load it once when the module is imported
# and keep it in memory. FastAPI imports this module once on startup.
# ─────────────────────────────────────────────────────────────────────────────

MODEL_PATH     = "meal_scorer.pkl"
ENCODINGS_PATH = "encodings.json"

try:
    MODEL     = joblib.load(MODEL_PATH)
    with open(ENCODINGS_PATH, "r") as f:
        ENCODINGS = json.load(f)
    FEATURE_COLUMNS = ENCODINGS["feature_columns"]
    print(f"[recommender] Model loaded: {MODEL_PATH}")
except FileNotFoundError as e:
    print(f"[recommender] ERROR: {e}")
    print("[recommender] Run train_model.py first to generate model files.")
    MODEL     = None
    ENCODINGS = {}
    FEATURE_COLUMNS = []


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: SAFE ENCODE
# ─────────────────────────────────────────────────────────────────────────────

def encode(field: str, value: str) -> int:
    """
    Encode a string value to its integer code using the saved mappings.
    Falls back to 0 if value is unknown — better than crashing.
    ML concept: this is serving-time feature encoding. Must be identical
    to training-time encoding in synthetic_data_gen.py. That's why we
    saved encodings.json — single source of truth for both.
    """
    mapping = ENCODINGS.get(field, {})
    return mapping.get(str(value), 0)


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: BUILD FEATURE ROW FOR ONE USER + CONTEXT + MEAL
# ─────────────────────────────────────────────────────────────────────────────

def build_feature_row(
    user:           dict,
    context:        dict,
    meal:           dict,
    feedback_stats: dict,
) -> pd.DataFrame:
    """
    Assemble a single feature row for the model.

    Parameters
    ──────────
    user  — from profiles table:
        age, gender, height_cm, weight_kg, goal, diet_type,
        activity_level, budget, has_pcos, has_diabetes, has_thyroid, has_bp,
        daily_calorie_target, protein_target_g

    context — from morning_checkins table (today's row):
        heart_rate, sleep_quality, energy_level, mood, metabolic_state,
        weather_condition, temperature_c, calorie_adjustment, slot

    meal — from meals table:
        calories, protein_g, carbs_g, fat_g, inflammation_score,
        recovery_impact, prep_type, diet_type, budget, tags (list)

    feedback_stats — computed from meal_logs for this user:
        avg_rating_this_meal, consumed_before, avg_rating_similar_meals
        (pass zeros for new users — cold start)
    """

    # Derived user features
    bmi            = user["weight_kg"] / ((user["height_cm"] / 100) ** 2)
    calorie_today  = user["daily_calorie_target"] + context.get("calorie_adjustment", 0)

    # Slot calorie target (fraction of today's total)
    slot_fractions = {"breakfast": 0.25, "lunch": 0.35, "snack": 0.10, "dinner": 0.30}
    slot_cal_target = calorie_today * slot_fractions.get(context["slot"], 0.25)

    # Derived meal features
    calorie_gap   = abs(meal["calories"] - slot_cal_target)
    protein_ratio = meal["protein_g"] / user["weight_kg"]

    # Metabolic tag match — does this meal's tags include today's metabolic state?
    # ML concept: interaction feature. Instead of making the model figure out
    # that (metabolic_state == meal_tag) matters, we compute it directly.
    meal_tags         = meal.get("tags", [])
    metabolic_state   = context["metabolic_state"]
    tag_match         = int(metabolic_state in meal_tags)

    row = {
        # User features
        "age":              user["age"],
        "bmi":              round(bmi, 1),
        "gender":           encode("gender",         user["gender"]),
        "goal":             encode("goal",            user["goal"]),
        "diet_type":        encode("diet_type",       user["diet_type"]),
        "activity_level":   encode("activity_level",  user["activity_level"]),
        "budget":           encode("budget",          user["budget"]),
        "has_pcos":         int(user.get("has_pcos",     0)),
        "has_diabetes":     int(user.get("has_diabetes", 0)),
        "has_thyroid":      int(user.get("has_thyroid",  0)),
        "has_bp":           int(user.get("has_bp",       0)),

        # Context features
        "heart_rate":           context["heart_rate"],
        "sleep_quality":        encode("sleep_quality",    context["sleep_quality"]),
        "energy_level":         encode("energy_level",     context["energy_level"]),
        "mood":                 encode("mood",              context["mood"]),
        "metabolic_state":      encode("metabolic_state",  metabolic_state),
        "weather_condition":    encode("weather_condition", context.get("weather_condition", "hot")),
        "temperature_c":        context.get("temperature_c", 28),
        "slot":                 encode("slot",              context["slot"]),
        "calorie_today":        round(calorie_today),
        "slot_calorie_target":  round(slot_cal_target),

        # Meal features
        "meal_calories":            meal["calories"],
        "meal_protein_g":           meal["protein_g"],
        "meal_carbs_g":             meal["carbs_g"],
        "meal_fat_g":               meal["fat_g"],
        "meal_inflammation_score":  meal["inflammation_score"],
        "meal_recovery_impact":     encode("recovery_impact", meal["recovery_impact"]),
        "meal_budget":              encode("meal_budget",     meal["budget"]),
        "meal_prep_type":           encode("prep_type",       meal["prep_type"]),
        "meal_diet_type":           encode("meal_diet_type",  meal["diet_type"]),

        # Derived / interaction features
        "calorie_gap":          round(calorie_gap, 1),
        "protein_ratio":        round(protein_ratio, 3),
        "metabolic_tag_match":  tag_match,

        # Feedback history (from meal_logs, zeros for new users)
        "user_avg_rating_this_meal":     feedback_stats.get("avg_rating_this_meal",     0.0),
        "user_consumed_before":          int(feedback_stats.get("consumed_before",       0)),
        "user_avg_rating_similar_meals": feedback_stats.get("avg_rating_similar_meals", 0.0),
    }

    return pd.DataFrame([row])[FEATURE_COLUMNS]


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: HARD CONSTRAINT CHECK
# ─────────────────────────────────────────────────────────────────────────────

def passes_hard_constraints(user: dict, meal: dict, context: dict) -> bool:
    """
    Filter meals that are completely ineligible before scoring.
    ML concept: pre-filtering. The model was trained to output 0.0 for
    these cases but hard-filtering is faster and more reliable than
    relying on the model to consistently score them low. Defense in depth.
    """

    # Diet compatibility
    diet_compat = {
        "veg":     ["veg"],
        "vegan":   ["vegan"],
        "jain":    ["jain", "veg"],
        "non-veg": ["veg", "non-veg", "vegan", "jain"],
    }
    allowed = diet_compat.get(user["diet_type"], [])
    if meal["diet_type"] not in allowed:
        return False

    # Slot compatibility
    suitable_slots = meal.get("suitable_slots", [])
    if suitable_slots and context["slot"] not in suitable_slots:
        return False

    # Budget compatibility
    budget_order = {"low": 0, "mid": 1, "high": 2}
    if budget_order.get(meal["budget"], 0) > budget_order.get(user["budget"], 0):
        return False

    # Basic allergy check (extend this when your allergen DB is richer)
    user_allergies = user.get("allergies", [])
    meal_name_lower = meal["name"].lower()
    if "peanuts" in user_allergies and "peanut" in meal_name_lower:
        return False
    if "gluten" in user_allergies and any(
        w in meal_name_lower for w in ["roti", "bread", "toast", "thepla", "upma", "wheat"]
    ):
        return False

    return True


# ─────────────────────────────────────────────────────────────────────────────
# MAIN: GET TOP 3 RECOMMENDATIONS
# ─────────────────────────────────────────────────────────────────────────────

def get_top3_meals(
    user:           dict,
    context:        dict,
    all_meals:      list,
    feedback_lookup: dict,
) -> list:
    """
    Score all eligible meals and return the top 3.

    Parameters
    ──────────
    user            — user profile dict (from profiles + user_conditions tables)
    context         — today's check-in dict (from morning_checkins table)
    all_meals       — full list of meal dicts (from meals + meal_tags tables)
    feedback_lookup — dict keyed by meal_id with feedback stats for this user
                      { "m_001": {"avg_rating_this_meal": 0.8, "consumed_before": 1,
                                  "avg_rating_similar_meals": 0.75} }
                      Pass {} for new users.

    Returns
    ───────
    List of top 3 meal dicts, each with an added "predicted_score" field,
    sorted descending by score.
    """

    if MODEL is None:
        print("[recommender] Model not loaded — returning fallback empty list")
        return []

    scored_meals = []

    for meal in all_meals:
        # Step 1: hard constraint filter
        if not passes_hard_constraints(user, meal, context):
            continue

        # Step 2: get feedback stats for this meal
        # ML concept: feedback enrichment.
        # For users with history, we fill feedback features from their actual
        # meal_logs. This is what makes the model personalised over time —
        # a meal this user consistently rates 5 will score much higher than
        # the same meal for a user with no history.
        feedback_stats = feedback_lookup.get(meal["meal_id"], {
            "avg_rating_this_meal":     0.0,
            "consumed_before":          0,
            "avg_rating_similar_meals": 0.0,
        })

        # Step 3: build feature row
        try:
            feature_row = build_feature_row(user, context, meal, feedback_stats)
        except Exception as e:
            print(f"[recommender] Feature build failed for meal {meal['meal_id']}: {e}")
            continue

        # Step 4: predict score
        # ML concept: inference. model.predict() runs the input through all
        # 300 decision trees and averages their outputs. This is fast —
        # typically < 1ms per meal. Scoring 50 meals takes < 50ms.
        try:
            raw_score = float(MODEL.predict(feature_row)[0])
            score     = float(np.clip(raw_score, 0.0, 1.0))
        except Exception as e:
            print(f"[recommender] Prediction failed for meal {meal['meal_id']}: {e}")
            continue

        scored_meals.append({
            **meal,
            "predicted_score": round(score, 4),
        })

    if not scored_meals:
        print("[recommender] No meals passed constraints — returning empty list")
        return []

    # Step 5: sort by score descending and return top 3
    scored_meals.sort(key=lambda m: m["predicted_score"], reverse=True)
    top3 = scored_meals[:3]

    # Step 6: attach why_recommended template string
    # This is shown to the user as a plain-English explanation.
    # Not LLM — just a template selected from the meal's context match.
    for meal in top3:
        meal["why_recommended"] = _generate_reason(meal, context, user)

    return top3


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: GENERATE WHY_RECOMMENDED STRING
# ─────────────────────────────────────────────────────────────────────────────

def _generate_reason(meal: dict, context: dict, user: dict) -> str:
    """
    Generate a plain-English explanation for why this meal was recommended.
    Template-based — fast, reliable, no LLM needed.
    """
    state   = context["metabolic_state"]
    tags    = meal.get("tags", [])
    inflam  = meal.get("inflammation_score", 5)
    recover = meal.get("recovery_impact", "medium")
    protein = meal.get("protein_g", 0)

    # State-specific reasons
    if state == "stress_recovery" and state in tags:
        return "Anti-inflammatory and gentle — ideal for your rest and recovery day"
    if state == "cortisol_buffer" and state in tags:
        return "Low inflammation helps buffer the elevated cortisol detected this morning"
    if state == "muscle_repair" and protein > 25:
        return f"High protein ({protein}g) supports muscle repair after your active day"
    if state == "performance" and state in tags:
        return "Balanced macros to fuel your peak performance window today"
    if state == "fat_burn" and meal.get("calories", 500) < 400:
        return "Lower calorie density supports your fat-burning window today"

    # Fallback reasons based on meal properties
    if inflam <= 2:
        return "Very low inflammation score — great for overall health and energy"
    if recover == "high":
        return "High recovery impact — supports your body's natural repair process"
    if user.get("goal") == "lose" and meal.get("calories", 500) < 400:
        return "Well within your calorie target for this meal slot"
    if user.get("goal") == "gain" and protein > 20:
        return f"Solid protein content ({protein}g) supports your muscle gain goal"

    return "Matches your dietary preferences and today's nutritional targets"


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: BUILD FEEDBACK LOOKUP FROM MEAL LOGS
# ─────────────────────────────────────────────────────────────────────────────

def build_feedback_lookup(meal_logs: list, all_meals: list) -> dict:
    """
    Takes a list of meal_log dicts for a user and builds the feedback_lookup
    dict that get_top3_meals() expects.

    Call this once per /meals/today request after querying meal_logs from DB.

    meal_logs: list of dicts with keys: meal_id, consumed, rating
    all_meals: full meal list (used to find similar meal tags)

    Returns: { meal_id: { avg_rating_this_meal, consumed_before,
                          avg_rating_similar_meals } }
    """

    # Build per-meal stats
    per_meal = {}
    for log in meal_logs:
        mid = log["meal_id"]
        if mid not in per_meal:
            per_meal[mid] = {"ratings": [], "consumed_count": 0}
        if log["consumed"]:
            per_meal[mid]["consumed_count"] += 1
            if log.get("rating"):
                # Normalise rating to 0–1 scale (same as training)
                per_meal[mid]["ratings"].append(log["rating"] / 5.0)

    # Build tag index for similar-meal lookup
    tag_index = {}
    for meal in all_meals:
        for tag in meal.get("tags", []):
            tag_index.setdefault(tag, []).append(meal["meal_id"])

    # Compute per-meal stats
    lookup = {}
    for meal in all_meals:
        mid   = meal["meal_id"]
        stats = per_meal.get(mid, {})

        avg_rating      = float(np.mean(stats["ratings"])) if stats.get("ratings") else 0.0
        consumed_before = int(stats.get("consumed_count", 0) > 0)

        # Similar meal avg: meals sharing at least one tag with this meal
        similar_ratings = []
        for tag in meal.get("tags", []):
            for similar_id in tag_index.get(tag, []):
                if similar_id != mid and similar_id in per_meal:
                    similar_ratings.extend(per_meal[similar_id]["ratings"])

        avg_similar = float(np.mean(similar_ratings)) if similar_ratings else 0.0

        lookup[mid] = {
            "avg_rating_this_meal":     round(avg_rating, 3),
            "consumed_before":          consumed_before,
            "avg_rating_similar_meals": round(avg_similar, 3),
        }

    return lookup


# ─────────────────────────────────────────────────────────────────────────────
# QUICK TEST — run this file directly to verify everything works
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    from meals_reference import MEALS

    # Simulate a real API call
    test_user = {
        "age": 24, "gender": "female", "height_cm": 160, "weight_kg": 62,
        "goal": "lose", "diet_type": "veg", "activity_level": "moderate",
        "budget": "low", "daily_calorie_target": 1500, "protein_target_g": 99,
        "has_pcos": 1, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    }

    test_context = {
        "heart_rate": 88, "sleep_quality": "bad", "energy_level": "tired",
        "mood": "stressed", "metabolic_state": "stress_recovery",
        "weather_condition": "hot", "temperature_c": 34.0,
        "slot": "lunch", "calorie_adjustment": -150,
    }

    # Simulate a user who has eaten m_007 before and loved it
    mock_logs = [
        {"meal_id": "m_007", "consumed": True, "rating": 5},
        {"meal_id": "m_007", "consumed": True, "rating": 4},
        {"meal_id": "m_010", "consumed": True, "rating": 3},
        {"meal_id": "m_013", "consumed": False, "rating": None},
    ]

    feedback_lookup = build_feedback_lookup(mock_logs, MEALS)

    print("── Running recommender test ─────────────────────────────")
    print(f"User:    {test_user['diet_type']}, {test_user['goal']}, PCOS={test_user['has_pcos']}")
    print(f"Context: {test_context['metabolic_state']}, slot={test_context['slot']}, "
          f"mood={test_context['mood']}")
    print()

    top3 = get_top3_meals(test_user, test_context, MEALS, feedback_lookup)

    if top3:
        print(f"Top 3 recommendations for {test_context['slot']}:\n")
        for i, meal in enumerate(top3, 1):
            print(f"  #{i}  {meal['name']}")
            print(f"       Score:      {meal['predicted_score']}")
            print(f"       Calories:   {meal['calories']} kcal")
            print(f"       Protein:    {meal['protein_g']}g")
            print(f"       Inflam:     {meal['inflammation_score']}/10")
            print(f"       Recovery:   {meal['recovery_impact']}")
            print(f"       Why:        {meal['why_recommended']}")
            print()
    else:
        print("No meals returned — check constraints and model loading.")

    # Verify a stressed veg user does not get non-veg or high-inflammation meals
    print("── Constraint verification ──────────────────────────────")
    for meal in top3:
        diet_ok   = meal["diet_type"] in ["veg"]
        inflam_ok = meal["inflammation_score"] <= 6
        print(f"  {meal['name']:<30} diet={meal['diet_type']} [{('ok' if diet_ok else 'FAIL')}]  "
              f"inflam={meal['inflammation_score']} [{('ok' if inflam_ok else 'WARN')}]")
