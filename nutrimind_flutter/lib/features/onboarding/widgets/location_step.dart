/// Step 7: Location Access — permission UI screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../provider/onboarding_provider.dart';

class LocationStep extends ConsumerWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider).data;
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Illustration ─────────────────────────────────
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 56,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Enable Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'We use your location to suggest weather-based meals and find nearby healthy food options.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.subtitleGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Mock location permission grant
              notifier.updateData((d) => d.copyWith(locationGranted: true));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location access granted ✓'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            icon: Icon(
              data.locationGranted
                  ? Icons.check_circle_rounded
                  : Icons.my_location_rounded,
            ),
            label: Text(
              data.locationGranted ? 'Location Enabled' : 'Allow Location Access',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          if (!data.locationGranted) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // User declines — we continue without location
              },
              child: Text(
                'Maybe later',
                style: TextStyle(color: AppTheme.subtitleGrey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
