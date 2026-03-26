# ============================================================
#  services/preference_service.py  —  Supabase version
# ============================================================

from models.database import supabase


def get_user(email: str) -> dict | None:
    res = supabase.table("profiles").select("*").eq("email", email).execute()
    return res.data[0] if res.data else None


def set_preferences(email: str, diet_type: str, budget: str, allergies: list, conditions: list) -> dict:
    user = get_user(email)
    if not user:
        return {"error": "User not found. Please signup first."}

    user_id = user["user_id"]

    # Update core profile fields
    supabase.table("profiles").update({
        "diet_type": diet_type,
        "budget":    budget,
    }).eq("user_id", user_id).execute()

    # Replace allergies — delete old, insert new
    supabase.table("user_allergies").delete().eq("user_id", user_id).execute()
    if allergies:
        supabase.table("user_allergies").insert(
            [{"user_id": user_id, "allergy": a} for a in allergies]
        ).execute()

    # Replace conditions — delete old, insert new
    supabase.table("user_conditions").delete().eq("user_id", user_id).execute()
    if conditions:
        supabase.table("user_conditions").insert(
            [{"user_id": user_id, "condition": c} for c in conditions]
        ).execute()

    return {
        "message": "Preferences saved successfully.",
        "preferences": {
            "diet_type":  diet_type,
            "budget":     budget,
            "allergies":  allergies,
            "conditions": conditions,
        },
    }


def get_preferences(email: str) -> dict:
    user = get_user(email)
    if not user:
        return {"error": "User not found."}

    user_id = user["user_id"]

    allergies  = supabase.table("user_allergies").select("allergy").eq("user_id", user_id).execute()
    conditions = supabase.table("user_conditions").select("condition").eq("user_id", user_id).execute()

    return {
        "email": email,
        "preferences": {
            "diet_type":  user.get("diet_type"),
            "budget":     user.get("budget"),
            "goal":       user.get("goal"),
            "allergies":  [r["allergy"]   for r in allergies.data],
            "conditions": [r["condition"] for r in conditions.data],
        },
    }
