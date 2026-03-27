/// Step 6: Activity Level — selectable cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  static const _levels = [
    {
      'label': 'Sedentary',
      'desc': 'Little or no exercise',
      'icon': Icons.weekend_rounded,
      'value': 'sedentary',
    },
    {
      'label': 'Light',
      'desc': 'Light exercise 1-3 days/week',
      'icon': Icons.directions_walk_rounded,
      'value': 'light',
    },
    {
      'label': 'Moderate',
      'desc': 'Moderate exercise 3-5 days/week',
      'icon': Icons.directions_run_rounded,
      'value': 'moderate',
    },
    {
      'label': 'Active',
      'desc': 'Heavy exercise 6-7 days/week',
      'icon': Icons.sports_rounded,
      'value': 'active',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider).data;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity level',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How active are you on a daily basis?',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 28),
          ..._levels.map((level) {
            final value = level['value'] as String;
            final selected = data.activityLevel == value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(activityLevel: value),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppTheme.primaryTeal : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        level['icon'] as IconData,
                        size: 32,
                        color: selected
                            ? AppTheme.primaryTeal
                            : AppTheme.subtitleGrey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? AppTheme.primaryTeal : null,
                              ),
                            ),
                            Text(
                              level['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitleGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryTeal,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
