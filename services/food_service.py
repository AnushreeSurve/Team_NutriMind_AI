# ============================================================
#  services/food_service.py  —  Dummy food analysis
# ============================================================

# Simple lookup table (replace with a real food API / DB later)
FOOD_DB = {
    "banana":        {"calories": 89,  "protein_g": 1.1,  "carbs_g": 23.0, "fat_g": 0.3,  "vitamins": ["B6", "C"],          "inflammation_score": 2},
    "chicken breast":{"calories": 165, "protein_g": 31.0, "carbs_g": 0.0,  "fat_g": 3.6,  "vitamins": ["B12", "B6"],        "inflammation_score": 3},
    "oats":          {"calories": 68,  "protein_g": 2.4,  "carbs_g": 12.0, "fat_g": 1.4,  "vitamins": ["B1", "Iron"],       "inflammation_score": 1},
    "rice":          {"calories": 130, "protein_g": 2.7,  "carbs_g": 28.0, "fat_g": 0.3,  "vitamins": ["B1"],               "inflammation_score": 2},
    "egg":           {"calories": 78,  "protein_g": 6.0,  "carbs_g": 0.6,  "fat_g": 5.0,  "vitamins": ["D", "B12"],        "inflammation_score": 2},
    "dal":           {"calories": 116, "protein_g": 9.0,  "carbs_g": 20.0, "fat_g": 0.4,  "vitamins": ["Folate", "Iron"],  "inflammation_score": 1},
    "paneer":        {"calories": 265, "protein_g": 18.0, "carbs_g": 1.2,  "fat_g": 20.0, "vitamins": ["Calcium", "B12"],  "inflammation_score": 3},
    "apple":         {"calories": 52,  "protein_g": 0.3,  "carbs_g": 14.0, "fat_g": 0.2,  "vitamins": ["C", "K"],          "inflammation_score": 1},
    "roti":          {"calories": 71,  "protein_g": 2.7,  "carbs_g": 15.0, "fat_g": 0.4,  "vitamins": ["Iron", "B1"],      "inflammation_score": 2},
    "idli":          {"calories": 39,  "protein_g": 2.0,  "carbs_g": 8.0,  "fat_g": 0.2,  "vitamins": ["B1", "Iron"],      "inflammation_score": 1},
}

DEFAULT_FOOD = {"calories": 200, "protein_g": 5.0, "carbs_g": 30.0, "fat_g": 5.0, "vitamins": ["Unknown"], "inflammation_score": 5}


def analyze_food(food_name: str, quantity_g: float) -> dict:
    key  = food_name.lower().strip()
    data = FOOD_DB.get(key, DEFAULT_FOOD)
    ratio = quantity_g / 100.0   # all values are per 100g

    return {
        "food":              food_name,
        "quantity_g":        quantity_g,
        "calories":          round(data["calories"]  * ratio, 1),
        "protein_g":         round(data["protein_g"] * ratio, 1),
        "carbs_g":           round(data["carbs_g"]   * ratio, 1),
        "fat_g":             round(data["fat_g"]     * ratio, 1),
        "vitamins":          data["vitamins"],
        "inflammation_score": data["inflammation_score"],
        "note":              "Values are approximate per-serving estimates." if key not in FOOD_DB else "Values from NutriSync food library.",
    }
