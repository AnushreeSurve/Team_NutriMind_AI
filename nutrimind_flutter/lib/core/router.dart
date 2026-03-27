/// GoRouter configuration with all named routes.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/meals/screens/meals_screen.dart';
import '../features/meals/screens/meal_detail_screen.dart';
import '../features/health/screens/health_screen.dart';
import '../features/tracker/screens/tracker_screen.dart';
import '../features/ppg/screens/ppg_screen.dart';
import '../features/ppg/screens/ppg_result_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../main_shell.dart';

class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      // ── Auth flow ─────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Onboarding ────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Main App Shell (bottom nav) ───────────────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/meals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MealsScreen(),
            ),
          ),
          GoRoute(
            path: '/health',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HealthScreen(),
            ),
          ),
          GoRoute(
            path: '/tracker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TrackerScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Detail / standalone screens ───────────────────────
      GoRoute(
        path: '/meal-detail/:id',
        builder: (context, state) => MealDetailScreen(
          mealId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/ppg',
        builder: (context, state) => const PpgScreen(),
      ),
      GoRoute(
        path: '/ppg-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PpgResultScreen(data: extra);
        },
      ),
    ],
  );
}
