// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../main.dart';
import '../../widgets/meal_card.dart';
import '../../widgets/metabolic_state_banner.dart';
import '../../widgets/bottom_nav.dart';
import '../insights/insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth  = context.read<AuthProvider>();
    final meals = context.read<MealProvider>();
    if (auth.email != null) {
      await meals.loadFullDayMeals(auth.email!);
    }
  }

  Future<void> _goToCheckin() async {
    await Navigator.pushNamed(context, '/checkin');
    if (mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedTab == 0 ? null : _buildAppBar(),
      body: _buildCurrentTab(),          // ← direct switch, no IndexedStack
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:  return _buildHomeTab();
      case 1:  return _buildMealsBody();
      case 2:  return const InsightsScreen();
      case 3:  return _buildProfileBody();
      default: return _buildHomeTab();
    }
  }

  AppBar _buildAppBar() {
    switch (_selectedTab) {
      case 1:
        return AppBar(
          title: const Text("Today's Meals"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        );
      case 2:
        return AppBar(
          title: const Text('Health Insights'),
          automaticallyImplyLeading: false,
        );
      case 3:
        return AppBar(
          title: const Text('Profile'),
          automaticallyImplyLeading: false,
        );
      default:
        return AppBar(automaticallyImplyLeading: false);
    }
  }

  Widget _buildHomeTab() {
    final auth    = context.watch<AuthProvider>();
    final meals   = context.watch<MealProvider>();
    final checkin = context.watch<CheckinProvider>();
    final today   = DateFormat('EEEE, d MMM').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Good ${_greeting()}, ${auth.name?.split(' ').first ?? ''}!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(today,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/chatbot'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!checkin.checkinDone) _buildCheckinCard(),
                  if (checkin.checkinDone && checkin.lastCheckin != null)
                    MetabolicStateBanner(result: checkin.lastCheckin!),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Meals",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (meals.isLoading)
                        const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppTheme.primary, size: 20),
                          onPressed: _loadData,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (meals.isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator()))
                  else if (meals.error != null)
                    _buildErrorCard(meals.error!)
                  else if (meals.mealSlots.isEmpty)
                    checkin.checkinDone
                        ? _buildNoMealsAfterCheckin()
                        : _buildEmptyMeals()
                  else
                    ...meals.mealSlots
                        .map((slot) => MealSlotCard(slot: slot))
                        .toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsBody() {
    final meals   = context.watch<MealProvider>();
    final checkin = context.watch<CheckinProvider>();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: meals.isLoading
          ? const Center(child: CircularProgressIndicator())
          : meals.error != null
              ? _buildErrorCard(meals.error!)
              : meals.mealSlots.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_menu,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              checkin.checkinDone
                                  ? 'No meals available.\nTap refresh to try again.'
                                  : 'Complete your morning\ncheck-in to see meals.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 20),
                            if (!checkin.checkinDone)
                              ElevatedButton(
                                onPressed: _goToCheckin,
                                child: const Text('Start Check-in'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload Meals'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (checkin.lastCheckin != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Text(checkin.lastCheckin!.emoji,
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        checkin.lastCheckin!.metabolicState
                                            .replaceAll('_', ' ')
                                            .split(' ')
                                            .map((w) =>
                                                w[0].toUpperCase() +
                                                w.substring(1))
                                            .join(' '),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      Text(
                                        checkin.lastCheckin!.stateLabel,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...meals.mealSlots
                            .map((slot) => MealSlotCard(slot: slot))
                            .toList(),
                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildProfileBody() {
    final auth = context.watch<AuthProvider>();
    return SingleChildScrollView(          // ← wrapped in scroll so it works on small screens
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            child: Text(
              (auth.name?.isNotEmpty == true)
                  ? auth.name![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(auth.name ?? '',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(auth.email ?? '',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Weekly Reports'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('AI Chatbot'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/chatbot'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Logout',
                style: TextStyle(color: AppTheme.danger)),
            onTap: () async {
              context.read<CheckinProvider>().reset();
              context.read<MealProvider>().reset();
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinCard() {
    return GestureDetector(
      onTap: _goToCheckin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF0F6E56)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Morning Check-in 🌅',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                      'Complete your check-in to get personalised meal recommendations',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMealsAfterCheckin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu,
                size: 60, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Generating your personalised meals...',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('This may take a moment on first load',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Meals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.favorite_outline,            'label': 'PPG Scan',    'route': '/ppg'},
      {'icon': Icons.water_drop_outlined,         'label': 'Hydration',   'route': '/hydration'},
      {'icon': Icons.medical_information_outlined, 'label': 'Health Tips', 'route': '/health-tips'},
      {'icon': Icons.bar_chart_outlined,          'label': 'Reports',     'route': '/reports'},
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, a['route'] as String),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(a['icon'] as IconData,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(height: 6),
              Text(a['label'] as String,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.error_outline, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Could not load meals',
                style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(error,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
                'Complete your morning check-in\nto get meal recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goToCheckin,
              child: const Text('Start Check-in'),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}