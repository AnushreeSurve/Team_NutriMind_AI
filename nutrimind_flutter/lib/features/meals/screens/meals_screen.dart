/// Meals screen — meal list with filters and feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/meals_provider.dart';
import '../model/meal_models.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mealsFilterProvider);
    final meals = ref.watch(filteredMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter.slot == 'all',
                  onTap: () =>
                      ref.read(mealsFilterProvider.notifier).setSlot('all'),
                ),
                _FilterChip(
                  label: 'Breakfast',
                  selected: filter.slot == 'breakfast',
                  onTap: () =>
                      ref.read(mealsFilterProvider.notifier).setSlot('breakfast'),
                ),
                _FilterChip(
                  label: 'Lunch',
                  selected: filter.slot == 'lunch',
                  onTap: () =>
                      ref.read(mealsFilterProvider.notifier).setSlot('lunch'),
                ),
                _FilterChip(
                  label: 'Dinner',
                  selected: filter.slot == 'dinner',
                  onTap: () =>
                      ref.read(mealsFilterProvider.notifier).setSlot('dinner'),
                ),
                _FilterChip(
                  label: 'Snack',
                  selected: filter.slot == 'snack',
                  onTap: () =>
                      ref.read(mealsFilterProvider.notifier).setSlot('snack'),
                ),
              ],
            ),
          ),

          // ── Meals list ───────────────────────────────────────
          Expanded(
            child: meals.isEmpty
                ? const EmptyStateWidget(
                    message: 'No meals match your filters',
                    icon: Icons.restaurant_rounded,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (filter.slot == 'all' || filter.slot == 'breakfast')
                        _MealSection(slot: 'breakfast', title: 'Breakfast', meals: meals.where((m) => m.slot == 'breakfast').toList()),
                      if (filter.slot == 'all' || filter.slot == 'lunch')
                        _MealSection(slot: 'lunch', title: 'Lunch', meals: meals.where((m) => m.slot == 'lunch').toList()),
                      if (filter.slot == 'all' || filter.slot == 'snack')
                        _MealSection(slot: 'snack', title: 'Snacks', meals: meals.where((m) => m.slot == 'snack').toList()),
                      if (filter.slot == 'all' || filter.slot == 'dinner')
                        _MealSection(slot: 'dinner', title: 'Dinner', meals: meals.where((m) => m.slot == 'dinner').toList()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Diet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['all', 'veg', 'non-veg', 'vegan', 'jain', 'eggetarian']
                    .map((dt) => ChoiceChip(
                          label: Text(dt == 'all' ? 'All' : dt),
                          selected:
                              ref.read(mealsFilterProvider).dietType == dt,
                          onSelected: (_) {
                            ref
                                .read(mealsFilterProvider.notifier)
                                .setDietType(dt);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: AppTheme.primaryTeal,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MealListCard extends StatelessWidget {
  final MealItem meal;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _MealListCard({
    required this.meal,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Meal type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.calories} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtitleGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tags
          if (meal.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: meal.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 10),
          // Selection row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSelected)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                    SizedBox(width: 4),
                    Text('Selected', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: onSelect,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryTeal),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Select', style: TextStyle(color: AppTheme.primaryTeal)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  final String slot;
  final String title;
  final List<MealItem> meals;

  const _MealSection({required this.slot, required this.title, required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (meals.isEmpty) return const SizedBox.shrink();

    final selectedMeal = ref.watch(selectedMealsProvider)[slot];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...meals.map((meal) {
          final isSelected = selectedMeal?.id == meal.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MealListCard(
              meal: meal,
              isSelected: isSelected,
              onTap: () => context.push('/meal-detail/${Uri.encodeComponent(meal.name)}'),
              onSelect: () => _handleSelect(context, ref, meal),
            ),
          );
        }),
        _OtherMealButton(slot: slot),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleSelect(BuildContext context, WidgetRef ref, MealItem meal) async {
    ref.read(selectedMealsProvider.notifier).selectMeal(slot, meal);
    
    // Real Supabase insertion integration
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(mealsRepositoryProvider).addMeal(
        email: user.email,
        mealName: meal.name,
        calories: meal.calories,
        proteinG: meal.proteinG,
        carbsG: meal.carbsG,
        fatG: meal.fatG,
        slot: slot,
      );
    }
    
    // UI confirmation
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${meal.name} selected!'),
      backgroundColor: AppTheme.successGreen,
    ));
    
    // Emoji popup
    final rating = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate this meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => Navigator.pop(ctx, i),
                child: Text(
                  _getEmoji(i),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
          ],
        ),
      ),
    );

    if (rating != null) {
      ref.read(mealRatingProvider.notifier).rateMeal(meal.id, rating);
    }
  }

  String _getEmoji(int rating) {
    switch (rating) {
      case 1: return '🤮';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😍';
      default: return '😐';
    }
  }
}

class _OtherMealButton extends ConsumerWidget {
  final String slot;
  const _OtherMealButton({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showOtherMealDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text('Use Custom ${slot[0].toUpperCase()}${slot.substring(1)}'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
      ),
    );
  }

  void _showOtherMealDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Meal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., 2 slices whole wheat bread with peanut butter',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final text = controller.text;
              Navigator.pop(ctx);
              
              // Gemini AI integration
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Analyzing meal with Gemini...'),
                backgroundColor: AppTheme.accentBlue,
              ));
              
              final analysis = await ref.read(mealsRepositoryProvider).analyzeFood(text, 100);
              
              final customMeal = MealItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: analysis.foodName,
                calories: analysis.calories,
                proteinG: analysis.proteinG,
                carbsG: analysis.carbsG,
                fatG: analysis.fatG,
                slot: slot,
                tags: ['Custom', 'Gemini AI'],
              );
              ref.read(selectedMealsProvider.notifier).selectMeal(slot, customMeal);

              final user = ref.read(authProvider).user;
              if (user != null) {
                ref.read(mealsRepositoryProvider).addMeal(
                  email: user.email,
                  mealName: customMeal.name,
                  calories: customMeal.calories,
                  proteinG: customMeal.proteinG,
                  carbsG: customMeal.carbsG,
                  fatG: customMeal.fatG,
                  slot: slot,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Analyze & Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }
}
