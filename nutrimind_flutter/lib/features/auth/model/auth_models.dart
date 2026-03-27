/// Auth models matching backend SignupRequest / SignupResponse.
library;

class SignupRequest {
  final String name;
  final String email;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;
  final String dietType;
  final String activityLevel;
  final String budget;

  const SignupRequest({
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.dietType,
    required this.activityLevel,
    required this.budget,
  });

  Map<String, dynamic> toJson() => {
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
      };
}

class SignupResponse {
  final String message;
  final String userId;
  final int dailyCalorieTarget;
  final int proteinTargetG;
  final int carbsTargetG;
  final int fatTargetG;

  const SignupResponse({
    required this.message,
    required this.userId,
    required this.dailyCalorieTarget,
    required this.proteinTargetG,
    required this.carbsTargetG,
    required this.fatTargetG,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
        message: json['message'] ?? '',
        userId: json['user_id'] ?? '',
        dailyCalorieTarget: json['daily_calorie_target'] ?? 0,
        proteinTargetG: json['protein_target_g'] ?? 0,
        carbsTargetG: json['carbs_target_g'] ?? 0,
        fatTargetG: json['fat_target_g'] ?? 0,
      );
}

/// Lightweight user model for local state.
class UserModel {
  final String name;
  final String email;
  String? userId;
  int? dailyCalorieTarget;

  UserModel({
    required this.name,
    required this.email,
    this.userId,
    this.dailyCalorieTarget,
  });
}
