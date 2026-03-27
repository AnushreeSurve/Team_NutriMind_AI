// lib/screens/meals/meal_compare_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart';

class MealCompareScreen extends StatelessWidget {
  const MealCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Meals')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Select two meals from your meal plan to compare their nutrition scores',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}
