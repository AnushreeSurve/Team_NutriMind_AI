// ─────────────────────────────────────────────────────────────
// lib/api/api.dart
// ALL API calls live here. Change BASE_URL in one place only.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const String BASE_URL = 'https://teamnutrimindai-production.up.railway.app';

const String GEMINI_API_KEY = 'AIzaSyDm4Rfj1XJWCmWRgYg5XF363h_4XVNIYsk';
const String GEMINI_URL =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

class ApiService {
  static Future<String?> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  // Safely parse any backend response — won't crash on HTML error pages
  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded, 'status': 'success'};
    } catch (_) {
      return {
        'detail': 'Server error (${res.statusCode}): ${res.body.substring(0, res.body.length.clamp(0, 200))}'
      };
    }
  }

  // ── AUTH ───────────────────────────────────────────────────

  // Full signup — called at end of onboarding with all fields
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String dietType,
    required String activityLevel,
    required String budget,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/auth/signup'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal': goal,
        'diet_type': dietType,
        'activity_level': activityLevel,
        'budget': budget,
      }),
    );
    return _parse(res);
  }

  // Login — password is hardcoded in backend as email+"_nutrisync"
  static Future<Map<String, dynamic>> login({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/auth/login'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': '${email}_nutrisync',
      }),
    );
    return _parse(res);
  }

  // ── ONBOARDING ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveOnboarding(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/user/onboarding'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/user/profile?user_id=$userId'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── CHECK-IN ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> morningCheckin(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/checkin/morning'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getCheckinStatus(
      String userId, String date) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/checkin/today?user_id=$userId&date=$date'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── MEALS ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTodayMeals({
    required String userId,
    required String date,
    String city = 'Pune',
  }) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/meals/today?user_id=$userId&date=$date&city=$city'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMealDetail(String mealId) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/meals/single?meal_id=$mealId'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> compareMeals(
      String mealId1, String mealId2) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/meals/compare?meal_id_1=$mealId1&meal_id_2=$mealId2'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getRecommendations({
    required String email,
    required String slot,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/recommend/meal-recommendation'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'slot': slot}),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getFullDayRecommendations(
      String email) async {
    // Send Flutter's local IST date — avoids UTC vs IST mismatch on Railway
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await http.get(
      Uri.parse('$BASE_URL/recommend/full-day?email=$email&date=$today'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── MEAL FEEDBACK ──────────────────────────────────────────

  static Future<Map<String, dynamic>> logMeal({
    required String userId,
    required String mealId,
    required String slot,
    required String date,
    required bool consumed,
    int? rating,
  }) async {
    final body = {
      'user_id': userId,
      'meal_id': mealId,
      'slot': slot,
      'date': date,
      'consumed': consumed,
      if (rating != null) 'rating': rating,
    };
    final res = await http.post(
      Uri.parse('$BASE_URL/meals/log'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getMealHistory(
      String userId, int limit) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/meals/history?user_id=$userId&limit=$limit'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── DASHBOARD ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard(
      String userId, String date) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/dashboard?user_id=$userId&date=$date'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── ALERTS ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAlerts(String userId) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/alerts?user_id=$userId'),
      headers: await _headers(),
    );
    return _parse(res);
  }

  // ── CHATBOT (GEMINI) ───────────────────────────────────────

  static Future<String> askGemini(String message,
      {String? metabolicState, String? dietType}) async {
    final systemContext = '''
You are NutriSync AI, a personal nutrition assistant. 
The user's metabolic state today is: ${metabolicState ?? 'normal'}.
Their diet type is: ${dietType ?? 'veg'}.
Answer questions about nutrition, meals, health, and wellness concisely.
Keep responses under 150 words. Be friendly and practical.
''';
    final res = await http.post(
      Uri.parse('$GEMINI_URL?key=$GEMINI_API_KEY'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$systemContext\n\nUser: $message'}
            ]
          }
        ]
      }),
    );
    final data = jsonDecode(res.body);
    try {
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (_) {
      return 'Sorry, I could not process that. Please try again.';
    }
  }

  // ── HEALTH / PREDICTION ────────────────────────────────────

  static Future<Map<String, dynamic>> getMetabolicState({
    required String email,
    required double sleepHours,
    required int steps,
    required int calories,
    required int heartRate,
    required String mood,
  }) async {
    final res = await http.post(
      Uri.parse('$BASE_URL/ml/predict'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'sleep_hours': sleepHours,
        'steps': steps,
        'calories': calories,
        'heart_rate': heartRate,
        'mood': mood,
      }),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> getHealthPlan(
      String email, String condition) async {
    final res = await http.get(
      Uri.parse('$BASE_URL/health/plan?email=$email&condition=$condition'),
      headers: await _headers(),
    );
    return _parse(res);
  }
}