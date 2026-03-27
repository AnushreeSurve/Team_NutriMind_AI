# ============================================================
#  routes/preferences.py  —  POST /user/set-preferences  |  POST /user/get-preferences
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import SetPreferencesRequest, GetPreferencesRequest
from services.preference_service import set_preferences, get_preferences

router = APIRouter()


@router.post("/set-preferences")
def set_prefs(req: SetPreferencesRequest):
    result = set_preferences(req.email, req.diet_type, req.budget, req.allergies, req.conditions)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


@router.post("/get-preferences")
def get_prefs(req: GetPreferencesRequest):
    result = get_preferences(req.email)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result
