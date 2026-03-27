// lib/models/user_model.dart

class UserProfile {
  final String userId;
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
  final String locationCity;
  final int dailyCalorieTarget;
  final int proteinTargetG;
  final bool onboardingComplete;

  UserProfile({
    required this.userId,
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
    required this.locationCity,
    required this.dailyCalorieTarget,
    required this.proteinTargetG,
    required this.onboardingComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId:              json['user_id'] ?? '',
        name:                json['name'] ?? '',
        email:               json['email'] ?? '',
        age:                 (json['age'] ?? 0) as int,
        gender:              json['gender'] ?? '',
        heightCm:            (json['height_cm'] ?? 0).toDouble(),
        weightKg:            (json['weight_kg'] ?? 0).toDouble(),
        goal:                json['goal'] ?? 'maintain',
        dietType:            json['diet_type'] ?? 'veg',
        activityLevel:       json['activity_level'] ?? 'moderate',
        budget:              json['budget'] ?? 'mid',
        locationCity:        json['location_city'] ?? 'Pune',
        dailyCalorieTarget:  (json['daily_calorie_target'] ?? 2000) as int,
        proteinTargetG:      (json['protein_target_g'] ?? 80) as int,
        onboardingComplete:  json['onboarding_complete'] ?? false,
      );
}

// lib/models/checkin_model.dart

class CheckinResult {
  final String metabolicState;
  final String stateLabel;
  final int calorieAdjustment;

  CheckinResult({
    required this.metabolicState,
    required this.stateLabel,
    required this.calorieAdjustment,
  });

  factory CheckinResult.fromJson(Map<String, dynamic> json) => CheckinResult(
        metabolicState:    json['metabolic_state'] ?? 'stress_recovery',
        stateLabel:        json['state_label'] ?? 'Have a balanced day!',
        calorieAdjustment: (json['calorie_adjustment'] ?? 0) as int,
      );

  String get emoji {
    switch (metabolicState) {
      case 'performance':     return '🚀';
      case 'stress_recovery': return '🌿';
      case 'fat_burn':        return '🔥';
      case 'cortisol_buffer': return '🧘';
      case 'muscle_repair':   return '💪';
      default:                return '✨';
    }
  }

  String get colorHex {
    switch (metabolicState) {
      case 'performance':     return '#1A73E8';
      case 'stress_recovery': return '#0F6E56';
      case 'fat_burn':        return '#EF9F27';
      case 'cortisol_buffer': return '#D4537E';
      case 'muscle_repair':   return '#7F77DD';
      default:                return '#555555';
    }
  }
}

// lib/models/dashboard_model.dart

class DashboardData {
  final String userName;
  final String todayMetabolicState;
  final String stateLabel;
  final bool checkinDone;
  final NutritionTargets todaysTargets;
  final WeeklySummary weeklySummary;
  final UpcomingMeal? upcomingMeal;

  DashboardData({
    required this.userName,
    required this.todayMetabolicState,
    required this.stateLabel,
    required this.checkinDone,
    required this.todaysTargets,
    required this.weeklySummary,
    this.upcomingMeal,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        userName:            json['user_name'] ?? '',
        todayMetabolicState: json['today_metabolic_state'] ?? 'normal',
        stateLabel:          json['state_label'] ?? '',
        checkinDone:         json['checkin_done'] ?? false,
        todaysTargets: NutritionTargets.fromJson(
            json['todays_targets'] ?? {}),
        weeklySummary: WeeklySummary.fromJson(
            json['weekly_summary'] ?? {}),
        upcomingMeal: json['upcoming_meal'] != null
            ? UpcomingMeal.fromJson(json['upcoming_meal'])
            : null,
      );
}

class NutritionTargets {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  NutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory NutritionTargets.fromJson(Map<String, dynamic> json) =>
      NutritionTargets(
        calories: (json['calories'] ?? 2000) as int,
        proteinG: (json['protein_g'] ?? 80) as int,
        carbsG:   (json['carbs_g'] ?? 250) as int,
        fatG:     (json['fat_g'] ?? 65) as int,
      );
}

class WeeklySummary {
  final int streakDays;
  final double avgRating;
  final String mealsFollowed;
  final String topInsight;

  WeeklySummary({
    required this.streakDays,
    required this.avgRating,
    required this.mealsFollowed,
    required this.topInsight,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        streakDays:   (json['streak_days'] ?? 0) as int,
        avgRating:    (json['avg_rating'] ?? 0.0).toDouble(),
        mealsFollowed: json['meals_followed'] ?? '0 of 0',
        topInsight:    json['top_insight'] ?? '',
      );
}

class UpcomingMeal {
  final String slot;
  final String mealName;
  final String scheduledTime;
  final String mealId;

  UpcomingMeal({
    required this.slot,
    required this.mealName,
    required this.scheduledTime,
    required this.mealId,
  });

  factory UpcomingMeal.fromJson(Map<String, dynamic> json) => UpcomingMeal(
        slot:          json['slot'] ?? '',
        mealName:      json['meal_name'] ?? '',
        scheduledTime: json['scheduled_time'] ?? '',
        mealId:        json['meal_id'] ?? '',
      );
}

class NutritionAlert {
  final String type;
  final String severity;
  final String message;
  final String suggestion;

  NutritionAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.suggestion,
  });

  factory NutritionAlert.fromJson(Map<String, dynamic> json) => NutritionAlert(
        type:       json['type'] ?? '',
        severity:   json['severity'] ?? 'low',
        message:    json['message'] ?? '',
        suggestion: json['suggestion'] ?? '',
      );
}
