/// Home repository — fetches daily summary and recommendations.
library;

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/constants/app_constants.dart';
import '../model/home_models.dart';

class HomeRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: ApiConstants.geminiApiKey,
  );

  /// Fetch daily calories consumed directly from Supabase meal_logs table
  Future<DailySummary> getDailySummary(String email) async {
    try {
      final res = await _supabase
          .from('meal_logs')
          .select()
          .eq('email', email);

      int cals = 0;
      double prot = 0, carbs = 0, fats = 0;
      for (final row in res) {
         cals += (row['calories'] ?? 0) as int;
         prot += (row['protein_g'] as num?)?.toDouble() ?? 0;
         carbs += (row['carbs_g'] as num?)?.toDouble() ?? 0;
         fats += (row['fat_g'] as num?)?.toDouble() ?? 0;
      }
      return DailySummary(
         caloriesConsumed: cals,
         calorieTarget: 2000,
         proteinG: prot,
         carbsG: carbs,
         fatG: fats,
      );
    } catch (_) {
      return DailySummary.mock;
    }
  }

  /// Use Gemini API to generate a personalized full day recommendation
  Future<FullDayResponse> getFullDayRecommendations(String email) async {
    try {
      final content = [Content.text('Generate 4 healthy Indian meal recommendations (breakfast, lunch, snack, dinner). Return strictly a JSON array of objects with keys: name (string), calories (int), slot (string, one of breakfast/lunch/snack/dinner), diet_type (string), tags (list of strings).')];
      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '[]';
      final List<dynamic> items = jsonDecode(jsonStr);
      
      final List<MealRecommendation> meals = items.map((e) => MealRecommendation.fromJson({
         'food_name': e['name'],
         'calories': e['calories'],
         'slot': e['slot'],
         'diet_type': e['diet_type'] ?? 'veg',
         'tags': e['tags'] ?? [],
      })).toList();

      return FullDayResponse(
        weatherCondition: 'normal',
        temperatureC: 25.0,
        city: 'Pune',
        meals: meals.isEmpty ? MealRecommendation.mockList : meals,
      );
    } catch (_) {
      return FullDayResponse(meals: MealRecommendation.mockList);
    }
  }
}
