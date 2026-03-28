// lib/widgets/meal_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';
import '../providers/meal_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

class MealSlotCard extends StatelessWidget {
  final MealSlot slot;
  const MealSlotCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _slotLabel(slot.slot),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
        ),
        ...slot.options.map((meal) => _MealOptionCard(meal: meal, slot: slot)),
        const SizedBox(height: 8),
      ],
    );
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'breakfast': return '🌅 Breakfast';
      case 'lunch':     return '☀️ Lunch';
      case 'dinner':    return '🌙 Dinner';
      case 'snack':     return '🍎 Snack';
      default:          return slot[0].toUpperCase() + slot.substring(1);
    }
  }
}

class _MealOptionCard extends StatefulWidget {
  final Meal     meal;
  final MealSlot slot;
  const _MealOptionCard({required this.meal, required this.slot});

  @override
  State<_MealOptionCard> createState() => _MealOptionCardState();
}

class _MealOptionCardState extends State<_MealOptionCard> {
  int?  _rating;
  bool  _logged  = false;
  bool  _logging = false;

  Future<void> _logMeal(int rating) async {
    if (_logging) return;
    setState(() { _logging = true; });

    final auth  = context.read<AuthProvider>();
    final meals = context.read<MealProvider>();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final ok = await meals.logMealWithRating(
      userId:  auth.email ?? '',      // ← auth.userId doesn't exist, use email
      mealId:  widget.meal.mealId,
      slot:    widget.slot.slot,
      date:    today,
      rating:  rating,
    );

    if (mounted) {
      setState(() {
        _rating  = rating;
        _logged  = ok;
        _logging = false;
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.meal.name} logged! ⭐ $rating/5'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/meal-detail',
        arguments: widget.meal,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: _logged
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant,
                        color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.meal.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ),
                            if (_logged)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Logged ✓',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ↓ whyRecommended used as subtitle — no 'description' in Meal
                        Text(
                          widget.meal.whyRecommended,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _macro('${widget.meal.calories}', 'kcal',
                                AppTheme.primary),
                            const SizedBox(width: 10),
                            // ↓ proteinG not protein
                            _macro(
                                '${widget.meal.proteinG.toStringAsFixed(1)}g',
                                'protein',
                                Colors.blueAccent),
                            const SizedBox(width: 10),
                            // ↓ carbsG not carbs
                            _macro(
                                '${widget.meal.carbsG.toStringAsFixed(1)}g',
                                'carbs',
                                Colors.orange),
                            const SizedBox(width: 10),
                            // ↓ fatG not fat
                            _macro(
                                '${widget.meal.fatG.toStringAsFixed(1)}g',
                                'fat',
                                Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Star rating row ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  const Text('Rate & log: ',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: _logging ? null : () => _logMeal(star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _logging
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5))
                            : Icon(
                                (_rating != null && star <= _rating!)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 22,
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}