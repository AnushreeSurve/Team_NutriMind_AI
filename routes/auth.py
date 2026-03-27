# ============================================================
#  routes/auth.py
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.auth_schema import SignupRequest
from services.auth_service import signup_user, login_user
from pydantic import BaseModel, EmailStr

router = APIRouter()


class LoginRequest(BaseModel):
    email: EmailStr
    password: str  # received but backend uses email+"_nutrisync" scheme


@router.post("/signup")
def signup(req: SignupRequest):
    result = signup_user(req)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return result


@router.post("/login")
def login(req: LoginRequest):
    result = login_user(req.email)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result