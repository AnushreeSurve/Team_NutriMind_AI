/// Step 8: Budget — range slider (₹100 to ₹5000).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class BudgetStep extends ConsumerWidget {
  const BudgetStep({super.key});

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
            'Daily food budget',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your daily meal budget range',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 40),

          // ── Budget display ─────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '₹${data.budgetMin.round()} — ₹${data.budgetMax.round()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Range slider ───────────────────────────────────
          RangeSlider(
            values: RangeValues(data.budgetMin, data.budgetMax),
            min: 100,
            max: 5000,
            divisions: 49,
            activeColor: AppTheme.primaryTeal,
            labels: RangeLabels(
              '₹${data.budgetMin.round()}',
              '₹${data.budgetMax.round()}',
            ),
            onChanged: (range) {
              notifier.updateData((d) => d.copyWith(
                    budgetMin: range.start,
                    budgetMax: range.end,
                  ));
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹100', style: TextStyle(color: AppTheme.subtitleGrey)),
              Text('₹5000', style: TextStyle(color: AppTheme.subtitleGrey)),
            ],
          ),
          const SizedBox(height: 32),

          // ── Quick select cards ──────────────────────────────
          Text(
            'Quick select',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickBudget(
                label: 'Budget',
                range: '₹100 - ₹500',
                selected: data.budgetMax <= 500,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(budgetMin: 100, budgetMax: 500),
                ),
              ),
              _QuickBudget(
                label: 'Moderate',
                range: '₹500 - ₹1500',
                selected: data.budgetMin >= 500 && data.budgetMax <= 1500,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(budgetMin: 500, budgetMax: 1500),
                ),
              ),
              _QuickBudget(
                label: 'Premium',
                range: '₹1500 - ₹5000',
                selected: data.budgetMin >= 1500,
                onTap: () => notifier.updateData(
                  (d) => d.copyWith(budgetMin: 1500, budgetMax: 5000),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBudget extends StatelessWidget {
  final String label;
  final String range;
  final bool selected;
  final VoidCallback onTap;

  const _QuickBudget({
    required this.label,
    required this.range,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppTheme.primaryTeal.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: selected ? AppTheme.primaryTeal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primaryTeal : null,
              ),
            ),
            Text(
              range,
              style: TextStyle(fontSize: 11, color: AppTheme.subtitleGrey),
            ),
          ],
        ),
      ),
    );
  }
}
