/// Step 5: Water Goal — selectable cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class WaterGoalStep extends ConsumerWidget {
  const WaterGoalStep({super.key});

  static const _options = [
    {'label': '1 Litre', 'value': 1.0, 'icon': Icons.water_drop_outlined},
    {'label': '2 Litres', 'value': 2.0, 'icon': Icons.water_drop_rounded},
    {'label': '3 Litres', 'value': 3.0, 'icon': Icons.water_drop_rounded},
    {'label': '4+ Litres', 'value': 4.0, 'icon': Icons.waves_rounded},
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
            'Daily water goal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How much water do you want to drink daily?',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 28),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: _options.map((opt) {
              final value = opt['value'] as double;
              final label = opt['label'] as String;
              final icon = opt['icon'] as IconData;
              final selected = data.waterGoalL == value;

              return GestureDetector(
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(waterGoalL: value),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 32,
                        color: selected
                            ? AppTheme.primaryTeal
                            : AppTheme.subtitleGrey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primaryTeal : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
