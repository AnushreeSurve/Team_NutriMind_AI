# ============================================================
#  routes/health.py  —  POST /health/health-plan
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import HealthPlanRequest
from services.other_services import health_plan

router = APIRouter()


@router.post("/health-plan")
def get_health_plan(req: HealthPlanRequest):
    """
    Returns a full day meal plan + food guidance tailored
    to a specific health condition (PCOS, diabetes, thyroid, BP).
    """
    result = health_plan(req.email, req.condition)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result
