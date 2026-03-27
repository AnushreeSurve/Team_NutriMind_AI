// ─────────────────────────────────────────────────────────────
// lib/models/meal_model.dart
// ─────────────────────────────────────────────────────────────

class Meal {
  final String mealId;
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int inflammationScore;
  final String recoveryImpact;
  final String prepType;
  final String imageUrl;
  final String whyRecommended;
  final double predictedScore;

  Meal({
    required this.mealId,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.inflammationScore,
    required this.recoveryImpact,
    required this.prepType,
    required this.imageUrl,
    required this.whyRecommended,
    required this.predictedScore,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        mealId:            json['meal_id'] ?? '',
        name:              json['name'] ?? '',
        calories:          (json['calories'] ?? 0) as int,
        proteinG:          (json['protein_g'] ?? 0).toDouble(),
        carbsG:            (json['carbs_g'] ?? 0).toDouble(),
        fatG:              (json['fat_g'] ?? 0).toDouble(),
        inflammationScore: (json['inflammation_score'] ?? 5) as int,
        recoveryImpact:    json['recovery_impact'] ?? 'medium',
        prepType:          json['prep_type'] ?? 'home',
        imageUrl:          json['image_url'] ?? '',
        whyRecommended:    json['why_recommended'] ?? '',
        predictedScore:    (json['predicted_score'] ?? 0.0).toDouble(),
      );
}

class MealSlot {
  final String slot;
  final String scheduledTime;
  final List<Meal> options;

  MealSlot({
    required this.slot,
    required this.scheduledTime,
    required this.options,
  });

  factory MealSlot.fromJson(Map<String, dynamic> json) => MealSlot(
        slot:          json['slot'] ?? '',
        scheduledTime: json['scheduled_time'] ?? '',
        options: (json['options'] as List? ?? [])
            .map((m) => Meal.fromJson(m))
            .toList(),
      );
}

class MealLog {
  final String date;
  final String slot;
  final String mealName;
  final bool consumed;
  final int? rating;
  final String metabolicStateThatDay;

  MealLog({
    required this.date,
    required this.slot,
    required this.mealName,
    required this.consumed,
    this.rating,
    required this.metabolicStateThatDay,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
        date:                  json['date'] ?? '',
        slot:                  json['slot'] ?? '',
        mealName:              json['meal_name'] ?? '',
        consumed:              json['consumed'] ?? false,
        rating:                json['rating'],
        metabolicStateThatDay: json['metabolic_state_that_day'] ?? '',
      );
}
