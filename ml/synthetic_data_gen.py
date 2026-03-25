# synthetic_data_gen.py
# ─────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Generate a synthetic training dataset for the NutriSync meal scoring model.
#   Each row = one (user, context, meal) combination with a derived meal_score.
#
# ML CONCEPTS COVERED HERE:
#   - Feature engineering: turning raw domain knowledge into model inputs
#   - Supervised learning setup: defining input features + target variable
#   - Correlated sampling: making synthetic data behave like real data
#   - Label/target construction: deriving a meaningful score from rules
#   - Noise injection: preventing the model from memorising perfect patterns
#   - Class balance awareness: ensuring all states and personas are represented
# ─────────────────────────────────────────────────────────────────────────────

import pandas as pd
import numpy as np
import random
import os
from meals_reference import MEALS, SLOT_CALORIE_FRACTION

# Fix random seeds so your dataset is reproducible.
# ML concept: reproducibility is critical — if you regenerate data with a
# different seed you get different results, making debugging impossible.
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

OUTPUT_PATH = "training_data.csv"
ROWS_TARGET = 5000   # aim for ~5000 rows — enough for XGBoost to learn patterns


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — DEFINE PERSONAS
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: instead of fully random users, we define structured personas.
# This ensures the model sees diverse but realistic combinations.
# Fully random users could produce impossible combos (e.g. vegan with
# "non-veg preference"), which adds noise that hurts training.
# ─────────────────────────────────────────────────────────────────────────────

PERSONAS = [
    {
        "persona_id": "P01",
        "age": 24, "gender": "female", "height_cm": 160, "weight_kg": 62,
        "goal": "lose", "diet_type": "veg", "activity_level": "moderate",
        "budget": "low",
        "has_pcos": 1, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P02",
        "age": 21, "gender": "male", "height_cm": 175, "weight_kg": 70,
        "goal": "maintain", "diet_type": "non-veg", "activity_level": "active",
        "budget": "low",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P03",
        "age": 45, "gender": "male", "height_cm": 168, "weight_kg": 85,
        "goal": "lose", "diet_type": "veg", "activity_level": "sedentary",
        "budget": "mid",
        "has_pcos": 0, "has_diabetes": 1, "has_thyroid": 0, "has_bp": 1,
        "allergies": [],
    },
    {
        "persona_id": "P04",
        "age": 28, "gender": "male", "height_cm": 178, "weight_kg": 75,
        "goal": "gain", "diet_type": "non-veg", "activity_level": "active",
        "budget": "high",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P05",
        "age": 35, "gender": "female", "height_cm": 155, "weight_kg": 58,
        "goal": "maintain", "diet_type": "jain", "activity_level": "moderate",
        "budget": "mid",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 1, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P06",
        "age": 22, "gender": "female", "height_cm": 162, "weight_kg": 55,
        "goal": "maintain", "diet_type": "vegan", "activity_level": "moderate",
        "budget": "mid",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": ["peanuts"],
    },
    {
        "persona_id": "P07",
        "age": 50, "gender": "female", "height_cm": 158, "weight_kg": 72,
        "goal": "lose", "diet_type": "veg", "activity_level": "sedentary",
        "budget": "mid",
        "has_pcos": 1, "has_diabetes": 1, "has_thyroid": 1, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P08",
        "age": 19, "gender": "male", "height_cm": 172, "weight_kg": 65,
        "goal": "gain", "diet_type": "non-veg", "activity_level": "active",
        "budget": "low",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    },
    {
        "persona_id": "P09",
        "age": 38, "gender": "male", "height_cm": 170, "weight_kg": 80,
        "goal": "lose", "diet_type": "non-veg", "activity_level": "moderate",
        "budget": "high",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 1,
        "allergies": [],
    },
    {
        "persona_id": "P10",
        "age": 26, "gender": "female", "height_cm": 165, "weight_kg": 60,
        "goal": "maintain", "diet_type": "veg", "activity_level": "active",
        "budget": "mid",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": ["gluten"],
    },
    {
        "persona_id": "P11",
        "age": 42, "gender": "female", "height_cm": 161, "weight_kg": 68,
        "goal": "lose", "diet_type": "veg", "activity_level": "moderate",
        "budget": "low",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 1, "has_bp": 1,
        "allergies": [],
    },
    {
        "persona_id": "P12",
        "age": 30, "gender": "male", "height_cm": 180, "weight_kg": 90,
        "goal": "lose", "diet_type": "non-veg", "activity_level": "moderate",
        "budget": "mid",
        "has_pcos": 0, "has_diabetes": 0, "has_thyroid": 0, "has_bp": 0,
        "allergies": [],
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — HELPER: CALCULATE BMR AND DAILY CALORIE TARGET
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: derived features. BMI and calorie_target are not raw inputs —
# they are calculated from other features. Providing these as separate
# features saves the model from having to learn this arithmetic itself,
# which would require far more training data to figure out implicitly.
# ─────────────────────────────────────────────────────────────────────────────

def calculate_targets(persona):
    w = persona["weight_kg"]
    h = persona["height_cm"]
    a = persona["age"]
    g = persona["gender"]

    if g == "male":
        bmr = 88.36 + (13.4 * w) + (4.8 * h) - (5.7 * a)
    else:
        bmr = 447.6 + (9.2 * w) + (3.1 * h) - (4.3 * a)

    multipliers = {"sedentary": 1.2, "moderate": 1.55, "active": 1.725}
    tdee = bmr * multipliers[persona["activity_level"]]

    goal_adj = {"lose": -300, "maintain": 0, "gain": 300}
    calorie_target = tdee + goal_adj[persona["goal"]]

    bmi = w / ((h / 100) ** 2)
    protein_target = w * 1.6

    return round(bmi, 1), round(calorie_target), round(protein_target)


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — SIMULATE A DAILY CONTEXT FOR A PERSONA
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: correlated feature sampling.
# Real-world features are not independent — bad sleep causes tiredness,
# tiredness causes stress. If you sample each feature independently
# (e.g. randomly assign sleep AND energy with no link), you get impossible
# combinations like "terrible sleep, extremely energetic" which confuse
# the model. We use conditional probabilities to mimic real correlations.
# ─────────────────────────────────────────────────────────────────────────────

SLEEP_DIST       = ["bad", "okay", "good"]
SLEEP_WEIGHTS    = [0.30,  0.40,  0.30]

WEATHER_OPTIONS  = ["hot", "cold", "rainy", "humid"]
WEATHER_WEIGHTS  = [0.40,  0.15,  0.20,  0.25]   # realistic for Indian cities

def simulate_context(persona, calorie_target):
    sleep = random.choices(SLEEP_DIST, weights=SLEEP_WEIGHTS)[0]

    # Energy is correlated with sleep quality
    if sleep == "bad":
        energy = random.choices(["tired","normal","energetic"], weights=[0.70,0.25,0.05])[0]
    elif sleep == "okay":
        energy = random.choices(["tired","normal","energetic"], weights=[0.20,0.60,0.20])[0]
    else:
        energy = random.choices(["tired","normal","energetic"], weights=[0.05,0.30,0.65])[0]

    # Mood is correlated with energy
    if energy == "tired":
        mood = random.choices(["stressed","neutral","calm"], weights=[0.60,0.30,0.10])[0]
    elif energy == "normal":
        mood = random.choices(["stressed","neutral","calm"], weights=[0.20,0.50,0.30])[0]
    else:
        mood = random.choices(["stressed","neutral","calm"], weights=[0.10,0.30,0.60])[0]

    # Heart rate is correlated with stress and activity level
    base_hr = {"sedentary": 75, "moderate": 68, "active": 60}[persona["activity_level"]]
    stress_hr_add = {"stressed": 12, "neutral": 4, "calm": 0}[mood]
    heart_rate = int(np.random.normal(base_hr + stress_hr_add, 5))
    heart_rate = max(50, min(110, heart_rate))   # clip to realistic range

    weather = random.choices(WEATHER_OPTIONS, weights=WEATHER_WEIGHTS)[0]
    temperature_c = {
        "hot":   round(np.random.normal(36, 3), 1),
        "cold":  round(np.random.normal(16, 4), 1),
        "rainy": round(np.random.normal(26, 3), 1),
        "humid": round(np.random.normal(30, 3), 1),
    }[weather]

    # Derive metabolic state from context — same logic your rules_engine.py uses
    # ML concept: this is label consistency. The model will later receive
    # real metabolic_state values from your rules_engine. If you derived the
    # state differently here, the model learns a mapping it will never see
    # in production — a classic training/serving skew problem.
    metabolic_state = derive_metabolic_state(sleep, energy, mood, heart_rate, persona)

    # Calorie adjustment based on state
    cal_adj = {
        "stress_recovery": -150,
        "cortisol_buffer": -100,
        "fat_burn":        -50,
        "normal":           0,
        "muscle_repair":   +100,
        "performance":     +150,
    }[metabolic_state]

    calorie_today = calorie_target + cal_adj
    slot = random.choice(["breakfast", "lunch", "snack", "dinner"])
    slot_target = calorie_today * SLOT_CALORIE_FRACTION[slot]

    return {
        "sleep_quality":   sleep,
        "energy_level":    energy,
        "mood":            mood,
        "heart_rate":      heart_rate,
        "weather_condition": weather,
        "temperature_c":   temperature_c,
        "metabolic_state": metabolic_state,
        "calorie_today":   round(calorie_today),
        "slot":            slot,
        "slot_calorie_target": round(slot_target),
    }


def derive_metabolic_state(sleep, energy, mood, hr, persona):
    # Stress recovery: bad sleep or very tired and stressed
    if sleep == "bad" and energy == "tired":
        return "stress_recovery"

    # Cortisol buffer: stressed even with okay conditions, or high HR
    if mood == "stressed" and hr > 85:
        return "cortisol_buffer"
    if mood == "stressed" and sleep == "bad":
        return "cortisol_buffer"

    # Performance: everything good
    if sleep == "good" and energy == "energetic" and mood != "stressed":
        if persona["activity_level"] in ["active", "moderate"]:
            return "performance"

    # Muscle repair: active person with good sleep
    if persona["activity_level"] == "active" and sleep in ["good", "okay"] and energy != "tired":
        return "muscle_repair"

    # Fat burn: moderate conditions, goal is lose
    if persona["goal"] == "lose" and energy == "normal" and mood != "stressed":
        return "fat_burn"

    return "normal"


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — SCORE A MEAL FOR A USER-CONTEXT COMBINATION
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: target variable construction.
# This is the most important function. The meal_score is your target — the
# number XGBoost learns to predict. It must encode real nutritional logic
# so the model learns meaningful patterns. Think of this as your "oracle"
# that knows the right answer — the model learns to approximate it.
#
# Note: hard constraints (diet mismatch, allergen) return 0.0 immediately.
# These are not gradients — they are absolute. The model will learn these
# as strong patterns because every incompatible (user, meal) pair always
# scores 0.0 with no exceptions.
# ─────────────────────────────────────────────────────────────────────────────

def score_meal(persona, context, meal, protein_target):
    # ── HARD CONSTRAINTS — always 0.0, no exceptions ──────────────────────
    # Diet incompatibility
    diet_compat = {
        "veg":     ["veg"],
        "vegan":   ["vegan"],
        "jain":    ["jain", "veg"],
        "non-veg": ["veg", "non-veg", "vegan", "jain"],
    }
    if meal["diet_type"] not in diet_compat[persona["diet_type"]]:
        return 0.0

    # Allergen check (simplified — peanuts and gluten)
    if "peanuts" in persona["allergies"] and "peanut" in meal["name"].lower():
        return 0.0
    if "gluten" in persona["allergies"] and meal["prep_type"] == "home" and \
       any(w in meal["name"].lower() for w in ["roti", "bread", "toast", "thepla", "upma"]):
        return 0.0

    # Slot compatibility
    if context["slot"] not in meal["suitable_slots"]:
        return 0.05   # very low but not zero — slot mismatch is bad but not impossible

    # ── BASE SCORE — simulating a realistic rating ─────────────────────────
    # ML concept: we simulate what a user WOULD rate this meal given a
    # good vs bad context fit. This becomes the ground truth the model learns.
    fit_score = _calculate_fit(persona, context, meal, protein_target)

    # Simulate consumed + rating from fit_score
    # Good fit meals are consumed more often and rated higher
    if fit_score > 0.75:
        consumed = random.choices([True, False], weights=[0.90, 0.10])[0]
        rating   = random.choices([3, 4, 5], weights=[0.10, 0.35, 0.55])[0]
    elif fit_score > 0.50:
        consumed = random.choices([True, False], weights=[0.75, 0.25])[0]
        rating   = random.choices([2, 3, 4, 5], weights=[0.10, 0.40, 0.35, 0.15])[0]
    elif fit_score > 0.25:
        consumed = random.choices([True, False], weights=[0.50, 0.50])[0]
        rating   = random.choices([1, 2, 3, 4], weights=[0.20, 0.40, 0.30, 0.10])[0]
    else:
        consumed = random.choices([True, False], weights=[0.20, 0.80])[0]
        rating   = random.choices([1, 2, 3], weights=[0.60, 0.30, 0.10])[0]

    # Convert to meal_score (0.0–1.0)
    if not consumed:
        base = 0.1
    else:
        base = {1: 0.2, 2: 0.4, 3: 0.6, 4: 0.8, 5: 1.0}[rating]

    # ── CONTEXT MATCH BONUS / PENALTY ─────────────────────────────────────
    score = base

    # Metabolic state tag match
    if context["metabolic_state"] in meal["tags"]:
        score *= 1.15

    # Recovery impact matches stress/recovery states
    if context["metabolic_state"] in ["stress_recovery", "cortisol_buffer"]:
        if meal["recovery_impact"] == "high":
            score *= 1.10
        elif meal["recovery_impact"] == "low":
            score *= 0.80

    # Inflammation penalty for stressed/condition users
    if context["mood"] == "stressed" and meal["inflammation_score"] > 5:
        score *= 0.75
    if (persona["has_pcos"] or persona["has_diabetes"]) and meal["inflammation_score"] > 5:
        score *= 0.65

    # Condition-specific penalties
    if persona["has_diabetes"] and meal["high_carb"]:
        score *= 0.50
    if persona["has_bp"] and meal["high_sodium"]:
        score *= 0.55

    # Calorie fit for slot
    calorie_gap = abs(meal["calories"] - context["slot_calorie_target"])
    if calorie_gap < 50:
        score *= 1.10
    elif calorie_gap > 200:
        score *= 0.75

    # Weather fit
    if context["weather_condition"] in ["hot", "humid"] and meal["inflammation_score"] > 5:
        score *= 0.80
    if context["weather_condition"] == "rainy" and meal["prep_type"] == "home":
        score *= 1.05   # prefer home cooked on rainy days

    # Protein adequacy for muscle repair
    protein_ratio = meal["protein_g"] / persona["weight_kg"]
    if context["metabolic_state"] == "muscle_repair" and protein_ratio < 0.3:
        score *= 0.70

    # Goal alignment
    if persona["goal"] == "lose" and meal["calories"] > context["slot_calorie_target"] * 1.3:
        score *= 0.80
    if persona["goal"] == "gain" and meal["calories"] < context["slot_calorie_target"] * 0.7:
        score *= 0.75

    # ── CONTROLLED NOISE ──────────────────────────────────────────────────
    # ML concept: noise injection. Real users are inconsistent.
    # Without noise, your model perfectly memorises the scoring rules
    # and fails to generalise to real messy human behavior.
    # ±0.12 noise is enough to simulate realistic inconsistency
    # without destroying the signal.
    noise = np.random.uniform(-0.12, 0.12)
    score = score + noise

    # Clip to valid range — ML concept: bounded targets are easier to learn
    return round(float(np.clip(score, 0.0, 1.0)), 4)


def _calculate_fit(persona, context, meal, protein_target):
    """Internal helper — pure fit score before simulating feedback."""
    score = 0.5   # neutral starting point

    if context["metabolic_state"] in meal["tags"]:
        score += 0.20
    if meal["recovery_impact"] == "high":
        score += 0.10
    if meal["inflammation_score"] <= 3:
        score += 0.10
    if not meal["high_carb"] and (persona["has_diabetes"] or persona["has_pcos"]):
        score += 0.10
    if not meal["high_sodium"] and persona["has_bp"]:
        score += 0.10
    if persona["goal"] == "gain" and meal["protein_g"] > 25:
        score += 0.10
    if persona["goal"] == "lose" and meal["calories"] < context["slot_calorie_target"]:
        score += 0.05

    return min(score, 1.0)


# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — ENCODE CATEGORICAL FEATURES
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: feature encoding.
# XGBoost (and all ML models) work on numbers, not strings.
# "male"/"female"/"other" must become 0/1/2. This mapping must be
# IDENTICAL between training and inference — if you change these numbers
# later, the model's predictions break completely. Save these mappings.
# ─────────────────────────────────────────────────────────────────────────────

ENCODINGS = {
    "gender":           {"male": 0, "female": 1, "other": 2},
    "goal":             {"lose": 0, "maintain": 1, "gain": 2},
    "diet_type":        {"veg": 0, "non-veg": 1, "vegan": 2, "jain": 3},
    "activity_level":   {"sedentary": 0, "moderate": 1, "active": 2},
    "budget":           {"low": 0, "mid": 1, "high": 2},
    "sleep_quality":    {"bad": 0, "okay": 1, "good": 2},
    "energy_level":     {"tired": 0, "normal": 1, "energetic": 2},
    "mood":             {"stressed": 0, "neutral": 1, "calm": 2},
    "metabolic_state":  {
        "stress_recovery": 0, "cortisol_buffer": 1, "fat_burn": 2,
        "normal": 3, "muscle_repair": 4, "performance": 5
    },
    "weather_condition":{"hot": 0, "cold": 1, "rainy": 2, "humid": 3},
    "slot":             {"breakfast": 0, "lunch": 1, "snack": 2, "dinner": 3},
    "recovery_impact":  {"low": 0, "medium": 1, "high": 2},
    "prep_type":        {"home": 0, "restaurant": 1, "cloud_kitchen": 2},
    "meal_diet_type":   {"veg": 0, "non-veg": 1, "vegan": 2, "jain": 3},
    "meal_budget":      {"low": 0, "mid": 1, "high": 2},
}


def encode_row(persona, context, meal, bmi, calorie_target, protein_target):
    """Build one encoded feature row as a dict."""
    protein_ratio = meal["protein_g"] / persona["weight_kg"]
    calorie_gap   = abs(meal["calories"] - context["slot_calorie_target"])

    return {
        # User features
        "age":                  persona["age"],
        "bmi":                  bmi,
        "gender":               ENCODINGS["gender"][persona["gender"]],
        "goal":                 ENCODINGS["goal"][persona["goal"]],
        "diet_type":            ENCODINGS["diet_type"][persona["diet_type"]],
        "activity_level":       ENCODINGS["activity_level"][persona["activity_level"]],
        "budget":               ENCODINGS["budget"][persona["budget"]],
        "has_pcos":             persona["has_pcos"],
        "has_diabetes":         persona["has_diabetes"],
        "has_thyroid":          persona["has_thyroid"],
        "has_bp":               persona["has_bp"],

        # Daily context features
        "heart_rate":           context["heart_rate"],
        "sleep_quality":        ENCODINGS["sleep_quality"][context["sleep_quality"]],
        "energy_level":         ENCODINGS["energy_level"][context["energy_level"]],
        "mood":                 ENCODINGS["mood"][context["mood"]],
        "metabolic_state":      ENCODINGS["metabolic_state"][context["metabolic_state"]],
        "weather_condition":    ENCODINGS["weather_condition"][context["weather_condition"]],
        "temperature_c":        context["temperature_c"],
        "slot":                 ENCODINGS["slot"][context["slot"]],
        "calorie_today":        context["calorie_today"],
        "slot_calorie_target":  context["slot_calorie_target"],

        # Meal features
        "meal_calories":        meal["calories"],
        "meal_protein_g":       meal["protein_g"],
        "meal_carbs_g":         meal["carbs_g"],
        "meal_fat_g":           meal["fat_g"],
        "meal_inflammation_score": meal["inflammation_score"],
        "meal_recovery_impact": ENCODINGS["recovery_impact"][meal["recovery_impact"]],
        "meal_budget":          ENCODINGS["meal_budget"][meal["budget"]],
        "meal_prep_type":       ENCODINGS["prep_type"][meal["prep_type"]],
        "meal_diet_type":       ENCODINGS["meal_diet_type"][meal["diet_type"]],

        # Derived / interaction features
        # ML concept: interaction features. Instead of letting the model
        # figure out that (meal_protein_g / weight_kg) matters, we give it
        # this ratio directly. This is called feature engineering — encoding
        # domain knowledge as a computed column. It significantly reduces
        # the amount of data needed to learn this relationship.
        "calorie_gap":          round(calorie_gap, 1),
        "protein_ratio":        round(protein_ratio, 3),
        "metabolic_tag_match":  int(context["metabolic_state"] in meal["tags"]),

        # Feedback history features — zero for all synthetic rows.
        # When real data is collected, these become the most powerful features.
        # ML concept: cold start. New users have no history so these are 0.
        # The model learns to rely on context features when history is absent,
        # and shifts to history features when they become available.
        "user_avg_rating_this_meal":     0.0,
        "user_consumed_before":          0,
        "user_avg_rating_similar_meals": 0.0,
    }


# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — GENERATE THE FULL DATASET
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: dataset construction loop.
# For each persona we generate many (context, meal, score) rows.
# Having multiple rows per persona is what allows the model to learn
# within-persona variation — the same user scores meals differently
# depending on their daily context. This is the personalisation signal.
# ─────────────────────────────────────────────────────────────────────────────

def generate_dataset(target_rows=ROWS_TARGET):
    rows = []
    rows_per_persona = target_rows // len(PERSONAS)

    print(f"Generating ~{target_rows} rows across {len(PERSONAS)} personas...")
    print(f"  {rows_per_persona} rows per persona\n")

    for persona in PERSONAS:
        bmi, calorie_target, protein_target = calculate_targets(persona)
        persona_rows = 0

        while persona_rows < rows_per_persona:
            context = simulate_context(persona, calorie_target)

            # Pick 3–5 meals to evaluate in this context
            # Sample from meals compatible with slot
            slot_meals = [m for m in MEALS if context["slot"] in m["suitable_slots"]]
            if not slot_meals:
                slot_meals = MEALS  # fallback

            num_to_score = min(random.randint(3, 5), len(slot_meals))
            sampled_meals = random.sample(slot_meals, num_to_score)

            for meal in sampled_meals:
                score = score_meal(persona, context, meal, protein_target)
                row = encode_row(persona, context, meal, bmi, calorie_target, protein_target)
                row["meal_score"] = score
                row["persona_id"] = persona["persona_id"]  # keep for debugging, drop before training
                row["meal_id"]    = meal["meal_id"]         # keep for debugging, drop before training
                rows.append(row)
                persona_rows += 1
                if persona_rows >= rows_per_persona:
                    break

        print(f"  Persona {persona['persona_id']} ({persona['diet_type']}, "
              f"{persona['goal']}, {persona['activity_level']}) → {persona_rows} rows")

    df = pd.DataFrame(rows)
    print(f"\nTotal rows generated: {len(df)}")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — VALIDATE THE DATASET
# ─────────────────────────────────────────────────────────────────────────────
# ML concept: data validation before training.
# A bad dataset trains a bad model — and you often won't know until
# the model makes nonsense predictions in production. These checks
# catch problems early. This is called "unit testing your data."
# ─────────────────────────────────────────────────────────────────────────────

def validate_dataset(df):
    print("\n── VALIDATION ──────────────────────────────────────────")
    passed = True

    # Check 1: score distribution
    mean_score = df["meal_score"].mean()
    print(f"Mean meal_score:  {mean_score:.3f}  (expect 0.3–0.7)")
    if not (0.2 < mean_score < 0.8):
        print("  WARN: Mean score is outside expected range — check scoring logic")
        passed = False

    # Check 2: no all-1.0 or all-0.0
    pct_zeros = (df["meal_score"] == 0.0).mean()
    pct_ones  = (df["meal_score"] == 1.0).mean()
    print(f"Zero scores:      {pct_zeros:.1%}  (expect < 20%)")
    print(f"Perfect scores:   {pct_ones:.1%}  (expect < 5%)")

    # Check 3: veg users never see high-scoring non-veg meals
    veg_users  = df[df["diet_type"] == ENCODINGS["diet_type"]["veg"]]
    nonveg_meals = veg_users[veg_users["meal_diet_type"] == ENCODINGS["meal_diet_type"]["non-veg"]]
    bad_scores = (nonveg_meals["meal_score"] > 0.2).sum()
    print(f"Veg user + non-veg meal scoring >0.2: {bad_scores}  (expect 0)")
    if bad_scores > 0:
        print("  ERROR: Diet constraint violated!")
        passed = False

    # Check 4: each metabolic state is represented
    state_counts = df["metabolic_state"].value_counts()
    print(f"\nMetabolic state distribution:")
    for state_name, state_code in ENCODINGS["metabolic_state"].items():
        count = state_counts.get(state_code, 0)
        pct   = count / len(df) * 100
        flag  = "WARN" if pct < 5 else "ok"
        print(f"  {state_name:<20} {count:>5} rows  ({pct:.1f}%)  [{flag}]")

    # Check 5: score range
    if df["meal_score"].min() < 0 or df["meal_score"].max() > 1:
        print("ERROR: Scores outside [0, 1] range!")
        passed = False

    print(f"\nScore percentiles:")
    for p in [10, 25, 50, 75, 90]:
        print(f"  p{p}: {df['meal_score'].quantile(p/100):.3f}")

    print(f"\nValidation: {'PASSED' if passed else 'FAILED — fix issues above'}")
    print("────────────────────────────────────────────────────────\n")
    return passed


# ─────────────────────────────────────────────────────────────────────────────
# MAIN — RUN EVERYTHING
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    df = generate_dataset(ROWS_TARGET)

    valid = validate_dataset(df)

    if valid:
        # Save full version (with persona_id and meal_id for debugging)
        df.to_csv("training_data_debug.csv", index=False)

        # Save clean version for model training (drop debug columns)
        train_df = df.drop(columns=["persona_id", "meal_id"])
        train_df.to_csv(OUTPUT_PATH, index=False)

        print(f"Saved training data → {OUTPUT_PATH}")
        print(f"Saved debug data    → training_data_debug.csv")
        print(f"\nColumns ({len(train_df.columns)}): {list(train_df.columns)}")
        print(f"Rows: {len(train_df)}")
    else:
        print("Dataset failed validation — do not proceed to training until fixed.")
