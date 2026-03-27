# ml/db_connector.py
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


def fetch_all_meals() -> list:
    meals_resp = (
        supabase.table("meals")
        .select("*")
        .eq("is_active", True)
        .execute()
    )
    meals = meals_resp.data
    if not meals:
        print("[db] WARNING: No meals found in DB")
        return []

    meal_ids = [m["meal_id"] for m in meals]

    tags_resp = (
        supabase.table("meal_tags")
        .select("meal_id, tag")
        .in_("meal_id", meal_ids)
        .execute()
    )
    tags_by_meal = {}
    for row in tags_resp.data:
        tags_by_meal.setdefault(row["meal_id"], []).append(row["tag"])

    micro_resp = (
        supabase.table("meal_micronutrients")
        .select("meal_id, micronutrient")
        .in_("meal_id", meal_ids)
        .execute()
    )
    micro_by_meal = {}
    for row in micro_resp.data:
        micro_by_meal.setdefault(row["meal_id"], []).append(row["micronutrient"])

    enriched = []
    for meal in meals:
        mid = meal["meal_id"]
        meal["tags"]               = tags_by_meal.get(mid, [])
        meal["key_micronutrients"] = micro_by_meal.get(mid, [])
        meal["suitable_slots"]     = _derive_suitable_slots(meal)
        meal["high_sodium"]        = meal.get("high_sodium", False)
        meal["high_sugar"]         = meal.get("high_sugar",  False)
        meal["high_carb"]          = meal.get("high_carb",   False)
        enriched.append(meal)

    print(f"[db] Fetched {len(enriched)} meals from Supabase")
    return enriched


def _derive_suitable_slots(meal: dict) -> list:
    cal = meal.get("calories", 400)
    if cal < 250:
        return ["snack"]
    elif cal < 400:
        return ["breakfast", "snack"]
    elif cal < 600:
        return ["breakfast", "lunch", "dinner"]
    else:
        return ["lunch", "dinner"]


def fetch_user_profile(user_id: str) -> dict:
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

    conditions_resp = (
        supabase.table("user_conditions")
        .select("condition")
        .eq("user_id", user_id)
        .execute()
    )
    condition_list       = [r["condition"] for r in (conditions_resp.data or [])]
    user["has_pcos"]     = int("pcos"     in condition_list)
    user["has_diabetes"] = int("diabetes" in condition_list)
    user["has_thyroid"]  = int("thyroid"  in condition_list)
    user["has_bp"]       = int("bp"       in condition_list)

    allergies_resp = (
        supabase.table("user_allergies")
        .select("allergy")
        .eq("user_id", user_id)
        .execute()
    )
    user["allergies"] = [r["allergy"] for r in (allergies_resp.data or [])]

    return user


def fetch_todays_checkin(user_id: str, date_str: str) -> dict | None:
    """
    date_str: "YYYY-MM-DD" from Flutter (IST local date — avoids UTC mismatch)
    Column in DB is 'checkin_date', NOT 'date'
    """
    resp = (
        supabase.table("morning_checkins")
        .select("*")
        .eq("user_id", str(user_id))       # cast to str — uuid vs text safety
        .eq("checkin_date", date_str)       # ← correct column name
        .execute()
    )

    if not resp.data:
        print(f"[db] No checkin found for user={user_id} date={date_str}")
        return None

    checkin = resp.data[0]
    checkin["date"] = checkin["checkin_date"]  # alias for ML code compatibility
    return checkin


def fetch_meal_logs(user_id: str, days: int = 30) -> list:
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


def save_daily_meal_plan(
    user_id:           str,
    plan_date:         str,
    metabolic_state:   str,
    weather_condition: str,
    slot:              str,
    scheduled_time:    str,
    top3_meals:        list,
) -> bool:
    if not top3_meals:
        print(f"[db] No meals to save for slot {slot}")
        return False

    meal_ids = [m["meal_id"] for m in top3_meals]
    while len(meal_ids) < 3:
        meal_ids.append(meal_ids[-1])

    record = {
        "user_id":           user_id,
        "plan_date":         plan_date,
        "metabolic_state":   metabolic_state,
        "weather_condition": weather_condition,
        "slot":              slot,
        "scheduled_time":    scheduled_time,
        "option_1_meal_id":  meal_ids[0],
        "option_2_meal_id":  meal_ids[1],
        "option_3_meal_id":  meal_ids[2],
    }

    resp = (
        supabase.table("daily_meal_plans")
        .upsert(record, on_conflict="user_id,plan_date,slot")
        .execute()
    )

    success = bool(resp.data)
    print(f"[db] {'Saved' if success else 'Failed to save'} meal plan: {slot} for {user_id} on {plan_date}")
    return success