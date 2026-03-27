/// Meal detail screen — full meal info with macros and feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../model/meal_models.dart';
import '../provider/meals_provider.dart';

class MealDetailScreen extends ConsumerWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find meal by name (used as id from route)
    final decoded = Uri.decodeComponent(mealId);
    final meal = MealItem.mockList.firstWhere(
      (m) => m.name == decoded,
      orElse: () => MealItem.mockList.first,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              title: Text(
                meal.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tags ──────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(meal.slot.toUpperCase(), AppTheme.primaryTeal),
                      _Tag(meal.dietType, AppTheme.accentBlue),
                      ...meal.tags.map((t) => _Tag(t, AppTheme.warningOrange)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Description ───────────────────────────────
                  if (meal.description.isNotEmpty) ...[
                    Text(
                      meal.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppTheme.subtitleGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Macros ────────────────────────────────────
                  const Text(
                    'Nutrition Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MacroCard(
                        label: 'Calories',
                        value: '${meal.calories}',
                        unit: 'kcal',
                        color: Colors.orange,
                      ),
                      _MacroCard(
                        label: 'Protein',
                        value: '${meal.proteinG.round()}',
                        unit: 'g',
                        color: AppTheme.errorRed,
                      ),
                      _MacroCard(
                        label: 'Carbs',
                        value: '${meal.carbsG.round()}',
                        unit: 'g',
                        color: AppTheme.accentBlue,
                      ),
                      _MacroCard(
                        label: 'Fat',
                        value: '${meal.fatG.round()}',
                        unit: 'g',
                        color: AppTheme.warningOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),

                  // ── Log this meal button ───────────────────────
                  GradientButton(
                    text: 'Log This Meal',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${meal.name} logged ✓'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
