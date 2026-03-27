# ============================================================
#  routes/prediction.py  —  POST /ml/predict  |  POST /ml/metabolic-predict
# ============================================================

from fastapi import APIRouter, HTTPException
from schemas.other_schemas import PredictRequest, MetabolicPredictRequest
from services.other_services import predict, metabolic_predict

router = APIRouter()


@router.post("/predict")
def general_predict(req: PredictRequest):
    """
    Generic numeric prediction endpoint.
    Currently uses a weighted linear formula.
    Swap in a real sklearn / TensorFlow model here later.
    """
    return predict(req.feature_1, req.feature_2, req.feature_3)


@router.post("/metabolic-predict")
def metabolic_predict_route(req: MetabolicPredictRequest):
    """
    Predicts the user's metabolic state for the day based on:
    sleep, steps, calories consumed, heart rate, and mood.
    Also saves the result to morning_checkins table in Supabase.
    """
    from models.database import supabase
    profile = supabase.table("profiles").select("user_id").eq("email", req.email).execute()
    if not profile.data:
        raise HTTPException(status_code=404, detail="User not found. Please signup first.")

    return metabolic_predict(
        req.sleep_hours,
        req.steps,
        req.calories_consumed,
        req.heart_rate,
        req.mood,
        req.email,
    )
