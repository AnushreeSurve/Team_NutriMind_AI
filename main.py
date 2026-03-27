# ============================================================
#  main.py  —  NutriSync AI Backend (Entry Point)
#  Run with:  uvicorn main:app --reload
# ============================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import auth, meals, food, preferences, recommendations, weather, health, prediction, ppg

app = FastAPI(
    title="NutriSync AI",
    description="AI-based Nutrition Assistant Backend",
    version="1.0.0",
)

# Allow all origins for development (tighten this in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register all route groups ──────────────────────────────
app.include_router(auth.router,            prefix="/auth",         tags=["Auth / User"])
app.include_router(meals.router,           prefix="/meals",        tags=["Meal Tracking"])
app.include_router(food.router,            prefix="/food",         tags=["Food Analysis"])
app.include_router(preferences.router,     prefix="/user",         tags=["Personalization"])
app.include_router(recommendations.router, prefix="/recommend",    tags=["Recommendations"])
app.include_router(weather.router,         prefix="/weather",      tags=["Weather-Based Suggestions"])
app.include_router(health.router,          prefix="/health",       tags=["Health Condition Support"])
app.include_router(prediction.router,      prefix="/ml",           tags=["ML / Prediction"])
app.include_router(ppg.router,             prefix="/ppg",       tags=["PPG / Biometric Sensing"])

@app.get("/", tags=["Root"])
def root():
    return {"message": "Welcome to NutriSync AI Backend 🥗", "docs": "/docs"}
