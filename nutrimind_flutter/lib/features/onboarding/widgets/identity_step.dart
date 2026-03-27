/// Step 1: Identity — Age, Gender, Height, Weight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class IdentityStep extends ConsumerWidget {
  const IdentityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider).data;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about you',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use this to personalize your nutrition plan',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 32),

          // ── Age ────────────────────────────────────────────
          _buildLabel(context, 'Age'),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(age: (d.age - 1).clamp(10, 99)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${data.age}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _StepperButton(
                icon: Icons.add,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(age: (d.age + 1).clamp(10, 99)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Gender ─────────────────────────────────────────
          _buildLabel(context, 'Gender'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: ['male', 'female', 'other'].map((g) {
              final selected = data.gender == g;
              return ChoiceChip(
                label: Text(
                  g[0].toUpperCase() + g.substring(1),
                  style: TextStyle(
                    color: selected ? AppTheme.primaryTeal : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                selected: selected,
                onSelected: (_) =>
                    notifier.updateData((d) => d.copyWith(gender: g)),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── Height ─────────────────────────────────────────
          _buildLabel(context, 'Height (cm)'),
          const SizedBox(height: 8),
          Slider(
            value: data.heightCm,
            min: 100,
            max: 220,
            divisions: 120,
            label: '${data.heightCm.round()} cm',
            activeColor: AppTheme.primaryTeal,
            onChanged: (v) =>
                notifier.updateData((d) => d.copyWith(heightCm: v)),
          ),
          Center(
            child: Text(
              '${data.heightCm.round()} cm',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Weight ─────────────────────────────────────────
          _buildLabel(context, 'Weight (kg)'),
          const SizedBox(height: 8),
          Slider(
            value: data.weightKg,
            min: 30,
            max: 200,
            divisions: 170,
            label: '${data.weightKg.round()} kg',
            activeColor: AppTheme.primaryTeal,
            onChanged: (v) =>
                notifier.updateData((d) => d.copyWith(weightKg: v)),
          ),
          Center(
            child: Text(
              '${data.weightKg.round()} kg',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── BMI Display ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated BMI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  (data.weightKg / ((data.heightCm / 100) * (data.heightCm / 100))).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal),
      ),
    );
  }
}
