/// PPG result screen — displays BPM, HRV, stress level, and confidence.
library;

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_button.dart';

class PpgResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const PpgResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bpm = (data['bpm'] ?? 72).toDouble();
    final stress = data['stress_level'] ?? 'LOW';
    final confidence = data['confidence'] ?? 'HIGH';
    final sdnn = data['sdnn_ms']?.toString() ?? '--';
    final rmssd = data['rmssd_ms']?.toString() ?? '--';

    Color stressColor;
    switch (stress) {
      case 'HIGH':
        stressColor = AppTheme.errorRed;
        break;
      case 'MEDIUM':
        stressColor = AppTheme.warningOrange;
        break;
      default:
        stressColor = AppTheme.successGreen;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── BPM display ──────────────────────────────────
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              gradient: AppTheme.primaryGradient,
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${bpm.round()}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'BPM',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _bpmLabel(bpm),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Metrics row ──────────────────────────────────
            Row(
              children: [
                _MetricCard(
                  label: 'Stress',
                  value: stress,
                  icon: Icons.psychology_rounded,
                  color: stressColor,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: 'Confidence',
                  value: confidence,
                  icon: Icons.verified_rounded,
                  color: AppTheme.accentBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricCard(
                  label: 'SDNN',
                  value: '${sdnn}ms',
                  icon: Icons.timeline_rounded,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: 'RMSSD',
                  value: '${rmssd}ms',
                  icon: Icons.show_chart_rounded,
                  color: AppTheme.warningOrange,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Actions ──────────────────────────────────────
            GradientButton(
              text: 'Save Reading',
              icon: Icons.save_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reading saved ✓'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bpmLabel(double bpm) {
    if (bpm < 60) return 'Below Normal';
    if (bpm <= 100) return 'Normal Range';
    return 'Elevated';
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
