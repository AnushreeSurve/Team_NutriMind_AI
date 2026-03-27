// lib/screens/meals/meal_detail_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meal = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>?;
    if (meal == null) {
      return const Scaffold(
          body: Center(child: Text('No meal data')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(meal['name'] ?? 'Meal Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nutrition grid
            Row(children: [
              _nutriBox('Calories', '${meal['calories']}', 'kcal',
                  AppTheme.accent),
              const SizedBox(width: 12),
              _nutriBox('Protein', '${meal['protein_g']}', 'g',
                  AppTheme.primary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _nutriBox('Carbs', '${meal['carbs_g']}', 'g',
                  AppTheme.secondary),
              const SizedBox(width: 12),
              _nutriBox('Fat', '${meal['fat_g']}', 'g',
                  const Color(0xFF7F77DD)),
            ]),
            const SizedBox(height: 20),

            // Inflammation score bar
            _scoreRow(
                'Inflammation Score',
                (meal['inflammation_score'] as num?)?.toInt() ?? 5,
                10,
                AppTheme.danger),
            const SizedBox(height: 16),

            // Recovery badge
            _recoveryBadge(meal['recovery_impact'] ?? 'medium'),
            const SizedBox(height: 20),

            // Why recommended
            if ((meal['why_recommended'] ?? '').toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.secondary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(meal['why_recommended'],
                            style: const TextStyle(fontSize: 14,
                                height: 1.5))),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Cook / Order tabs
            const Text('Options',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '👨‍🍳 Cook at Home'),
                      Tab(text: '🍽️ Order Out'),
                    ],
                  ),
                  SizedBox(
                    height: 100,
                    child: TabBarView(children: [
                      Center(
                        child: Text(
                          meal['prep_type'] == 'home'
                              ? 'Great choice for home cooking!'
                              : 'Can also be made at home with simple ingredients.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                      ),
                      Center(
                        child: Text(
                          meal['prep_type'] == 'restaurant'
                              ? 'Available at nearby restaurants'
                              : 'Best when home cooked for maximum nutrition.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutriBox(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, int value, int max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$value / $max',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / max,
            color: color,
            backgroundColor: color.withOpacity(0.15),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _recoveryBadge(String impact) {
    final colors = {
      'high':   AppTheme.secondary,
      'medium': AppTheme.accent,
      'low':    AppTheme.textSecondary,
    };
    final color = colors[impact] ?? AppTheme.textSecondary;
    return Row(
      children: [
        const Text('Recovery Impact: ',
            style: TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(impact.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
