// ─────────────────────────────────────────────────────────────
// lib/widgets/metabolic_state_banner.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../main.dart';

class MetabolicStateBanner extends StatelessWidget {
  final dynamic result; // CheckinResult

  const MetabolicStateBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(result.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.metabolicState
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w[0].toUpperCase() + w.substring(1))
                      .join(' '),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(result.stateLabel,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}