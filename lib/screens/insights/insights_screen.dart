// lib/screens/insights/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/checkin_provider.dart';
import '../../main.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkin = context.watch<CheckinProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header card ──────────────────────────────────────────────
          _HeaderCard(checkin: checkin),
          const SizedBox(height: 20),

          // ── Today's vitals from PPG/checkin ──────────────────────────
          const Text('Today\'s Vitals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _VitalsGrid(checkin: checkin),
          const SizedBox(height: 24),

          // ── Heart Rate trend (from checkins) ─────────────────────────
          const Text('Heart Rate Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('From your morning check-ins',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _HRChart(checkin: checkin),
          const SizedBox(height: 24),

          // ── HRV gauge ────────────────────────────────────────────────
          const Text('HRV Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _HRVCard(checkin: checkin),
          const SizedBox(height: 24),

          // ── Metabolic state card ──────────────────────────────────────
          if (checkin.checkinDone && checkin.lastCheckin != null) ...[
            const Text('Metabolic State',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _MetabolicCard(checkin: checkin),
          ],
        ],
      ),
    );
  }
}

// ── Header card ────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final CheckinProvider checkin;
  const _HeaderCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final done = checkin.checkinDone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.monitor_heart,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Check-in Complete ✓' : 'No Check-in Today Yet',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Vitals recorded from your PPG scan'
                      : 'Complete morning check-in to see vitals',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ── Vitals grid ────────────────────────────────────────────────────────────
class _VitalsGrid extends StatelessWidget {
  final CheckinProvider checkin;
  const _VitalsGrid({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final hr      = checkin.lastCheckinHeartRate ?? 0;
    final hrv     = hr > 0 ? (1000 / hr * 10).round() : 0;
    final state   = checkin.lastCheckin?.metabolicState ?? '--';
    final calAdj  = checkin.lastCheckin?.calorieAdjustment ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _VitalCard(
          icon: Icons.favorite,
          label: 'Heart Rate',
          value: hr > 0 ? '$hr' : '--',
          unit: 'BPM',
          color: Colors.redAccent,
          target: '60–100',
          status: hr > 0
              ? (hr >= 60 && hr <= 100 ? 'Normal ✓' : 'Check needed')
              : 'No data',
          statusOk: hr >= 60 && hr <= 100,
        ),
        _VitalCard(
          icon: Icons.show_chart,
          label: 'HRV',
          value: hrv > 0 ? '$hrv' : '--',
          unit: 'ms',
          color: Colors.blueAccent,
          target: '> 50 ms',
          status: hrv > 0 ? (hrv >= 50 ? 'Good ✓' : 'Low') : 'No data',
          statusOk: hrv >= 50,
        ),
        _VitalCard(
          icon: Icons.local_fire_department_outlined,
          label: 'Calorie Adjust',
          value: checkin.checkinDone
              ? (calAdj >= 0 ? '+$calAdj' : '$calAdj')
              : '--',
          unit: 'kcal',
          color: Colors.orange,
          target: 'Based on state',
          status: checkin.checkinDone ? 'Applied ✓' : 'No data',
          statusOk: checkin.checkinDone,
        ),
        _VitalCard(
          icon: Icons.psychology_outlined,
          label: 'Metabolic',
          value: state != '--'
              ? state
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w[0].toUpperCase() + w.substring(1))
                  .join('\n')
              : '--',
          unit: '',
          color: AppTheme.primary,
          target: 'Post-absorptive',
          status: checkin.checkinDone ? 'Recorded ✓' : 'No data',
          statusOk: checkin.checkinDone,
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final String   unit;
  final Color    color;
  final String   target;
  final String   status;
  final bool     statusOk;

  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.target,
    required this.status,
    required this.statusOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusOk && value != '--'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 9,
                      color: statusOk && value != '--'
                          ? Colors.green
                          : Colors.grey[600],
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: value == '--'
                              ? Colors.grey
                              : AppTheme.textPrimary),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: '  $unit',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── HR Chart ───────────────────────────────────────────────────────────────
class _HRChart extends StatelessWidget {
  final CheckinProvider checkin;
  const _HRChart({required this.checkin});

  @override
  Widget build(BuildContext context) {
    // Build 7-day labels; only today has real data from checkin
    final today    = DateTime.now();
    final labels   = List.generate(7, (i) =>
        DateFormat('EEE').format(today.subtract(Duration(days: 6 - i))));
    final hr       = checkin.lastCheckinHeartRate ?? 0;

    // Today is index 6; rest are 0 (no data yet — shown as gaps)
    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      if (i == 6 && hr > 0) {
        spots.add(FlSpot(i.toDouble(), hr.toDouble()));
      }
      // Other days: no spot = gap in line (future: load from history API)
    }

    final hasData = spots.isNotEmpty;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: hasData
          ? LineChart(LineChartData(
              minY: 40, maxY: 120,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(labels[idx],
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary));
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.redAccent,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.redAccent,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.redAccent.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 44, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text(
                    'Complete your morning check-in\nto start building your HR trend',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── HRV Card ───────────────────────────────────────────────────────────────
class _HRVCard extends StatelessWidget {
  final CheckinProvider checkin;
  const _HRVCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final hr  = checkin.lastCheckinHeartRate ?? 0;
    final hrv = hr > 0 ? (1000 / hr * 10).round() : 0;

    String label;
    Color  color;
    double pct;

    if (hrv == 0) {
      label = 'No data — complete check-in';
      color = Colors.grey;
      pct   = 0;
    } else if (hrv >= 70) {
      label = 'Excellent recovery';
      color = Colors.green;
      pct   = 1.0;
    } else if (hrv >= 50) {
      label = 'Good — normal range';
      color = Colors.lightGreen;
      pct   = 0.7;
    } else if (hrv >= 30) {
      label = 'Moderate — some fatigue';
      color = Colors.orange;
      pct   = 0.45;
    } else {
      label = 'Low — consider rest';
      color = Colors.redAccent;
      pct   = 0.2;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hrv > 0 ? '$hrv ms' : '-- ms',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: hrv > 0 ? color : Colors.grey),
              ),
              Icon(Icons.favorite_border, color: color, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
              'HRV measures your nervous system recovery. Higher = better.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Metabolic card ─────────────────────────────────────────────────────────
class _MetabolicCard extends StatelessWidget {
  final CheckinProvider checkin;
  const _MetabolicCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final result = checkin.lastCheckin!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(result.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
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
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(result.stateLabel,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Meals personalised for this state',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}