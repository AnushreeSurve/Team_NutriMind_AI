/// Home Dashboard screen — greeting, summary cards, quick actions,
/// meal recommendation, weekly chart preview.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../auth/provider/auth_provider.dart';
import '../../meals/provider/meals_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../provider/home_provider.dart';
import '../model/home_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'User';
    final email = authState.user?.email ?? '';
    final waterMl = ref.watch(waterIntakeProvider);
    final fullDayState = ref.watch(fullDayProvider(email));
    final weatherData = fullDayState.valueOrNull;
    final googleFitOn = ref.watch(googleFitProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          color: AppTheme.subtitleGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  if (weatherData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            weatherData.weatherCondition == 'rainy' ? Icons.water_drop :
                            weatherData.weatherCondition == 'cold' ? Icons.ac_unit :
                            weatherData.temperatureC > 30 ? Icons.wb_sunny : Icons.cloud,
                            size: 16,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${weatherData.temperatureC.round()}°C',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Daily summary cards ──────────────────────────
              _DailySummaryCards(email: email, waterMl: waterMl),
              const SizedBox(height: 24),

              // ── Health Data Section ──────────────────────────
              const SectionHeader(title: 'Health Data'),
              if (googleFitOn) ...[
                const _GoogleFitDashboard(),
              ] else ...[
                const _PpgDashboard(),
              ],
              const SizedBox(height: 24),

              // ── Quick actions ────────────────────────────────
              const SectionHeader(title: 'Quick Actions'),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.monitor_heart_rounded,
                      label: 'Scan Heart Rate',
                      gradient: AppTheme.accentGradient,
                      onTap: () => context.push('/ppg'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.restaurant_rounded,
                      label: 'Log Meal',
                      gradient: AppTheme.primaryGradient,
                      onTap: () => context.go('/meals'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Today's meal recommendation ──────────────────
              const SectionHeader(
                title: "Today's Meals",
                actionText: 'See All',
              ),
              _MealRecommendationSection(email: email),
              const SizedBox(height: 24),

              // ── Weekly report preview ────────────────────────
              const SectionHeader(title: 'Weekly Report'),
              _WeeklyChartPreview(),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

// ── Daily summary cards (Calories, Water, Activity) ───────────
class _DailySummaryCards extends ConsumerWidget {
  final String email;
  final int waterMl;

  const _DailySummaryCards({required this.email, required this.waterMl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider(email));

    return summary.when(
      loading: () => LoadingShimmer.list(count: 1, itemHeight: 120),
      error: (_, __) => _buildCards(context, DailySummary.mock),
      data: (data) => _buildCards(context, data),
    );
  }

  Widget _buildCards(BuildContext context, DailySummary data) {
    final calPct = data.calorieTarget > 0
        ? (data.caloriesConsumed / data.calorieTarget).clamp(0, 1).toDouble()
        : 0.0;
    final waterPct = (waterMl / 2000).clamp(0, 1).toDouble();

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            title: 'Calories',
            value: '${data.caloriesConsumed}',
            subtitle: 'of ${data.calorieTarget} kcal',
            progress: calPct,
            progressColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.water_drop_rounded,
            iconColor: AppTheme.accentBlue,
            title: 'Water',
            value: '${(waterMl / 1000).toStringAsFixed(1)}L',
            subtitle: 'of 2.0L goal',
            progress: waterPct,
            progressColor: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.directions_run_rounded,
            iconColor: AppTheme.successGreen,
            title: 'Activity',
            value: 'Moderate',
            subtitle: 'Today',
            progress: 0.6,
            progressColor: AppTheme.successGreen,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final Color progressColor;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppTheme.subtitleGrey),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
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
    );
  }
}

// ── Meal recommendation section ───────────────────────────────
class _MealRecommendationSection extends ConsumerWidget {
  final String email;

  const _MealRecommendationSection({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMeals = ref.watch(selectedMealsProvider);

    if (selectedMeals.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 40, color: AppTheme.subtitleGrey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No meals selected for today',
                style: TextStyle(color: AppTheme.subtitleGrey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/meals'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryTeal),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Pick Meals', style: TextStyle(color: AppTheme.primaryTeal)),
              ),
            ],
          ),
        ),
      );
    }
    
    final List<MealRecommendation> mappedMeals = selectedMeals.values.map((m) => MealRecommendation(
      name: m.name,
      calories: m.calories,
      slot: m.slot,
      dietType: m.dietType,
      tags: m.tags,
    )).toList();

    return _buildList(mappedMeals);
  }

  Widget _buildList(List<MealRecommendation> meals) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final meal = meals[i];
          return _MealCard(meal: meal);
        },
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealRecommendation meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/meal-detail/${Uri.encodeComponent(meal.name)}'),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  size: 20,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.slot.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              meal.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${meal.calories} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.subtitleGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly chart preview ──────────────────────────────────────
class _WeeklyChartPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 2500,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: [
              _bar(0, 1800),
              _bar(1, 2100),
              _bar(2, 1500),
              _bar(3, 1900),
              _bar(4, 2200),
              _bar(5, 1700),
              _bar(6, 1250),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryTeal, AppTheme.primaryTealLight],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }
}

// ── Google Fit & PPG Dashboards ───────────────────────────────
class _GoogleFitDashboard extends StatelessWidget {
  const _GoogleFitDashboard();

  @override
  Widget build(BuildContext context) {
    // TODO: Add Google Fit API credentials in .env file
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _HealthDataCard(icon: Icons.nightlight_round, color: Colors.indigo, title: 'Sleep', value: '7h 20m'),
              const SizedBox(height: 12),
              _HealthDataCard(icon: Icons.favorite_rounded, color: Colors.red, title: 'HRV', value: '45 ms'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _HealthDataCard(icon: Icons.directions_walk_rounded, color: Colors.teal, title: 'Steps', value: '8,432'),
              const SizedBox(height: 12),
              _HealthDataCard(icon: Icons.local_fire_department_rounded, color: Colors.orange, title: 'Cals', value: '1,840'),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthDataCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _HealthDataCard({required this.icon, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PpgDashboard extends StatelessWidget {
  const _PpgDashboard();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heart Rate (PPG)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('72 BPM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Normal', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
