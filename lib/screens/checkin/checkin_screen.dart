// lib/screens/checkin/checkin_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../main.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int _step = 0;
  int _heartRate = 72;
  String _sleepQuality = 'okay';
  String _energyLevel = 'normal';
  String _mood = 'neutral';

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final auth    = context.read<AuthProvider>();
    final checkin = context.read<CheckinProvider>();
    final today   = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final ok = await checkin.submitCheckin(
      userId:       auth.userId ?? '',
      date:         today,
      heartRate:    _heartRate,
      sleepQuality: _sleepQuality,
      energyLevel:  _energyLevel,
      mood:         _mood,
    );

    if (!mounted) return;
    if (ok) {
      _showResultSheet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(checkin.error ?? 'Check-in failed'),
              backgroundColor: AppTheme.danger));
    }
  }

  void _showResultSheet() {
    final result = context.read<CheckinProvider>().lastCheckin!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Today\'s Mode',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              result.metabolicState
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w[0].toUpperCase() + w.substring(1))
                  .join(' '),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(result.stateLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('See My Meal Plan'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(4, (i) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? AppTheme.primary
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: [
                _buildPPGStep(),
                _buildSleepStep(),
                _buildEnergyStep(),
                _buildMoodStep(),
              ][_step],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: context.watch<CheckinProvider>().isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _next,
                    child: Text(_step < 3 ? 'Next' : 'Submit Check-in'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPPGStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Heart Rate Scan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tap "Scan" to measure your heart rate using your camera',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
        Center(
          child: GestureDetector(
            onTap: () async {
              final result =
                  await Navigator.pushNamed(context, '/ppg') as int?;
              if (result != null) setState(() => _heartRate = result);
            },
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.danger.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.danger, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite,
                      color: AppTheme.danger, size: 48),
                  const SizedBox(height: 8),
                  Text('$_heartRate BPM',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Tap to scan',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Or adjust manually:',
            style: TextStyle(color: AppTheme.textSecondary)),
        Slider(
          value: _heartRate.toDouble(),
          min: 45, max: 120,
          divisions: 75,
          label: '$_heartRate BPM',
          onChanged: (v) => setState(() => _heartRate = v.round()),
        ),
      ],
    );
  }

  Widget _buildSleepStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How did you sleep?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your sleep quality directly affects your meal recommendations',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 40),
        ...[
          ('bad', '😴', 'Poor sleep', 'Woke up multiple times'),
          ('okay', '😐', 'Okay sleep', 'Slept but not deeply'),
          ('good', '😊', 'Great sleep', 'Slept well and deeply'),
        ].map((item) => _bigOptionCard(
              value: item.$1,
              emoji: item.$2,
              title: item.$3,
              subtitle: item.$4,
              selected: _sleepQuality,
              onTap: () => setState(() => _sleepQuality = item.$1),
            )),
      ],
    );
  }

  Widget _buildEnergyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Energy level?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('How energetic do you feel right now?',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 40),
        ...[
          ('tired', '🥱', 'Tired', 'Low energy, sluggish'),
          ('normal', '😌', 'Normal', 'Feeling okay'),
          ('energetic', '⚡', 'Energetic', 'Ready to go!'),
        ].map((item) => _bigOptionCard(
              value: item.$1,
              emoji: item.$2,
              title: item.$3,
              subtitle: item.$4,
              selected: _energyLevel,
              onTap: () => setState(() => _energyLevel = item.$1),
            )),
      ],
    );
  }

  Widget _buildMoodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How are you feeling?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your mood helps us suggest the right comfort foods',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 40),
        ...[
          ('stressed', '😰', 'Stressed', 'Feeling anxious or overwhelmed'),
          ('neutral', '😐', 'Neutral', 'Just a regular day'),
          ('calm', '😊', 'Calm', 'Relaxed and at peace'),
        ].map((item) => _bigOptionCard(
              value: item.$1,
              emoji: item.$2,
              title: item.$3,
              subtitle: item.$4,
              selected: _mood,
              onTap: () => setState(() => _mood = item.$1),
            )),
      ],
    );
  }

  Widget _bigOptionCard({
    required String value,
    required String emoji,
    required String title,
    required String subtitle,
    required String selected,
    required VoidCallback onTap,
  }) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
