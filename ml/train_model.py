# train_model.py
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Load the synthetic dataset, train an XGBoost Regressor to predict
#   meal_score, evaluate it thoroughly, and save the trained model.
#
# ML CONCEPTS COVERED:
#   - Train/test split: why you never evaluate on training data
#   - Feature matrix (X) vs target vector (y): the core supervised learning setup
#   - XGBoost Regressor: what it is and why it suits this problem
#   - Hyperparameters: what each one does
#   - Evaluation metrics: RMSE, MAE, R² — what they mean
#   - Feature importance: which inputs the model actually relies on
#   - Model persistence: saving and loading with joblib
#   - Sanity checking predictions: does the model make intuitive sense?
# ─────────────────────────────────────────────────────────────────────────────

import pandas as pd
import numpy as np
import joblib
import json
import os

from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

SEED        = 42
DATA_PATH   = "training_data.csv"
MODEL_PATH  = "meal_scorer.pkl"
ENCODINGS_PATH = "encodings.json"   # save encodings so recommender can use them

np.random.seed(SEED)


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — LOAD AND INSPECT DATA
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: always inspect your data before training.
# Shape, dtypes, missing values, and target distribution tell you if
# something went wrong in data generation before you waste time training.
# ─────────────────────────────────────────────────────────────────────────────

print("── STEP 1: Loading data ─────────────────────────────────")
df = pd.read_csv(DATA_PATH)

print(f"Shape:          {df.shape}  (rows, columns)")
print(f"Missing values: {df.isnull().sum().sum()}")
print(f"\nTarget (meal_score) distribution:")
print(f"  Min:    {df['meal_score'].min():.3f}")
print(f"  Max:    {df['meal_score'].max():.3f}")
print(f"  Mean:   {df['meal_score'].mean():.3f}")
print(f"  Median: {df['meal_score'].median():.3f}")
print(f"  Std:    {df['meal_score'].std():.3f}")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — SPLIT FEATURES (X) AND TARGET (y)
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: X is the feature matrix (inputs), y is the target vector (output).
# Every ML model learns a function  f(X) → y.
# XGBoost learns: given these 36 numbers about a user-context-meal combination,
# predict the meal_score. It does this by building an ensemble of decision
# trees where each tree corrects the errors of the previous ones.
# This technique is called gradient boosting — "boosting" because each
# new tree boosts the ensemble's accuracy.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 2: Preparing features ───────────────────────────")

FEATURE_COLUMNS = [
    # User
    "age", "bmi", "gender", "goal", "diet_type", "activity_level", "budget",
    "has_pcos", "has_diabetes", "has_thyroid", "has_bp",
    # Context
    "heart_rate", "sleep_quality", "energy_level", "mood", "metabolic_state",
    "weather_condition", "temperature_c", "slot", "calorie_today",
    "slot_calorie_target",
    # Meal
    "meal_calories", "meal_protein_g", "meal_carbs_g", "meal_fat_g",
    "meal_inflammation_score", "meal_recovery_impact", "meal_budget",
    "meal_prep_type", "meal_diet_type",
    # Derived
    "calorie_gap", "protein_ratio", "metabolic_tag_match",
    # Feedback history (zeros for now, will matter when real data comes in)
    "user_avg_rating_this_meal", "user_consumed_before",
    "user_avg_rating_similar_meals",
]

X = df[FEATURE_COLUMNS]
y = df["meal_score"]

print(f"Feature matrix X: {X.shape}")
print(f"Target vector y:  {y.shape}")
print(f"Features used:    {len(FEATURE_COLUMNS)}")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — TRAIN / TEST SPLIT
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: train/test split.
# You NEVER evaluate a model on data it was trained on — that would be like
# giving a student the exam answers during study and then using the same
# answers as the exam. The model would appear perfect but fail on new data.
# We hold out 20% of rows as a "test set" the model never sees during training.
# The model trains on 80% and is evaluated on the 20% it has never seen.
# This gives an honest estimate of real-world performance.
#
# shuffle=True: rows must be shuffled before splitting so the test set
# isn't accidentally all from one persona.
# random_state=SEED: same seed = same split every run = reproducible results.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 3: Train / test split ───────────────────────────")

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.20, random_state=SEED, shuffle=True
)

print(f"Training set:   {X_train.shape[0]} rows  (80%)")
print(f"Test set:       {X_test.shape[0]} rows  (20%)")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — DEFINE THE MODEL AND HYPERPARAMETERS
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: hyperparameters.
# These are settings you choose BEFORE training — the model does not learn them.
# They control HOW the model learns. Wrong hyperparameters → underfitting
# (model too simple) or overfitting (model memorises training data).
#
# n_estimators=300:
#   Number of decision trees in the ensemble. More trees = more capacity
#   to learn complex patterns, but also more risk of overfitting.
#   300 is a good starting point for ~5000 rows.
#
# max_depth=5:
#   How deep each decision tree can grow. Deeper = more complex rules.
#   Shallow trees (depth 3-5) generalise better on small datasets.
#
# learning_rate=0.05:
#   How much each new tree corrects previous errors. Lower = slower learning
#   but better generalisation. Lower learning_rate needs more n_estimators.
#
# subsample=0.8:
#   Each tree only sees 80% of training rows, chosen randomly.
#   This is like "dropout" for decision trees — prevents overfitting.
#
# colsample_bytree=0.8:
#   Each tree only sees 80% of features, chosen randomly.
#   Forces the model to learn with different feature subsets = robustness.
#
# min_child_weight=3:
#   A leaf node must have at least 3 samples. Prevents the model from
#   creating rules for tiny, unrepresentative groups.
#
# reg_alpha=0.1, reg_lambda=1.0:
#   L1 and L2 regularisation. Penalise overly complex models.
#   Encourages the model to use fewer, stronger features rather than
#   many weak ones — improves generalisation.
#
# objective='reg:squarederror':
#   Tells XGBoost this is a regression problem (predicting a number),
#   and to minimise squared error between predicted and actual scores.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 4: Defining model ───────────────────────────────")

model = XGBRegressor(
    n_estimators     = 300,
    max_depth        = 5,
    learning_rate    = 0.05,
    subsample        = 0.8,
    colsample_bytree = 0.8,
    min_child_weight = 3,
    reg_alpha        = 0.1,
    reg_lambda       = 1.0,
    objective        = "reg:squarederror",
    random_state     = SEED,
    n_jobs           = -1,      # use all CPU cores
    verbosity        = 0,
)

print("Model defined: XGBoost Regressor")
print(f"  Trees (n_estimators):   {model.n_estimators}")
print(f"  Max tree depth:         {model.max_depth}")
print(f"  Learning rate:          {model.learning_rate}")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — CROSS VALIDATION (before final training)
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: cross validation (CV).
# A single train/test split can be lucky or unlucky depending on which rows
# end up in which set. CV splits the data into 5 equal "folds", trains on
# 4 folds, tests on 1 fold, rotates, and repeats 5 times. You get 5
# test scores and average them — a much more reliable performance estimate.
# We do this BEFORE final training to check the model is worth training.
# Negative RMSE is used because sklearn optimises by maximising score —
# so we negate RMSE to make "higher = better" consistent.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 5: Cross validation (5-fold) ────────────────────")

cv_scores = cross_val_score(
    model, X_train, y_train,
    cv=5,
    scoring="neg_root_mean_squared_error",
    n_jobs=-1
)

cv_rmse = -cv_scores
print(f"CV RMSE scores:   {[round(s, 4) for s in cv_rmse]}")
print(f"CV RMSE mean:     {cv_rmse.mean():.4f}")
print(f"CV RMSE std:      {cv_rmse.std():.4f}  (lower = more stable)")

# Rule of thumb: RMSE < 0.15 on a 0-1 target is good for this dataset size
if cv_rmse.mean() < 0.20:
    print("Cross validation: GOOD — proceeding to full training")
else:
    print("Cross validation: WARN — RMSE is high, but proceeding anyway")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — TRAIN FINAL MODEL
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: final training on full training set.
# After CV confirms the model is reasonable, we train on ALL training data
# (not just 4/5 of it as in CV). This gives the model maximum data to
# learn from before saving. We still hold out the 20% test set for final
# honest evaluation.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 6: Training final model ─────────────────────────")
print("Training... (this may take 10–30 seconds)")

model.fit(X_train, y_train)
print("Training complete.")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — EVALUATE ON TEST SET
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: evaluation metrics for regression.
#
# RMSE (Root Mean Squared Error):
#   Average prediction error in the same units as your target (0–1 here).
#   RMSE = 0.10 means predictions are off by 0.10 on average.
#   Squaring errors before averaging means large errors are penalised more.
#   Lower is better. For a 0–1 target, RMSE < 0.15 is solid.
#
# MAE (Mean Absolute Error):
#   Like RMSE but without squaring — treats all errors equally.
#   More interpretable: MAE = 0.08 means "on average, predictions are
#   0.08 away from the true score." Lower is better.
#
# R² (R-squared):
#   How much of the variance in meal_score the model explains.
#   R² = 1.0 means perfect predictions (overfitting).
#   R² = 0.0 means the model is no better than predicting the mean.
#   R² = 0.7 means the model explains 70% of score variation.
#   For noisy human behavior data, R² > 0.6 is very good.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 7: Evaluation on held-out test set ──────────────")

y_pred = model.predict(X_test)
y_pred = np.clip(y_pred, 0.0, 1.0)   # clip predictions to valid range

rmse = np.sqrt(mean_squared_error(y_test, y_pred))
mae  = mean_absolute_error(y_test, y_pred)
r2   = r2_score(y_test, y_pred)

print(f"RMSE:  {rmse:.4f}  (avg error in score units — lower is better)")
print(f"MAE:   {mae:.4f}  (avg absolute error — lower is better)")
print(f"R²:    {r2:.4f}  (variance explained — higher is better)")

if rmse < 0.15:
    print("\nModel quality: EXCELLENT")
elif rmse < 0.20:
    print("\nModel quality: GOOD")
elif rmse < 0.25:
    print("\nModel quality: ACCEPTABLE for MVP")
else:
    print("\nModel quality: POOR — consider tuning hyperparameters")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 8 — FEATURE IMPORTANCE
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: feature importance.
# XGBoost tracks how much each feature contributes to reducing prediction
# error across all trees. Features with high importance are the ones the
# model relies on most. This tells you:
#   - Which signals actually matter for meal scoring
#   - Whether the model learned what you expected (nutrition logic)
#     or something spurious (random noise)
#   - Which features could be removed without hurting performance
#
# Expected top features: metabolic_tag_match, meal_inflammation_score,
# meal_diet_type, metabolic_state, calorie_gap, meal_calories
# If random or trivial features appear at top — something is wrong.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 8: Feature importance (top 15) ──────────────────")

importances = pd.Series(
    model.feature_importances_,
    index=FEATURE_COLUMNS
).sort_values(ascending=False)

print(f"\n{'Feature':<35} {'Importance':>10}")
print("─" * 47)
for feat, imp in importances.head(15).items():
    bar = "█" * int(imp * 200)
    print(f"{feat:<35} {imp:>8.4f}  {bar}")

print(f"\nBottom 5 (least useful):")
for feat, imp in importances.tail(5).items():
    print(f"  {feat:<35} {imp:.4f}")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 9 — SANITY CHECK PREDICTIONS
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: sanity checking / model interpretability.
# After training, you must verify the model makes intuitive sense.
# Metrics alone don't tell you IF the model learned the right patterns —
# only that it fits the data well. We construct specific test cases where
# we know the expected output and check the model agrees.
# This is called "behavioral testing" of ML models.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 9: Sanity checks ─────────────────────────────────")

def make_test_row(overrides):
    """Build a neutral base row and apply overrides for targeted tests."""
    base = {
        "age": 28, "bmi": 23.0, "gender": 1, "goal": 0,
        "diet_type": 0, "activity_level": 1, "budget": 1,
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "heart_rate": 70, "sleep_quality": 1, "energy_level": 1, "mood": 1,
        "metabolic_state": 3, "weather_condition": 0, "temperature_c": 28,
        "slot": 1, "calorie_today": 1600, "slot_calorie_target": 560,
        "meal_calories": 480, "meal_protein_g": 18, "meal_carbs_g": 55,
        "meal_fat_g": 12, "meal_inflammation_score": 3,
        "meal_recovery_impact": 1, "meal_budget": 1,
        "meal_prep_type": 0, "meal_diet_type": 0,
        "calorie_gap": 80, "protein_ratio": 0.24, "metabolic_tag_match": 0,
        "user_avg_rating_this_meal": 0.0, "user_consumed_before": 0,
        "user_avg_rating_similar_meals": 0.0,
    }
    base.update(overrides)
    return pd.DataFrame([base])[FEATURE_COLUMNS]

def predict_single(overrides):
    row = make_test_row(overrides)
    score = float(np.clip(model.predict(row)[0], 0.0, 1.0))
    return round(score, 3)

# Test A: Tag match should score higher than no match
score_tag_match    = predict_single({"metabolic_tag_match": 1, "metabolic_state": 0})
score_no_tag_match = predict_single({"metabolic_tag_match": 0, "metabolic_state": 0})
tag_test = "PASS" if score_tag_match > score_no_tag_match else "FAIL"
print(f"Tag match > no match:           {score_tag_match:.3f} vs {score_no_tag_match:.3f}  [{tag_test}]")

# Test B: Low inflammation should score higher than high inflammation for stressed user
score_low_inflam  = predict_single({"meal_inflammation_score": 2, "mood": 0})
score_high_inflam = predict_single({"meal_inflammation_score": 8, "mood": 0})
inflam_test = "PASS" if score_low_inflam > score_high_inflam else "FAIL"
print(f"Low inflam > high inflam (stressed): {score_low_inflam:.3f} vs {score_high_inflam:.3f}  [{inflam_test}]")

# Test C: Diet mismatch (non-veg meal for veg user) should score near 0
# meal_diet_type=1 (non-veg), diet_type=0 (veg)
score_diet_mismatch = predict_single({"diet_type": 0, "meal_diet_type": 1})
score_diet_match    = predict_single({"diet_type": 0, "meal_diet_type": 0})
diet_test = "PASS" if score_diet_mismatch < score_diet_match else "FAIL"
print(f"Diet match > diet mismatch:     {score_diet_match:.3f} vs {score_diet_mismatch:.3f}  [{diet_test}]")

# Test D: High protein meal should score higher for muscle repair state
score_high_protein = predict_single({"meal_protein_g": 42, "protein_ratio": 0.56, "metabolic_state": 4})
score_low_protein  = predict_single({"meal_protein_g": 8,  "protein_ratio": 0.11, "metabolic_state": 4})
protein_test = "PASS" if score_high_protein > score_low_protein else "FAIL"
print(f"High protein > low protein (muscle repair): {score_high_protein:.3f} vs {score_low_protein:.3f}  [{protein_test}]")

# Test E: Good calorie fit should score higher than large calorie gap
score_small_gap = predict_single({"calorie_gap": 20})
score_large_gap = predict_single({"calorie_gap": 300})
gap_test = "PASS" if score_small_gap > score_large_gap else "FAIL"
print(f"Small calorie gap > large gap:  {score_small_gap:.3f} vs {score_large_gap:.3f}  [{gap_test}]")

# Test F: User feedback history — previously liked meal should score higher
score_liked     = predict_single({"user_avg_rating_this_meal": 1.0, "user_consumed_before": 1})
score_no_history= predict_single({"user_avg_rating_this_meal": 0.0, "user_consumed_before": 0})
history_test = "PASS" if score_liked > score_no_history else "FAIL"
print(f"Liked before > no history:      {score_liked:.3f} vs {score_no_history:.3f}  [{history_test}]")

sanity_results = [tag_test, inflam_test, diet_test, protein_test, gap_test, history_test]
passed_count = sanity_results.count("PASS")
print(f"\nSanity checks: {passed_count}/6 passed")
if passed_count >= 5:
    print("Model has learned expected nutrition patterns — good to deploy")
elif passed_count >= 3:
    print("Model partially learned patterns — acceptable for MVP, revisit with more data")
else:
    print("Model failed sanity checks — do not deploy, check data generation logic")


# ─────────────────────────────────────────────────────────────────────────────
# STEP 10 — SAVE THE MODEL AND ENCODINGS
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: model persistence.
# joblib serialises the trained model object to a binary .pkl file.
# When your FastAPI server starts, it loads this file once into memory
# and uses it for every recommendation request.
# Saving ENCODINGS separately is critical — the recommender must encode
# incoming strings (e.g. "stressed") to integers (0) using EXACTLY the
# same mapping used during training. If mappings differ, predictions are
# completely wrong even though the model loaded correctly.
# ─────────────────────────────────────────────────────────────────────────────

print("\n── STEP 10: Saving model ─────────────────────────────────")

joblib.dump(model, MODEL_PATH)
print(f"Model saved → {MODEL_PATH}")

# Save encodings for use in recommender.py
ENCODINGS = {
    "gender":            {"male": 0, "female": 1, "other": 2},
    "goal":              {"lose": 0, "maintain": 1, "gain": 2},
    "diet_type":         {"veg": 0, "non-veg": 1, "vegan": 2, "jain": 3},
    "activity_level":    {"sedentary": 0, "moderate": 1, "active": 2},
    "budget":            {"low": 0, "mid": 1, "high": 2},
    "sleep_quality":     {"bad": 0, "okay": 1, "good": 2},
    "energy_level":      {"tired": 0, "normal": 1, "energetic": 2},
    "mood":              {"stressed": 0, "neutral": 1, "calm": 2},
    "metabolic_state":   {
        "stress_recovery": 0, "cortisol_buffer": 1, "fat_burn": 2,
        "normal": 3, "muscle_repair": 4, "performance": 5
    },
    "weather_condition": {"hot": 0, "cold": 1, "rainy": 2, "humid": 3},
    "slot":              {"breakfast": 0, "lunch": 1, "snack": 2, "dinner": 3},
    "recovery_impact":   {"low": 0, "medium": 1, "high": 2},
    "prep_type":         {"home": 0, "restaurant": 1, "cloud_kitchen": 2},
    "meal_diet_type":    {"veg": 0, "non-veg": 1, "vegan": 2, "jain": 3},
    "meal_budget":       {"low": 0, "mid": 1, "high": 2},
    "feature_columns":   FEATURE_COLUMNS,
}

with open(ENCODINGS_PATH, "w") as f:
    json.dump(ENCODINGS, f, indent=2)
print(f"Encodings saved → {ENCODINGS_PATH}")

print("\n── DONE ──────────────────────────────────────────────────")
print(f"Model:     {MODEL_PATH}")
print(f"Encodings: {ENCODINGS_PATH}")
print("Next step: recommender.py — loads these files and scores real meals")
