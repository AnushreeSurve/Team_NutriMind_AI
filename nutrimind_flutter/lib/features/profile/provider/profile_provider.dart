/// Profile providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

/// Dark mode toggle.
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false);

  void toggle() => state = !state;
}

final darkModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>(
  (ref) => ThemeModeNotifier(),
);

/// Google Fit integration toggle (UI only).
class GoogleFitNotifier extends StateNotifier<bool> {
  GoogleFitNotifier() : super(false);

  void toggle() => state = !state;
}

final googleFitProvider = StateNotifierProvider<GoogleFitNotifier, bool>(
  (ref) => GoogleFitNotifier(),
);

/// User diet preference
class DietTypeNotifier extends StateNotifier<String> {
  DietTypeNotifier() : super('veg'); // Default

  void setDietType(String type) => state = type;
}

final dietTypeProvider = StateNotifierProvider<DietTypeNotifier, String>(
  (ref) => DietTypeNotifier(),
);
