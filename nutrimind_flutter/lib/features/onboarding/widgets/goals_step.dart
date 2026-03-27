/// Step 2: Goals — multi-select chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  static const _goals = [
    {'label': 'Weight loss', 'icon': Icons.fitness_center_rounded},
    {'label': 'Muscle gain', 'icon': Icons.sports_gymnastics_rounded},
    {'label': 'Maintenance', 'icon': Icons.balance_rounded},
    {'label': 'PCOS control', 'icon': Icons.healing_rounded},
    {'label': 'Diabetes control', 'icon': Icons.bloodtype_rounded},
    {'label': 'BP control', 'icon': Icons.monitor_heart_rounded},
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
            'What are your goals?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _goals.map((goal) {
              final label = goal['label'] as String;
              final icon = goal['icon'] as IconData;
              final selected = data.goals.contains(label);

              return FilterChip(
                avatar: Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppTheme.subtitleGrey,
                ),
                label: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selectedColor: AppTheme.primaryTeal,
                checkmarkColor: Colors.white,
                selected: selected,
                onSelected: (_) {
                  final updatedGoals = List<String>.from(data.goals);
                  if (selected) {
                    updatedGoals.remove(label);
                  } else {
                    updatedGoals.add(label);
                  }
                  notifier.updateData((d) => d.copyWith(goals: updatedGoals));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
