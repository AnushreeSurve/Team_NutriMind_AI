// lib/widgets/meal_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../main.dart';

class MealSlotCard extends StatefulWidget {
  final MealSlot slot;
  const MealSlotCard({super.key, required this.slot});
  @override
  State<MealSlotCard> createState() => _MealSlotCardState();
}

class _MealSlotCardState extends State<MealSlotCard> {
  int _selectedOption = 0;

  String get _slotEmoji {
    switch (widget.slot.slot) {
      case 'breakfast': return '🌅';
      case 'lunch':     return '☀️';
      case 'snack':     return '🍎';
      case 'dinner':    return '🌙';
      default:          return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.slot.options.isNotEmpty
        ? widget.slot.options[_selectedOption]
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot header
            Row(
              children: [
                Text(_slotEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  widget.slot.slot[0].toUpperCase() +
                      widget.slot.slot.substring(1),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(widget.slot.scheduledTime,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),

            if (meal != null) ...[
              const SizedBox(height: 12),
              // Option selector
              if (widget.slot.options.length > 1)
                Row(
                  children: List.generate(widget.slot.options.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOption = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedOption == i
                              ? AppTheme.primary
                              : const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Option ${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                color: _selectedOption == i
                                    ? Colors.white
                                    : AppTheme.textSecondary)),
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 10),

              // Meal name
              Text(meal.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(meal.whyRecommended,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),

              const SizedBox(height: 12),

              // Nutrition row
              Row(
                children: [
                  _nutriChip('${meal.calories} kcal', AppTheme.accent),
                  const SizedBox(width: 6),
                  _nutriChip('${meal.proteinG}g protein', AppTheme.primary),
                  const SizedBox(width: 6),
                  _nutriChip('Inflam ${meal.inflammationScore}/10',
                      meal.inflammationScore <= 3
                          ? AppTheme.secondary
                          : meal.inflammationScore <= 6
                              ? AppTheme.accent
                              : AppTheme.danger),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context, '/meal-detail',
                        arguments: {
                          'meal_id':            meal.mealId,
                          'name':               meal.name,
                          'calories':           meal.calories,
                          'protein_g':          meal.proteinG,
                          'carbs_g':            meal.carbsG,
                          'fat_g':              meal.fatG,
                          'inflammation_score': meal.inflammationScore,
                          'recovery_impact':    meal.recoveryImpact,
                          'prep_type':          meal.prepType,
                          'why_recommended':    meal.whyRecommended,
                        },
                      ),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showFeedbackSheet(context, meal),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      child: const Text('Log Meal'),
                    ),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No options available',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nutriChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  void _showFeedbackSheet(BuildContext context, Meal meal) {
    bool? consumed;
    int rating = 4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log: ${meal.name}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Did you eat this meal?',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _feedbackBtn('Yes ✅', consumed == true,
                        () => setSheetState(() => consumed = true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _feedbackBtn('No ❌', consumed == false,
                        () => setSheetState(() => consumed = false)),
                  ),
                ],
              ),
              if (consumed == true) ...[
                const SizedBox(height: 20),
                const Text('Rate this meal:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setSheetState(() => rating = i + 1),
                      child: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.accent,
                        size: 36,
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 20),
              if (consumed != null)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final auth  = context.read<AuthProvider>();
                    final meals = context.read<MealProvider>();
                    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    await meals.logMeal(
                      userId:   auth.userId ?? '',
                      mealId:   meal.mealId,
                      slot:     widget.slot.slot,
                      date:     today,
                      consumed: consumed!,
                      rating:   consumed! ? rating : null,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meal logged!')));
                    }
                  },
                  child: const Text('Submit'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 2),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary)),
        ),
      ),
    );
  }
}

