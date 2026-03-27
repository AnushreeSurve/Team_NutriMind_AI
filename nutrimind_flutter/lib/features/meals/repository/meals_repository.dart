/// Meals repository — calls backend meal/recommendation/food endpoints.
library;

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/constants/app_constants.dart';
import '../model/meal_models.dart';

class MealsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: ApiConstants.geminiApiKey,
  );

  /// Gemini AI Recommendation
  Future<List<MealItem>> getMealRecommendations(String email, String slot) async {
    try {
      final content = [Content.text('Generate 3 healthy Indian meal recommendations for $slot. Return strictly a JSON array of objects with keys: name (string), calories (int), protein_g (double), carbs_g (double), fat_g (double), slot (string), diet_type (string), tags (list of strings).')];
      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '[]';
      final List<dynamic> items = jsonDecode(jsonStr);
      
      return items.map((e) => MealItem.fromJson({
         'id': DateTime.now().millisecondsSinceEpoch.toString(),
         'food_name': e['name'],
         'calories': e['calories'],
         'protein_g': e['protein_g'],
         'carbs_g': e['carbs_g'],
         'fat_g': e['fat_g'],
         'slot': e['slot'] ?? slot,
         'diet_type': e['diet_type'] ?? 'veg',
         'tags': e['tags'] ?? [],
      })).toList();
    } catch (_) {
      return MealItem.mockList;
    }
  }

  /// Gemini AI Food Analysis
  Future<FoodAnalysis> analyzeFood(String foodName, double quantityG) async {
    try {
        final content = [Content.text('Analyze nutritional value for $quantityG grams of $foodName. Return strictly a JSON object with keys: food_name (string), calories (int), protein_g (double), carbs_g (double), fat_g (double).')];
        final response = await _model.generateContent(content);
        final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
        return FoodAnalysis.fromJson(jsonDecode(jsonStr));
    } catch (_) {
        return FoodAnalysis(foodName: foodName, calories: 150);
    }
  }

  /// Supabase Insert
  Future<Map<String, dynamic>> addMeal({
    required String email,
    required String mealName,
    required int calories,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    String slot = 'snack',
  }) async {
    try {
      final res = await _supabase.from('meal_logs').insert({
        'email': email,
        'meal_name': mealName,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'slot': slot,
      }).select();
      
      if (res.isNotEmpty) return res.first;
    } catch (_) {}
    return {};
  }
}
