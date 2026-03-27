/// Meals providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/meal_models.dart';
import '../repository/meals_repository.dart';
import '../../profile/provider/profile_provider.dart';

final mealsRepositoryProvider = Provider<MealsRepository>(
  (ref) => MealsRepository(),
);

/// Filter state for meals screen.
class MealsFilterState {
  final String slot;
  final String dietType;

  const MealsFilterState({this.slot = 'all', this.dietType = 'all'});

  MealsFilterState copyWith({String? slot, String? dietType}) =>
      MealsFilterState(
        slot: slot ?? this.slot,
        dietType: dietType ?? this.dietType,
      );
}

class MealsFilterNotifier extends StateNotifier<MealsFilterState> {
  MealsFilterNotifier() : super(const MealsFilterState());

  void setSlot(String slot) => state = state.copyWith(slot: slot);
  void setDietType(String type) => state = state.copyWith(dietType: type);
}

final mealsFilterProvider =
    StateNotifierProvider<MealsFilterNotifier, MealsFilterState>(
  (ref) => MealsFilterNotifier(),
);

final filteredMealsProvider = Provider<List<MealItem>>((ref) {
  final filter = ref.watch(mealsFilterProvider);
  final userDiet = ref.watch(dietTypeProvider);
  var meals = MealItem.mockList;

  final activeDiet = filter.dietType == 'all' ? userDiet.toLowerCase() : filter.dietType.toLowerCase();

  if (activeDiet != 'all') {
    meals = meals.where((m) => m.dietType.toLowerCase() == activeDiet).toList();
  }

  if (filter.slot != 'all') {
    meals = meals.where((m) => m.slot == filter.slot).toList();
  }
  return meals;
});

/// Selected meals per slot (e.g., 'breakfast' -> MealItem).
class SelectedMealsNotifier extends StateNotifier<Map<String, MealItem>> {
  SelectedMealsNotifier() : super({});

  void selectMeal(String slot, MealItem meal) {
    state = {...state, slot: meal};
  }
}

final selectedMealsProvider =
    StateNotifierProvider<SelectedMealsNotifier, Map<String, MealItem>>(
  (ref) => SelectedMealsNotifier(),
);

/// Meal rating state — tracks 1-5 rating per meal.
class MealRatingNotifier extends StateNotifier<Map<String, int>> {
  MealRatingNotifier() : super({});

  void rateMeal(String mealId, int rating) {
    state = {...state, mealId: rating};
  }
}

final mealRatingProvider =
    StateNotifierProvider<MealRatingNotifier, Map<String, int>>(
  (ref) => MealRatingNotifier(),
);

