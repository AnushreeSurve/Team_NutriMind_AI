# db_connector.py
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   All Supabase queries needed by the recommender live here.
#   This file is the bridge between your trained model and real DB data.
#   Backend will also use similar queries — but this version is for the
#   ML module's internal use and testing.
# ─────────────────────────────────────────────────────────────────────────────

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise EnvironmentError(
        "SUPABASE_URL and SUPABASE_KEY must be set in your .env file"
    )

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ─────────────────────────────────────────────────────────────────────────────
# FETCH ALL ACTIVE MEALS WITH TAGS AND MICRONUTRIENTS
# ─────────────────────────────────────────────────────────────────────────────

def fetch_all_meals() -> list:
    """
    Fetch all active meals from the DB and attach their tags and micronutrients.
    Returns a list of meal dicts in the same format recommender.py expects.
    This replaces MEALS from meals_reference.py in production.
    """

    # Fetch all active meals
    meals_resp = (
        supabase.table("meals")
        .select("*")
        .eq("is_active", True)
        .execute()
    )
    meals = meals_resp.data
    if not meals:
        print("[db] WARNING: No meals found in DB — check that meals table is seeded")
        return []

    meal_ids = [m["meal_id"] for m in meals]

    # Fetch all tags for these meals in one query
    tags_resp = (
        supabase.table("meal_tags")
        .select("meal_id, tag")
        .in_("meal_id", meal_ids)
        .execute()
    )
    # Group tags by meal_id
    tags_by_meal = {}
    for row in tags_resp.data:
        tags_by_meal.setdefault(row["meal_id"], []).append(row["tag"])

    # Fetch all micronutrients for these meals in one query
    micro_resp = (
        supabase.table("meal_micronutrients")
        .select("meal_id, micronutrient")
        .in_("meal_id", meal_ids)
        .execute()
    )
    micro_by_meal = {}
    for row in micro_resp.data:
        micro_by_meal.setdefault(row["meal_id"], []).append(row["micronutrient"])

    # Attach tags and micronutrients to each meal
    # Also add suitable_slots derived from meal properties
    # (your meals table doesn't have a suitable_slots column
    #  so we derive it from the meal name / type — or you can
    #  ask DB person to add a suitable_slots column to meals table)
    enriched = []
    for meal in meals:
        mid = meal["meal_id"]
        meal["tags"]            = tags_by_meal.get(mid, [])
        meal["key_micronutrients"] = micro_by_meal.get(mid, [])
        meal["suitable_slots"]  = _derive_suitable_slots(meal)

        # Normalise column names to match what recommender.py expects
        # (DB uses inflammation_score, recommender uses inflammation_score — fine)
        # Add boolean flags the scorer uses
        meal["high_sodium"] = meal.get("high_sodium", False)
        meal["high_sugar"]  = meal.get("high_sugar",  False)
        meal["high_carb"]   = meal.get("high_carb",   False)

        enriched.append(meal)

    print(f"[db] Fetched {len(enriched)} meals from Supabase")
    return enriched


def _derive_suitable_slots(meal: dict) -> list:
    """
    Derive which slots a meal is suitable for based on calorie content.
    If your DB person adds a suitable_slots column to the meals table,
    use that directly instead of this function.
    """
    cal = meal.get("calories", 400)
    if cal < 250:
        return ["snack"]
    elif cal < 400:
        return ["breakfast", "snack"]
    elif cal < 600:
        return ["breakfast", "lunch", "dinner"]
    else:
        return ["lunch", "dinner"]


# ─────────────────────────────────────────────────────────────────────────────
# FETCH USER PROFILE WITH CONDITIONS AND ALLERGIES
# ─────────────────────────────────────────────────────────────────────────────

def fetch_user_profile(user_id: str) -> dict:
    """
    Fetch user profile and attach their conditions and allergies as flat fields.
    Returns a single user dict ready for recommender.py.
    """

    # Main profile
    profile_resp = (
        supabase.table("profiles")
        .select("*")
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    if not profile_resp.data:
        raise ValueError(f"No profile found for user_id: {user_id}")

    user = profile_resp.data

    # Conditions → flat boolean fields
    conditions_resp = (
        supabase.table("user_conditions")
        .select("condition")
        .eq("user_id", user_id)
        .execute()
    )
    condition_list = [r["condition"] for r in conditions_resp.data]
    user["has_pcos"]     = int("pcos"     in condition_list)
    user["has_diabetes"] = int("diabetes" in condition_list)
    user["has_thyroid"]  = int("thyroid"  in condition_list)
    user["has_bp"]       = int("bp"       in condition_list)

    # Allergies → list
    allergies_resp = (
        supabase.table("user_allergies")
        .select("allergy")
        .eq("user_id", user_id)
        .execute()
    )
    user["allergies"] = [r["allergy"] for r in allergies_resp.data]

    return user


# ─────────────────────────────────────────────────────────────────────────────
# FETCH TODAY'S CHECK-IN CONTEXT
# ─────────────────────────────────────────────────────────────────────────────

def fetch_todays_checkin(user_id: str, date_str: str) -> dict:
    """
    Fetch morning check-in for a specific user and date.
    date_str format: "YYYY-MM-DD"
    Returns the checkin dict or None if check-in not done yet.
    """

    resp = (
        supabase.table("morning_checkins")
        .select("*")
        .eq("user_id", user_id)
        .eq("checkin_date", date_str)
        .execute()
    )

    if not resp.data:
        return None

    checkin = resp.data[0]   # get first row as a plain dict
    if "checkin_date" in checkin:
        checkin["date"] = checkin["checkin_date"]
    return checkin


# ─────────────────────────────────────────────────────────────────────────────
# FETCH MEAL LOGS FOR FEEDBACK LOOKUP
# ─────────────────────────────────────────────────────────────────────────────

def fetch_meal_logs(user_id: str, days: int = 30) -> list:
    """
    Fetch recent meal logs for a user.
    Used to build feedback_lookup for personalisation.
    Default: last 30 days. New users will get an empty list — that's fine.
    """
    from datetime import date, timedelta
    cutoff = (date.today() - timedelta(days=days)).isoformat()

    resp = (
        supabase.table("meal_logs")
        .select("meal_id, consumed, rating, metabolic_state_that_day")
        .eq("user_id", user_id)
        .gte("log_date", cutoff)
        .execute()
    )

    return resp.data or []


# ─────────────────────────────────────────────────────────────────────────────
# SAVE DAILY MEAL PLAN TO DB
# ─────────────────────────────────────────────────────────────────────────────

def save_daily_meal_plan(
    user_id:          str,
    plan_date:        str,
    metabolic_state:  str,
    weather_condition: str,
    slot:             str,
    scheduled_time:   str,
    top3_meals:       list,
) -> bool:
    """
    Save the recommended top 3 meals for a slot to daily_meal_plans table.
    Called after get_top3_meals() returns results.
    Returns True if saved successfully.
    """

    if len(top3_meals) < 1:
        print(f"[db] No meals to save for slot {slot}")
        return False

    # Pad to 3 if fewer than 3 returned
    meal_ids = [m["meal_id"] for m in top3_meals]
    while len(meal_ids) < 3:
        meal_ids.append(meal_ids[-1])   # repeat last meal if fewer than 3

    record = {
        "user_id":          user_id,
        "plan_date":         plan_date,
        "metabolic_state":  metabolic_state,
        "weather_condition": weather_condition,
        "slot":             slot,
        "scheduled_time":   scheduled_time,
        "option_1_meal_id": meal_ids[0],
        "option_2_meal_id": meal_ids[1],
        "option_3_meal_id": meal_ids[2],
    }

    resp = (
        supabase.table("daily_meal_plans")
        .upsert(record, on_conflict="user_id,plan_date,slot")
        .execute()
    )

    success = bool(resp.data)
    if success:
        print(f"[db] Saved meal plan: {slot} for {user_id} on {plan_date}")
    else:
        print(f"[db] Failed to save meal plan for {slot}")
    return success
