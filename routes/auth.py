# ============================================================
#  routes/auth.py  —  POST /auth/signup
# ============================================================

from fastapi import APIRouter
from schemas.auth_schema import SignupRequest, SignupResponse
from services.auth_service import signup_user

router = APIRouter()


@router.post("/signup")
def signup(req: SignupRequest):
    """
    Register a new user.
    Calculates BMR, TDEE, calorie goal, and macro targets automatically.
    """
    result = signup_user(req)
    if "error" in result:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=result["error"])
    return result
