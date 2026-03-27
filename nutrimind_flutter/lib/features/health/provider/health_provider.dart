/// Health providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(),
);

/// Expanded conditions state — which cards are expanded.
class HealthExpandedNotifier extends StateNotifier<Set<String>> {
  HealthExpandedNotifier() : super({});

  void toggle(String condition) {
    final updated = Set<String>.from(state);
    if (updated.contains(condition)) {
      updated.remove(condition);
    } else {
      updated.add(condition);
    }
    state = updated;
  }
}

final healthExpandedProvider =
    StateNotifierProvider<HealthExpandedNotifier, Set<String>>(
  (ref) => HealthExpandedNotifier(),
);
