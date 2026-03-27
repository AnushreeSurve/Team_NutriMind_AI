import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/checkin_provider.dart';

import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/checkin/checkin_screen.dart';
import 'screens/meals/meal_detail_screen.dart';
import 'screens/meals/meal_compare_screen.dart';
import 'screens/ppg/ppg_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/hydration/hydration_screen.dart';
import 'screens/health/health_tips_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriSyncApp());
}

class NutriSyncApp extends StatelessWidget {
  const NutriSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
      ],
      child: MaterialApp(
        title: 'NutriSync AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash':      (_) => const SplashScreen(),
          '/login':       (_) => const LoginScreen(),
          '/signup':      (_) => const SignupScreen(),
          '/onboarding':  (_) => const OnboardingScreen(),
          '/home':        (_) => const HomeScreen(),
          '/checkin':     (_) => const CheckinScreen(),
          '/ppg':         (_) => const PPGScreen(),
          '/chatbot':     (_) => const ChatbotScreen(),
          '/reports':     (_) => const ReportsScreen(),
          '/hydration':   (_) => const HydrationScreen(),
          '/health-tips': (_) => const HealthTipsScreen(),
          '/meal-detail': (_) => const MealDetailScreen(),
          '/meal-compare':(_) => const MealCompareScreen(),
        },
      ),
    );
  }
}

class AppTheme {
  static const Color primary    = Color(0xFF1A73E8);
  static const Color secondary  = Color(0xFF0F6E56);
  static const Color accent     = Color(0xFFEF9F27);
  static const Color danger     = Color(0xFFE24B4A);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF555555);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: background,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F3F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
