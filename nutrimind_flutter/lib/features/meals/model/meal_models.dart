/// Meals feature models.
library;

class MealItem {
  final String id;
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String slot;
  final String dietType;
  final List<String> tags;
  final String description;

  const MealItem({
    required this.id,
    required this.name,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.slot = 'lunch',
    this.dietType = 'veg',
    this.tags = const [],
    this.description = '',
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['id']?.toString() ?? json['food_name'] ?? '',
        name: json['food_name'] ?? json['name'] ?? '',
        calories: json['calories'] ?? 0,
        proteinG: (json['protein_g'] ?? 0).toDouble(),
        carbsG: (json['carbs_g'] ?? 0).toDouble(),
        fatG: (json['fat_g'] ?? 0).toDouble(),
        slot: json['slot'] ?? 'lunch',
        dietType: json['diet_type'] ?? 'veg',
        tags: List<String>.from(json['tags'] ?? []),
        description: json['description'] ?? '',
      );

  static List<MealItem> get mockList => [
        const MealItem(
          id: '1',
          name: 'Paneer Tikka Bowl',
          calories: 420,
          proteinG: 28,
          carbsG: 35,
          fatG: 18,
          slot: 'lunch',
          dietType: 'veg',
          tags: ['High Protein', 'Low Carb'],
          description: 'Grilled paneer with spices, served with quinoa and fresh veggies.',
        ),
        const MealItem(
          id: '2',
          name: 'Oats Banana Smoothie',
          calories: 280,
          proteinG: 12,
          carbsG: 45,
          fatG: 6,
          slot: 'breakfast',
          dietType: 'veg',
          tags: ['Fiber Rich', 'Quick'],
          description: 'Creamy oats blended with banana, honey, and almond milk.',
        ),
        const MealItem(
          id: '3',
          name: 'Grilled Chicken Salad',
          calories: 350,
          proteinG: 40,
          carbsG: 12,
          fatG: 14,
          slot: 'dinner',
          dietType: 'non-veg',
          tags: ['Low Fat', 'High Protein', 'Keto Friendly'],
          description: 'Grilled chicken breast with mixed greens, cherry tomatoes, and balsamic.',
        ),
        const MealItem(
          id: '4',
          name: 'Mixed Fruit Bowl',
          calories: 180,
          proteinG: 3,
          carbsG: 42,
          fatG: 1,
          slot: 'snack',
          dietType: 'veg',
          tags: ['Vitamins', 'Natural Sugar'],
          description: 'Seasonal fruits with a drizzle of honey and chia seeds.',
        ),
        const MealItem(
          id: '5',
          name: 'Dal Tadka with Rice',
          calories: 480,
          proteinG: 18,
          carbsG: 68,
          fatG: 12,
          slot: 'lunch',
          dietType: 'veg',
          tags: ['Comfort Food', 'Protein'],
          description: 'Classic yellow dal tempered with ghee, garlic, and cumin.',
        ),
        const MealItem(
          id: '6',
          name: 'Egg Bhurji Wrap',
          calories: 320,
          proteinG: 22,
          carbsG: 28,
          fatG: 14,
          slot: 'breakfast',
          dietType: 'eggetarian',
          tags: ['Quick', 'High Protein'],
          description: 'Spiced scrambled eggs wrapped in a whole wheat roti.',
        ),
      ];
}

class FoodAnalysis {
  final String foodName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const FoodAnalysis({
    required this.foodName,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) => FoodAnalysis(
        foodName: json['food_name'] ?? '',
        calories: json['calories'] ?? 0,
        proteinG: (json['protein_g'] ?? 0).toDouble(),
        carbsG: (json['carbs_g'] ?? 0).toDouble(),
        fatG: (json['fat_g'] ?? 0).toDouble(),
      );
}
