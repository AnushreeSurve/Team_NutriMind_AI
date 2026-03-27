// lib/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../api/api.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _dashData;
  List<dynamic> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final dash   = await ApiService.getDashboard(auth.userId ?? '', dateStr);
      final alerts = await ApiService.getAlerts(auth.userId ?? '');
      setState(() {
        _dashData = dash;
        _alerts   = alerts['alerts'] ?? [];
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Could not load report data';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFE24B4A))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildProteinChart(),
                        const SizedBox(height: 24),
                        if (_alerts.isNotEmpty) _buildAlerts(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final weekly = _dashData?['weekly_summary'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('This Week', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _metricCard('🔥 Streak', '${weekly['streak_days'] ?? 0} days', const Color(0xFFEF9F27))),
          const SizedBox(width: 12),
          Expanded(child: _metricCard('⭐ Avg Rating', '${(weekly['avg_rating'] ?? 0.0).toStringAsFixed(1)}', const Color(0xFF0F6E56))),
        ]),
        const SizedBox(height: 12),
        if ((weekly['top_insight'] ?? '').toString().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF1A73E8), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(weekly['top_insight'], style: const TextStyle(fontSize: 14, height: 1.4))),
            ]),
          ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF555555), fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProteinChart() {
    final spots = [
      const FlSpot(0, 45), const FlSpot(1, 72), const FlSpot(2, 58),
      const FlSpot(3, 80), const FlSpot(4, 65), const FlSpot(5, 90), const FlSpot(6, 78),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Protein Intake (g) — Last 7 Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final idx = v.toInt();
                    if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                    return Text(days[idx], style: const TextStyle(fontSize: 12));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF1A73E8),
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: const Color(0xFF1A73E8).withOpacity(0.1)),
              ),
            ],
          )),
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutrition Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._alerts.map((a) {
          final sev = a['severity'] ?? 'low';
          final color = sev == 'high' ? const Color(0xFFE24B4A) : sev == 'medium' ? const Color(0xFFEF9F27) : const Color(0xFF0F6E56);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['message'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
              const SizedBox(height: 4),
              Text(a['suggestion'] ?? '', style: const TextStyle(color: Color(0xFF555555), fontSize: 13)),
            ]),
          );
        }),
      ],
    );
  }
}
