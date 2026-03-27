// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  int _age = 25;
  String _gender = 'female';
  double _height = 160;
  double _weight = 60;
  String _goal = 'maintain';
  String _dietType = 'veg';
  String _activity = 'moderate';
  String _budget = 'mid';
  String _city = 'Pune';
  List<String> _conditions = [];
  List<String> _allergies = [];

  final List<String> _conditionOptions = ['pcos', 'diabetes', 'thyroid', 'bp'];
  final List<String> _allergyOptions = ['peanuts', 'gluten', 'dairy', 'soy'];

  void _next() {
    if (_currentPage < 3) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final ok = await auth.completeSignup(
      age: _age,
      gender: _gender,
      heightCm: _height,
      weightKg: _weight,
      goal: _goal,
      dietType: _dietType,
      activityLevel: _activity,
      budget: _budget,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to save profile'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? AppTheme.primary
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _next,
                      child: Text(
                          _currentPage < 3 ? 'Continue' : 'Start My Journey'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This helps us personalise your nutrition plan',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _label('Age: $_age'),
          Slider(
            value: _age.toDouble(), min: 15, max: 80, divisions: 65,
            onChanged: (v) => setState(() => _age = v.round()),
          ),
          const SizedBox(height: 16),
          _label('Gender'),
          _chipGroup(
            ['female', 'male', 'other'],
            ['Female', 'Male', 'Other'],
            _gender, (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          _label('Height: ${_height.round()} cm'),
          Slider(
            value: _height, min: 140, max: 210,
            onChanged: (v) => setState(() => _height = v),
          ),
          _label('Weight: ${_weight.round()} kg'),
          Slider(
            value: _weight, min: 35, max: 150,
            onChanged: (v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 16),
          _label('City'),
          TextFormField(
            initialValue: _city,
            decoration: const InputDecoration(
                hintText: 'e.g. Pune',
                prefixIcon: Icon(Icons.location_on_outlined)),
            onChanged: (v) => _city = v,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your health goals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('We adapt every meal to your specific goal',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _label('Goal'),
          _chipGroup(
            ['lose', 'maintain', 'gain'],
            ['Lose weight', 'Maintain', 'Gain muscle'],
            _goal, (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 24),
          _label('Diet Type'),
          _chipGroup(
            ['veg', 'non-veg', 'vegan', 'jain'],
            ['Vegetarian', 'Non-veg', 'Vegan', 'Jain'],
            _dietType, (v) => setState(() => _dietType = v),
          ),
          const SizedBox(height: 24),
          _label('Activity Level'),
          _chipGroup(
            ['sedentary', 'moderate', 'active'],
            ['Sedentary', 'Moderate', 'Active'],
            _activity, (v) => setState(() => _activity = v),
          ),
          const SizedBox(height: 24),
          _label('Budget'),
          _chipGroup(
            ['low', 'mid', 'high'],
            ['Low (₹0-200)', 'Mid (₹200-500)', 'High (₹500+)'],
            _budget, (v) => setState(() => _budget = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Health conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select any that apply — your meals will be adjusted',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ..._conditionOptions.map((c) => CheckboxListTile(
                title: Text(c.toUpperCase()),
                value: _conditions.contains(c),
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() =>
                    v == true ? _conditions.add(c) : _conditions.remove(c)),
              )),
          const SizedBox(height: 24),
          const Text('Allergies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._allergyOptions.map((a) => CheckboxListTile(
                title: Text(a[0].toUpperCase() + a.substring(1)),
                value: _allergies.contains(a),
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() =>
                    v == true ? _allergies.add(a) : _allergies.remove(a)),
              )),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.secondary, size: 80),
          const SizedBox(height: 24),
          const Text("You're all set! 🎉",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              'NutriSync AI will now analyse your body signals every morning and serve personalised meals before you even feel hungry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _summaryRow('Goal', _goal),
          _summaryRow('Diet', _dietType),
          _summaryRow('Activity', _activity),
          _summaryRow('Budget', _budget),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      );

  Widget _chipGroup(List<String> values, List<String> labels,
      String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(values.length, (i) {
        final isSelected = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.white,
              border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(labels[i],
                style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
        );
      }),
    );
  }
}