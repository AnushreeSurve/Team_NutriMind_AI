/// Core constants for the NutriMindAI application.
/// Contains API base URL and all endpoint paths matching the FastAPI backend.
library;

class ApiConstants {
  ApiConstants._();

  // ── Base URL ────────────────────────────────────────────────
  // Change this to your backend IP/domain
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Supabase & Gemini Keys ──────────────────────────────────
  static const String supabaseUrl = 'https://iqfrnxogfusrpygjnzzs.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxZnJueG9nZnVzcnB5Z2puenpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMDUyMTQsImV4cCI6MjA4OTU4MTIxNH0.zLWOOY5s8rx0ooFCWpC3e2QmPCKbb0AqN_vvEcnzpKE';
  static const String geminiApiKey = 'AIzaSyDm4Rfj1XJWCmWRgYg5XF363h_4XVNIYsk';

  // ── Auth ────────────────────────────────────────────────────
  static const String signup = '/auth/signup';

  // ── Meals ───────────────────────────────────────────────────
  static const String addMeal = '/meals/add-meal';
  static const String dailyCalories = '/meals/daily-calories';

  // ── Food ────────────────────────────────────────────────────
  static const String analyzeFood = '/food/analyze-food';

  // ── Preferences ─────────────────────────────────────────────
  static const String setPreferences = '/user/set-preferences';
  static const String getPreferences = '/user/get-preferences';

  // ── Recommendations ─────────────────────────────────────────
  static const String mealRecommendation = '/recommend/meal-recommendation';
  static const String fullDayRecommendation = '/recommend/full-day';

  // ── Weather ─────────────────────────────────────────────────
  static const String weatherMeals = '/weather/weather-meals';

  // ── Health ──────────────────────────────────────────────────
  static const String healthPlan = '/health/health-plan';

  // ── ML / Prediction ─────────────────────────────────────────
  static const String predict = '/ml/predict';
  static const String metabolicPredict = '/ml/metabolic-predict';

  // ── PPG / Biometric ─────────────────────────────────────────
  static const String ppgAnalyze = '/ppg/analyze';
  static const String ppgSubmitReading = '/ppg/submit-reading';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'NutriMind AI';
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 350);
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
}
