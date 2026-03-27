/// Step 4: Allergies — checkboxes + "Others" text input.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class AllergiesStep extends ConsumerStatefulWidget {
  const AllergiesStep({super.key});

  @override
  ConsumerState<AllergiesStep> createState() => _AllergiesStepState();
}

class _AllergiesStepState extends ConsumerState<AllergiesStep> {
  final _otherController = TextEditingController();

  static const _allergyOptions = ['Dairy', 'Nut', 'Gluten', 'Shellfish'];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider).data;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any food allergies?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll make sure to avoid these in your recommendations',
            style: TextStyle(color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 28),

          // ── Allergy checkboxes ──────────────────────────────
          ..._allergyOptions.map((allergy) {
            final selected = data.allergies.contains(allergy);
            return CheckboxListTile(
              title: Text(allergy),
              value: selected,
              activeColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (_) {
                final updated = List<String>.from(data.allergies);
                selected ? updated.remove(allergy) : updated.add(allergy);
                notifier.updateData((d) => d.copyWith(allergies: updated));
              },
            );
          }),
          const SizedBox(height: 16),

          // ── Others text input ──────────────────────────────
          Text(
            'Others',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherController,
            decoration: const InputDecoration(
              hintText: 'e.g. Soy, Sesame...',
            ),
            onChanged: (val) =>
                notifier.updateData((d) => d.copyWith(otherAllergy: val)),
          ),
        ],
      ),
    );
  }
}
