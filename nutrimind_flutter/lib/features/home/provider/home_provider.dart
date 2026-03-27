/// Home providers using Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/home_models.dart';
import '../repository/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(),
);

final dailySummaryProvider = FutureProvider.family<DailySummary, String>(
  (ref, email) => ref.read(homeRepositoryProvider).getDailySummary(email),
);

final fullDayProvider =
    FutureProvider.family<FullDayResponse, String>(
  (ref, email) =>
      ref.read(homeRepositoryProvider).getFullDayRecommendations(email),
);

/// Water intake state — tracks current water intake (ml).
class WaterIntakeNotifier extends StateNotifier<int> {
  WaterIntakeNotifier() : super(0);

  void addWater(int ml) => state = state + ml;
  void reset() => state = 0;
}

final waterIntakeProvider = StateNotifierProvider<WaterIntakeNotifier, int>(
  (ref) => WaterIntakeNotifier(),
);
