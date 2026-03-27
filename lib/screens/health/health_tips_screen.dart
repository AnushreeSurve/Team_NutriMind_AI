// lib/screens/health/health_tips_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  static const List<Map<String, dynamic>> _conditions = [
    {
      'name': 'PCOS',
      'icon': '🌸',
      'color': 0xFFD4537E,
      'focus': 'Low GI foods, anti-inflammatory diet, high fibre',
      'eat': ['Oats', 'Lentils', 'Leafy greens', 'Flaxseeds', 'Berries'],
      'avoid': ['Sugar', 'White bread', 'Fried foods', 'Dairy excess'],
      'meal_plan': [
        'Breakfast: Oats + Flaxseed + Berries (280 cal)',
        'Lunch: Moong Dal + Brown Rice (370 cal)',
        'Snack: Handful of nuts + green tea (150 cal)',
        'Dinner: Stir-fried veggies + Quinoa (340 cal)',
      ],
    },
    {
      'name': 'Diabetes',
      'icon': '🩺',
      'color': 0xFF1A73E8,
      'focus': 'Low glycaemic index, controlled carbs, high protein',
      'eat': ['Bitter gourd', 'Methi', 'Lentils', 'Fish', 'Oats'],
      'avoid': ['White rice', 'Sugar', 'Fruit juice', 'Maida'],
      'meal_plan': [
        'Breakfast: Methi Paratha (small) + Curd (260 cal)',
        'Lunch: Brown Rice + Rajma + Salad (380 cal)',
        'Snack: Roasted chana + Cucumber (130 cal)',
        'Dinner: Dal + 2 Roti + Sabzi (350 cal)',
      ],
    },
    {
      'name': 'Thyroid',
      'icon': '🦋',
      'color': 0xFF7F77DD,
      'focus': 'Iodine-rich, selenium foods; avoid goitrogens',
      'eat': ['Eggs', 'Fish', 'Brazil nuts', 'Dairy', 'Iodized salt'],
      'avoid': ['Raw cabbage', 'Soy excess', 'Millet excess'],
      'meal_plan': [
        'Breakfast: Egg + whole grain toast + milk (300 cal)',
        'Lunch: Fish curry + Rice + Salad (420 cal)',
        'Snack: Yogurt + walnuts (160 cal)',
        'Dinner: Chicken stew + sweet potato (380 cal)',
      ],
    },
    {
      'name': 'High BP',
      'icon': '❤️',
      'color': 0xFFE24B4A,
      'focus': 'DASH diet: low sodium, high potassium, high fibre',
      'eat': ['Banana', 'Spinach', 'Oats', 'Beets', 'Garlic'],
      'avoid': ['Salt excess', 'Pickles', 'Processed food', 'Alcohol'],
      'meal_plan': [
        'Breakfast: Oats + Banana + low-fat milk (300 cal)',
        'Lunch: Spinach dal + Brown rice (370 cal)',
        'Snack: Beet juice + almonds (140 cal)',
        'Dinner: Grilled chicken + sautéed greens (380 cal)',
      ],
    },
    {
      'name': 'General Wellness',
      'icon': '✨',
      'color': 0xFF0F6E56,
      'focus': 'Balanced macros, adequate hydration, quality sleep',
      'eat': ['Whole grains', 'Legumes', 'Fresh fruit', 'Vegetables', 'Nuts'],
      'avoid': ['Ultra-processed food', 'Excess sugar', 'Refined carbs'],
      'meal_plan': [
        'Breakfast: Poha + peanuts + fruit (300 cal)',
        'Lunch: Dal + Rice + Sabzi (450 cal)',
        'Snack: Mixed fruit bowl (150 cal)',
        'Dinner: Roti + Paneer curry + salad (420 cal)',
      ],
    },
    {
      'name': 'Weight Loss',
      'icon': '🎯',
      'color': 0xFFEF9F27,
      'focus': 'Calorie deficit, high protein, high fibre',
      'eat': ['Eggs', 'Greek yogurt', 'Leafy greens', 'Legumes', 'Berries'],
      'avoid': ['Fried snacks', 'Sugary drinks', 'White bread', 'Excess oil'],
      'meal_plan': [
        'Breakfast: Moong dal chilla + curd (280 cal)',
        'Lunch: Grilled chicken + salad + dal (380 cal)',
        'Snack: Sprouts chaat (150 cal)',
        'Dinner: Vegetable soup + 1 roti (280 cal)',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Tips')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _conditions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = _conditions[i];
          final color = Color(c['color'] as int);
          return Card(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(c['icon'],
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                title: Text(c['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c['focus'],
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        _tipSection('✅ Eat more', c['eat'] as List, color),
                        const SizedBox(height: 14),
                        _tipSection('❌ Avoid', c['avoid'] as List,
                            AppTheme.danger),
                        const SizedBox(height: 14),
                        _mealPlanSection(c['meal_plan'] as List),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tipSection(String title, List items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(item,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500)),
              )).toList(),
        ),
      ],
    );
  }

  Widget _mealPlanSection(List meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📋 Sample Meal Plan',
            style:
                TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ...meals.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  Expanded(
                      child: Text(m,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }
}
