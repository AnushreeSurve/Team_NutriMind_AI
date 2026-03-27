/// Onboarding state model and Riverpod provider.
/// Collects all 8-step data and submits to backend.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/provider/auth_provider.dart';
import '../../auth/model/auth_models.dart';
import '../../auth/repository/auth_repository.dart';

// ── Onboarding data model ─────────────────────────────────────
class OnboardingData {
  int age;
  String gender;
  double heightCm;
  double weightKg;
  List<String> goals;
  List<String> dietTypes;
  List<String> allergies;
  String otherAllergy;
  double waterGoalL;
  String activityLevel;
  bool locationGranted;
  double budgetMin;
  double budgetMax;
  int mealsPerDay;
  List<String> mealTimings;

  OnboardingData({
    this.age = 25,
    this.gender = 'male',
    this.heightCm = 170,
    this.weightKg = 70,
    this.goals = const [],
    this.dietTypes = const [],
    this.allergies = const [],
    this.otherAllergy = '',
    this.waterGoalL = 2,
    this.activityLevel = 'moderate',
    this.locationGranted = false,
    this.budgetMin = 500,
    this.budgetMax = 2000,
    this.mealsPerDay = 3,
    this.mealTimings = const ['Breakfast', 'Lunch', 'Dinner'],
  });

  OnboardingData copyWith({
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? goals,
    List<String>? dietTypes,
    List<String>? allergies,
    String? otherAllergy,
    double? waterGoalL,
    String? activityLevel,
    bool? locationGranted,
    double? budgetMin,
    double? budgetMax,
    int? mealsPerDay,
    List<String>? mealTimings,
  }) {
    return OnboardingData(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goals: goals ?? this.goals,
      dietTypes: dietTypes ?? this.dietTypes,
      allergies: allergies ?? this.allergies,
      otherAllergy: otherAllergy ?? this.otherAllergy,
      waterGoalL: waterGoalL ?? this.waterGoalL,
      activityLevel: activityLevel ?? this.activityLevel,
      locationGranted: locationGranted ?? this.locationGranted,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      mealTimings: mealTimings ?? this.mealTimings,
    );
  }

  /// Map goal list to backend's single-value goal field.
  String get primaryGoal {
    if (goals.contains('Weight loss')) return 'lose';
    if (goals.contains('Muscle gain')) return 'gain';
    return 'maintain';
  }

  /// Map diet types to backend's single-value diet_type field.
  String get primaryDiet {
    if (dietTypes.contains('Vegan')) return 'vegan';
    if (dietTypes.contains('Jain')) return 'jain';
    if (dietTypes.contains('Non-veg')) return 'non-veg';
    return 'veg';
  }

  /// Map budget range to backend's budget category.
  String get budgetCategory {
    final mid = (budgetMin + budgetMax) / 2;
    if (mid < 1000) return 'low';
    if (mid < 3000) return 'mid';
    return 'high';
  }
}

// ── Onboarding state ──────────────────────────────────────────
class OnboardingState {
  final int currentStep;
  final int totalSteps;
  final OnboardingData data;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 8,
    required this.data,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    OnboardingData? data,
    bool? isSubmitting,
    String? error,
  }) =>
      OnboardingState(
        currentStep: currentStep ?? this.currentStep,
        totalSteps: totalSteps,
        data: data ?? this.data,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );

  double get progress => (currentStep + 1) / totalSteps;
}

// ── Onboarding notifier ───────────────────────────────────────
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final AuthRepository _authRepo;
  final AuthNotifier _authNotifier;

  OnboardingNotifier(this._authRepo, this._authNotifier)
      : super(OnboardingState(data: OnboardingData()));

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateData(OnboardingData Function(OnboardingData) updater) {
    state = state.copyWith(data: updater(state.data));
  }

  /// Submit onboarding data to backend (signup endpoint).
  Future<bool> submit() async {
    final user = _authNotifier.state.user;
    if (user == null) return false;

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final request = SignupRequest(
        name: user.name,
        email: user.email,
        age: state.data.age,
        gender: state.data.gender,
        heightCm: state.data.heightCm,
        weightKg: state.data.weightKg,
        goal: state.data.primaryGoal,
        dietType: state.data.primaryDiet,
        activityLevel: state.data.activityLevel,
        budget: state.data.budgetCategory,
      );
      await _authRepo.signup(request);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(
    ref.read(authRepositoryProvider),
    ref.read(authProvider.notifier),
  ),
);
