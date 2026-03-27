/// Onboarding screen — multi-step PageView with progress indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../provider/onboarding_provider.dart';
import '../widgets/identity_step.dart';
import '../widgets/goals_step.dart';
import '../widgets/diet_step.dart';
import '../widgets/allergies_step.dart';
import '../widgets/water_goal_step.dart';
import '../widgets/activity_step.dart';
import '../widgets/location_step.dart';
import '../widgets/budget_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);

    if (state.currentStep == state.totalSteps - 1) {
      // Final step — submit & navigate
      _submit();
    } else {
      notifier.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);

    if (state.currentStep > 0) {
      notifier.prevStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.submit();
    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        // Even if signup fails (e.g. user already exists), go home
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isLast = state.currentStep == state.totalSteps - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      state.currentStep > 0
                          ? IconButton(
                              onPressed: _prev,
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                              ),
                            )
                          : const SizedBox(width: 48),
                      Text(
                        'Step ${state.currentStep + 1} of ${state.totalSteps}',
                        style: TextStyle(
                          color: AppTheme.subtitleGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _next,
                        child: Text(
                          isLast ? '' : 'Skip',
                          style: TextStyle(color: AppTheme.subtitleGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Linear progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step pages ───────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  IdentityStep(),
                  GoalsStep(),
                  DietStep(),
                  AllergiesStep(),
                  WaterGoalStep(),
                  ActivityStep(),
                  LocationStep(),
                  BudgetStep(),
                ],
              ),
            ),

            // ── Next / Finish button ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GradientButton(
                text: isLast ? 'Get Started' : 'Continue',
                isLoading: state.isSubmitting,
                onPressed: _next,
                icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
