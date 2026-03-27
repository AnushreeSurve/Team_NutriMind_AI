// lib/screens/hydration/hydration_screen.dart

import 'package:flutter/material.dart';
import '../../main.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});
  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  int _glasses = 3;
  final int _target = 8;

  @override
  Widget build(BuildContext context) {
    final pct = (_glasses / _target).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200, height: 200,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 16,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 1.0 ? AppTheme.secondary : AppTheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, color: AppTheme.primary, size: 32),
                    const SizedBox(height: 4),
                    Text('$_glasses / $_target',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('glasses',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _glasses < _target
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '💧 Drink ${_target - _glasses} more glasses to hit your daily goal',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.accent),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🎉 You\'ve hit your hydration goal today!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.secondary)),
                  ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (_glasses > 0) setState(() => _glasses--);
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_glasses < 15) setState(() => _glasses++);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Glass'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 48)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Tips
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hydration Tips',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            ...[
              '💧 Start your day with a glass of water before anything else',
              '🍋 Add lemon or cucumber for variety',
              '⏰ Set reminders every 2 hours',
              '🌡️ Hot weather increases your needs — add 1–2 extra glasses',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(tip,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  height: 1.4))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
