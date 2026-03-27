/// Health screen — common health problems with expandable cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../provider/health_provider.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  static const _conditions = [
    {
      'name': 'PCOS',
      'icon': Icons.healing_rounded,
      'color': Color(0xFFE91E63),
      'description':
          'Polycystic Ovary Syndrome affects hormonal balance. A low-GI diet rich in anti-inflammatory foods helps manage symptoms.',
      'tips': [
        'Eat whole grains, leafy greens, and lean proteins',
        'Avoid refined carbs and sugary foods',
        'Include omega-3 rich foods like walnuts and flaxseeds',
        'Stay hydrated with at least 2-3 litres of water',
        'Regular moderate exercise helps with insulin resistance',
      ],
    },
    {
      'name': 'Diabetes',
      'icon': Icons.bloodtype_rounded,
      'color': Color(0xFF2196F3),
      'description':
          'Diabetes requires careful management of blood sugar levels through diet, exercise, and monitoring.',
      'tips': [
        'Monitor carbohydrate intake and choose complex carbs',
        'Eat at regular intervals to maintain stable blood sugar',
        'Include fiber-rich foods in every meal',
        'Limit processed and sugary foods',
        'Regular physical activity improves insulin sensitivity',
      ],
    },
    {
      'name': 'Thyroid',
      'icon': Icons.air_rounded,
      'color': Color(0xFF9C27B0),
      'description':
          'Thyroid disorders affect metabolism. Proper nutrition supports thyroid hormone production and overall energy.',
      'tips': [
        'Ensure adequate iodine, selenium, and zinc intake',
        'Eat Brazil nuts, seafood, and dairy products',
        'Limit goitrogenic foods (raw cruciferous vegetables) if hypothyroid',
        'Avoid excessive soy consumption',
        'Maintain stable meal times for consistent energy',
      ],
    },
    {
      'name': 'Blood Pressure',
      'icon': Icons.monitor_heart_rounded,
      'color': Color(0xFFF44336),
      'description':
          'High blood pressure increases risk of heart disease and stroke. The DASH diet is proven to help control BP.',
      'tips': [
        'Reduce sodium intake to less than 2,300mg/day',
        'Eat potassium-rich foods: bananas, spinach, sweet potatoes',
        'Include magnesium from nuts, seeds, and legumes',
        'Limit alcohol and caffeine consumption',
        'Maintain a healthy weight through balanced diet and exercise',
      ],
    },
    {
      'name': 'Digestive Issues',
      'icon': Icons.local_hospital_rounded,
      'color': Color(0xFF4CAF50),
      'description':
          'Common digestive problems like IBS, acid reflux, and bloating can be managed through dietary changes.',
      'tips': [
        'Eat slowly and chew food thoroughly',
        'Include probiotic-rich foods: yogurt, buttermilk',
        'Increase fiber intake gradually',
        'Stay hydrated throughout the day',
        'Identify and avoid trigger foods',
      ],
    },
    {
      'name': 'Anemia',
      'icon': Icons.opacity_rounded,
      'color': Color(0xFFFF5722),
      'description':
          'Anemia results from insufficient red blood cells. Iron-rich foods and vitamin C help improve iron absorption.',
      'tips': [
        'Eat iron-rich foods: spinach, lentils, red meat',
        'Pair iron-rich foods with vitamin C sources',
        'Avoid tea/coffee with meals (inhibits iron absorption)',
        'Include folate-rich foods: beans, citrus fruits',
        'Consider iron-fortified cereals and grains',
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedSet = ref.watch(healthExpandedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Conditions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conditions.length,
        itemBuilder: (context, i) {
          final cond = _conditions[i];
          final name = cond['name'] as String;
          final isExpanded = expandedSet.contains(name);

          return _HealthConditionCard(
            name: name,
            icon: cond['icon'] as IconData,
            color: cond['color'] as Color,
            description: cond['description'] as String,
            tips: (cond['tips'] as List).cast<String>(),
            isExpanded: isExpanded,
            onToggle: () =>
                ref.read(healthExpandedProvider.notifier).toggle(name),
          );
        },
      ),
    );
  }
}

class _HealthConditionCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> tips;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _HealthConditionCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.tips,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.subtitleGrey,
                ),
              ),
            ],
          ),

          // ── Expandable content ─────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.subtitleGrey,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tips:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.subtitleGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
