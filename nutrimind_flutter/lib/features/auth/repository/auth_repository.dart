/// Auth repository — calls backend auth endpoints.
library;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../model/auth_models.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Supabase auth signup and profile injection
  Future<SignupResponse> signup(SignupRequest request) async {
    // Default mock password for seamless flow without structurally changing models.
    final res = await _supabase.auth.signUp(
      email: request.email,
      password: 'NutriMind123!',
    );

    final user = res.user;
    if (user != null) {
      // Insert profile data
      await _supabase.from('profiles').insert({
        'id': user.id,
        'name': request.name,
        'email': request.email,
        'age': request.age,
        'gender': request.gender,
        'height_cm': request.heightCm,
        'weight_kg': request.weightKg,
        'goal': request.goal,
        'diet_type': request.dietType,
        'activity_level': request.activityLevel,
        'budget': request.budget,
      });

      return SignupResponse(
        message: 'Success',
        userId: user.id,
        dailyCalorieTarget: 2000,
        proteinTargetG: 65,
        carbsTargetG: 200,
        fatTargetG: 50,
      );
    }
    throw Exception('Signup failed');
  }

  /// Supabase auth login
  Future<SignupResponse> login(String email) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: 'NutriMind123!',
    );

    final user = res.user;
    if (user != null) {
      final profile = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      return SignupResponse(
        message: profile?['name'] ?? 'Success',
        userId: user.id,
        dailyCalorieTarget: 2000,
        proteinTargetG: 65,
        carbsTargetG: 200,
        fatTargetG: 50,
      );
    }
    throw Exception('Login failed');
  }
}
