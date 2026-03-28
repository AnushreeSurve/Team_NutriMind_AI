// lib/providers/meal_provider.dart

import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/meal_model.dart';

class MealProvider extends ChangeNotifier {
  List<MealSlot> _mealSlots = [];
  bool _isLoading = false;
  String? _error;
  String _metabolicState = 'normal';
  String _weatherCondition = 'hot';

  List<MealSlot> get mealSlots  => _mealSlots;
  bool get isLoading            => _isLoading;
  String? get error             => _error;
  String get metabolicState     => _metabolicState;
  String get weatherCondition   => _weatherCondition;

  void reset() {
    _mealSlots        = [];
    _isLoading        = false;
    _error            = null;
    _metabolicState   = 'normal';
    _weatherCondition = 'hot';
    notifyListeners();
  }

  Future<void> loadFullDayMeals(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.getFullDayRecommendations(email);

      final rawMeals = res['meals']
          ?? res['recommendations']
          ?? res['meal_slots']
          ?? res['data'];

      if (rawMeals != null && rawMeals is List) {
        _metabolicState   = res['metabolic_state'] ?? 'normal';
        _weatherCondition = res['weather_condition'] ?? 'hot';
        _mealSlots = rawMeals
            .map((s) => MealSlot.fromJson(s as Map<String, dynamic>))
            .toList();
        _error = null;
      } else if (res['status'] == 'success') {
        _mealSlots = [];
        _error = null;
      } else {
        final detail = res['detail'];
        if (detail is List && detail.isNotEmpty) {
          _error = detail[0]['msg']?.toString() ?? 'Failed to load meals';
        } else {
          _error = detail?.toString()
              ?? res['error']?.toString()
              ?? res['message']?.toString()
              ?? 'Failed to load meals';
        }
      }
    } catch (e) {
      _error = 'Could not load meals: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Used by old code — keep for compatibility
  Future<bool> logMeal({
    required String userId,
    required String mealId,
    required String slot,
    required String date,
    required bool consumed,
    int? rating,
  }) async {
    try {
      final res = await ApiService.logMeal(
        userId:   userId,
        mealId:   mealId,
        slot:     slot,
        date:     date,
        consumed: consumed,
        rating:   rating,
      );
      return res['status'] == 'success' || res['message'] != null;
    } catch (_) {
      return false;
    }
  }

  // Used by meal_card.dart star rating — routes through ApiService
  Future<bool> logMealWithRating({
    required String userId,
    required String mealId,
    required String slot,
    required String date,
    required int    rating,
  }) async {
    try {
      final res = await ApiService.logMeal(
        userId:   userId,
        mealId:   mealId,
        slot:     slot,
        date:     date,
        consumed: true,
        rating:   rating,
      );
      return res['status'] == 'success' || res['logged'] == true;
    } catch (e) {
      debugPrint('logMealWithRating error: $e');
      return false;
    }
  }
} 