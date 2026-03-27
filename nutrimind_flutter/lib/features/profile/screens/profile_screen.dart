/// Profile screen — user info, edit preferences, Google Fit toggle, logout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'User';
    final email = authState.user?.email ?? 'user@example.com';
    final googleFitOn = ref.watch(googleFitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── User avatar & info ───────────────────────────
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: AppTheme.subtitleGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate to edit profile
                    },
                    icon: const Icon(Icons.edit_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Settings section ─────────────────────────────
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Diet Preferences',
                    subtitle: 'Manage your diet type and allergies',
                    onTap: () => _showPreferencesSheet(context, ref),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.flag_rounded,
                    title: 'Goals',
                    subtitle: 'Update your health goals',
                    onTap: () => _showGoalsDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Budget',
                    subtitle: 'Adjust your daily meal budget',
                    onTap: () => _showBudgetDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Integrations section ─────────────────────────
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _ToggleTile(
                    icon: Icons.fitness_center_rounded,
                    title: 'Google Fit',
                    subtitle: 'Sync activity and health data',
                    value: googleFitOn,
                    onChanged: (_) =>
                        ref.read(googleFitProvider.notifier).toggle(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Meal reminders and hydration alerts',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── About section ────────────────────────────────
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About NutriMind AI',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final currentDiet = ref.watch(dietTypeProvider);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Preferences',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
    
                  // Diet type
                  const Text('Diet Type',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Veg', 'Non-veg', 'Vegan', 'Jain', 'Eggetarian']
                        .map((d) {
                          final selected = d.toLowerCase() == currentDiet.toLowerCase();
                          return ChoiceChip(
                            label: Text(
                              d,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            selectedColor: AppTheme.primaryTeal,
                            selected: selected,
                            onSelected: (_) {
                              ref.read(dietTypeProvider.notifier).setDietType(d.toLowerCase());
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),
    
                  // Allergies
                  const Text('Allergies',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Dairy', 'Nut', 'Gluten', 'Shellfish']
                        .map((a) {
                          final selected = false;
                          return FilterChip(
                            label: Text(
                              a,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            selectedColor: AppTheme.primaryTeal,
                            checkmarkColor: Colors.white,
                            selected: selected,
                            onSelected: (_) {},
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
    
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showGoalsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'e.g., Lose 5kg in 2 months',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.subtitleGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Save Goal'),
          ),
        ],
      )
    );
  }

  void _showBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Budget', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'e.g., 500',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.subtitleGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Save Budget'),
          ),
        ],
      )
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.subtitleGrey),
      onTap: onTap,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryTeal,
    );
  }
}
