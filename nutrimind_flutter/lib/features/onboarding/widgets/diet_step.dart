/// Step 3: Diet Type — multi-select chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class DietStep extends ConsumerWidget {
  const DietStep({super.key});

  static const _diets = [
    {'label': 'Veg', 'icon': Icons.eco_rounded},
    {'label': 'Non-veg', 'icon': Icons.set_meal_rounded},
    {'label': 'Jain', 'icon': Icons.spa_rounded},
    {'label': 'Vegan', 'icon': Icons.grass_rounded},
    {'label': 'Eggetarian', 'icon': Icons.egg_rounded},
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
            'Your diet preference?',
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
            children: _diets.map((diet) {
              final label = diet['label'] as String;
              final icon = diet['icon'] as IconData;
              final selected = data.dietTypes.contains(label);

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
                  final updated = List<String>.from(data.dietTypes);
                  selected ? updated.remove(label) : updated.add(label);
                  notifier.updateData((d) => d.copyWith(dietTypes: updated));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // ── Number of meals ────────────────────────────────
          Text(
            'Meals per day',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(mealsPerDay: (d.mealsPerDay - 1).clamp(1, 8)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${data.mealsPerDay}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _StepperButton(
                icon: Icons.add,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(mealsPerDay: (d.mealsPerDay + 1).clamp(1, 8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // ── Meal Timings ───────────────────────────────────
          Text(
            'Preferred Meal Timings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Breakfast', 'Morning Snack', 'Lunch', 'Evening Snack', 'Dinner'].map((timing) {
              final selected = data.mealTimings.contains(timing);
              return FilterChip(
                label: Text(
                  timing,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selectedColor: AppTheme.primaryTeal,
                checkmarkColor: Colors.white,
                selected: selected,
                onSelected: (_) {
                  final updated = List<String>.from(data.mealTimings);
                  selected ? updated.remove(timing) : updated.add(timing);
                  notifier.updateData((d) => d.copyWith(mealTimings: updated));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal),
      ),
    );
  }
}
