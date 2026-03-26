# ============================================================
#  services/recommendation_service.py  —  Supabase version
#  Reads meals from the `meals` table, filtered by user profile.
#  Falls back to in-catalog defaults if DB has no meals yet.
# ============================================================

from models.database import supabase

# Fallback catalog (used if meals table is empty)
FALLBACK_CATALOG = [
    {"name": "Oats with Banana",      "calories": 280, "protein_g": 8,  "slot": ["breakfast"],       "diet": ["veg","vegan","jain"],      "budget": ["low","mid","high"]},
    {"name": "Paneer Bhurji + Roti",  "calories": 420, "protein_g": 22, "slot": ["lunch"],           "diet": ["veg","jain"],              "budget": ["mid","high"]},
    {"name": "Chicken Breast + Rice", "calories": 450, "protein_g": 38, "slot": ["lunch","dinner"],  "diet": ["non-veg"],                 "budget": ["mid","high"]},
    {"name": "Moong Dal Khichdi",     "calories": 320, "protein_g": 14, "slot": ["lunch","dinner"],  "diet": ["veg","vegan","jain"],      "budget": ["low","mid"]},
    {"name": "Idli + Sambar",         "calories": 200, "protein_g": 7,  "slot": ["breakfast"],       "diet": ["veg","vegan"],             "budget": ["low","mid"]},
    {"name": "Mixed Fruit Bowl",      "calories": 150, "protein_g": 2,  "slot": ["snack"],           "diet": ["veg","vegan","jain","non-veg"], "budget": ["low","mid","high"]},
    {"name": "Rajma + Brown Rice",    "calories": 400, "protein_g": 18, "slot": ["lunch","dinner"],  "diet": ["veg","vegan"],             "budget": ["low","mid"]},
    {"name": "Poha",                  "calories": 250, "protein_g": 5,  "slot": ["breakfast","snack"],"diet": ["veg","jain"],             "budget": ["low"]},
]


def recommend_meals(email: str, slot: str) -> dict:
    # 1. Fetch user profile for diet + budget
    profile_res = supabase.table("profiles").select("diet_type, budget, daily_calorie_target").eq("email", email).execute()
    if not profile_res.data:
        return {"error": "User not found."}

    user   = profile_res.data[0]
    diet   = user.get("diet_type", "veg")
    budget = user.get("budget",    "mid")

    # 2. Try fetching from meals table in Supabase
    meals_res = (
        supabase.table("meals")
        .select("name, calories, protein_g, carbs_g, fat_g, why_recommended, inflammation_score, recovery_impact")
        .eq("diet_type", diet)
        .eq("budget", budget)
        .eq("is_active", True)
        .limit(6)
        .execute()
    )

    if meals_res.data:
        options = meals_res.data[:3]
        source  = "supabase"
    else:
        # 3. Fall back to hardcoded catalog
        filtered = [
            m for m in FALLBACK_CATALOG
            if slot in m["slot"] and diet in m["diet"] and budget in m["budget"]
        ] or [m for m in FALLBACK_CATALOG if slot in m["slot"]]
        options = filtered[:3]
        source  = "fallback_catalog"

    return {
        "slot":    slot,
        "diet":    diet,
        "budget":  budget,
        "source":  source,
        "options": options,
        "tip":     "Pick the meal that matches your energy today.",
    }
