/// Tracker screen — hydration tracker with progress ring and weekly chart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../home/provider/home_provider.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterMl = ref.watch(waterIntakeProvider);
    final goalMl = 2000;
    final percent = (waterMl / goalMl).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Progress ring ──────────────────────────────────
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 100,
                    lineWidth: 14,
                    percent: percent,
                    animation: true,
                    animationDuration: 800,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: AppTheme.accentBlue,
                    backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.12),
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.water_drop_rounded,
                          size: 32,
                          color: AppTheme.accentBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(waterMl / 1000).toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'of ${(goalMl / 1000).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subtitleGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    percent >= 1.0
                        ? '🎉 Goal reached! Great job!'
                        : '${((1 - percent) * goalMl).round()}ml to go',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          percent >= 1.0 ? AppTheme.successGreen : AppTheme.subtitleGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Add water buttons ──────────────────────────────
            Row(
              children: [
                _AddWaterButton(
                  amount: 150,
                  label: '150ml',
                  icon: Icons.local_drink_rounded,
                  onTap: () => ref.read(waterIntakeProvider.notifier).addWater(150),
                ),
                const SizedBox(width: 10),
                _AddWaterButton(
                  amount: 250,
                  label: '250ml',
                  icon: Icons.water_drop_outlined,
                  onTap: () => ref.read(waterIntakeProvider.notifier).addWater(250),
                ),
                const SizedBox(width: 10),
                _AddWaterButton(
                  amount: 500,
                  label: '500ml',
                  icon: Icons.water_drop_rounded,
                  onTap: () => ref.read(waterIntakeProvider.notifier).addWater(500),
                ),
                const SizedBox(width: 10),
                _AddWaterButton(
                  amount: 1000,
                  label: '1L',
                  icon: Icons.waves_rounded,
                  onTap: () => ref.read(waterIntakeProvider.notifier).addWater(1000),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Reset button
            TextButton.icon(
              onPressed: () => ref.read(waterIntakeProvider.notifier).reset(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.subtitleGrey),
            ),
            const SizedBox(height: 24),

            // ── Weekly report charts ───────────────────────────
            _WeeklyChart(
              title: 'Hydration',
              unit: 'L',
              maxY: 3000,
              horizontalInterval: 500,
              spots: [
                const FlSpot(0, 1800),
                const FlSpot(1, 2200),
                const FlSpot(2, 1500),
                const FlSpot(3, 2000),
                const FlSpot(4, 1700),
                const FlSpot(5, 2400),
                FlSpot(6, waterMl.toDouble()),
              ],
              goal: 2000,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: 16),
            _WeeklyChart(
              title: 'HRV (Heart Rate Variability)',
              unit: 'ms',
              maxY: 80,
              horizontalInterval: 20,
              spots: [
                const FlSpot(0, 42),
                const FlSpot(1, 45),
                const FlSpot(2, 48),
                const FlSpot(3, 44),
                const FlSpot(4, 50),
                const FlSpot(5, 46),
                const FlSpot(6, 52),
              ],
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            _WeeklyChart(
              title: 'Protein Intake',
              unit: 'g',
              maxY: 150,
              horizontalInterval: 50,
              spots: [
                const FlSpot(0, 50),
                const FlSpot(1, 65),
                const FlSpot(2, 70),
                const FlSpot(3, 60),
                const FlSpot(4, 80),
                const FlSpot(5, 75),
                const FlSpot(6, 85),
              ],
              goal: 100,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final String title;
  final String unit;
  final double maxY;
  final double horizontalInterval;
  final List<FlSpot> spots;
  final double? goal;
  final Color color;

  const _WeeklyChart({
    required this.title,
    required this.unit,
    required this.maxY,
    required this.horizontalInterval,
    required this.spots,
    this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) {
                        if (value % horizontalInterval == 0) {
                          String label;
                          if (unit == 'L') {
                            label = '${(value / 1000).toStringAsFixed(1)}$unit';
                          } else {
                            label = '${value.toInt()}$unit';
                          }
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.subtitleGrey,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: color,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                  if (goal != null)
                    LineChartBarData(
                      spots: List.generate(
                        7,
                        (i) => FlSpot(i.toDouble(), goal!),
                      ),
                      isCurved: false,
                      color: AppTheme.subtitleGrey.withValues(alpha: 0.5),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                      dashArray: [6, 4],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddWaterButton extends StatelessWidget {
  final int amount;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AddWaterButton({
    required this.amount,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.accentBlue, size: 20),
              const SizedBox(height: 6),
              Text(
                '+$label',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
