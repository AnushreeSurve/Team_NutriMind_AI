/// Home feature models for dashboard data.
library;

class DailySummary {
  final int caloriesConsumed;
  final int calorieTarget;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const DailySummary({
    this.caloriesConsumed = 0,
    this.calorieTarget = 2000,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        caloriesConsumed: json['total_calories'] ?? 0,
        calorieTarget: json['calorie_target'] ?? 2000,
        proteinG: (json['total_protein_g'] ?? 0).toDouble(),
        carbsG: (json['total_carbs_g'] ?? 0).toDouble(),
        fatG: (json['total_fat_g'] ?? 0).toDouble(),
      );

  /// Mock data for initial display.
  static DailySummary get mock => const DailySummary(
        caloriesConsumed: 1250,
        calorieTarget: 2000,
        proteinG: 65,
        carbsG: 140,
        fatG: 45,
      );
}

class MealRecommendation {
  final String name;
  final int calories;
  final String slot;
  final String dietType;
  final String imageUrl;
  final List<String> tags;

  const MealRecommendation({
    required this.name,
    required this.calories,
    required this.slot,
    this.dietType = 'veg',
    this.imageUrl = '',
    this.tags = const [],
  });

  factory MealRecommendation.fromJson(Map<String, dynamic> json) =>
      MealRecommendation(
        name: json['food_name'] ?? json['name'] ?? '',
        calories: json['calories'] ?? 0,
        slot: json['slot'] ?? '',
        dietType: json['diet_type'] ?? 'veg',
        tags: List<String>.from(json['tags'] ?? []),
      );

  static List<MealRecommendation> get mockList => [
        const MealRecommendation(
          name: 'Paneer Tikka Bowl',
          calories: 420,
          slot: 'lunch',
          dietType: 'veg',
          tags: ['High Protein', 'Low Carb'],
        ),
        const MealRecommendation(
          name: 'Oats Smoothie',
          calories: 280,
          slot: 'breakfast',
          dietType: 'veg',
          tags: ['Fiber Rich', 'Quick'],
        ),
        const MealRecommendation(
          name: 'Grilled Chicken Salad',
          calories: 350,
          slot: 'dinner',
          dietType: 'non-veg',
          tags: ['Low Fat', 'High Protein'],
        ),
        const MealRecommendation(
          name: 'Mixed Fruit Bowl',
          calories: 180,
          slot: 'snack',
          dietType: 'veg',
          tags: ['Vitamins', 'Natural Sugar'],
        ),
      ];
}

class FullDayResponse {
  final String weatherCondition;
  final double temperatureC;
  final String city;
  final List<MealRecommendation> meals;

  const FullDayResponse({
    this.weatherCondition = 'normal',
    this.temperatureC = 25.0,
    this.city = 'Pune',
    this.meals = const [],
  });
}
