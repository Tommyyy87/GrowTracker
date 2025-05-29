// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../plants/controllers/plant_controller.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/attention_cards.dart';
import '../widgets/current_grows_section.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/quick_actions_fab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final statsAsync = ref.watch(plantStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plantsProvider);
          ref.invalidate(plantStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // FIXED: App Bar mit korrekter Höhe
            SliverAppBar(
              expandedHeight: 160, // Reduced from 120 to prevent overflow
              floating: true,
              snap: true,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false, // Remove back button
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Benachrichtigungen kommen bald!')),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Profil'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Einstellungen'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Export'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Abmelden', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.gradientEnd,
                      ],
                    ),
                  ),
                  child: const SafeArea(
                    child: DashboardHeader(),
                  ),
                ),
              ),
            ),

            // Dashboard Content
            plantsAsync.when(
              data: (plants) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),

                    // Statistiken - Jetzt viel übersichtlicher
                    statsAsync.when(
                      data: (stats) => DashboardStats(stats: stats),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Attention Cards - Nur wenn nötig
                    AttentionCards(plants: plants),

                    const SizedBox(height: 24),

                    // IMPROVED: Current Grows Section mit besserer Darstellung
                    if (plants.isNotEmpty) ...[
                      CurrentGrowsSection(
                        plants: plants,
                        isGridView: _isGridView,
                        onViewToggle: () =>
                            setState(() => _isGridView = !_isGridView),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // IMPROVED: Empty State wenn keine Pflanzen
                    if (plants.isEmpty) ...[
                      _buildEmptyDashboard(context),
                      const SizedBox(height: 24),
                    ],

                    // Recent Activity - Nur wenn Pflanzen vorhanden
                    if (plants.isNotEmpty) ...[
                      const RecentActivitySection(),
                      const SizedBox(height: 24),
                    ],

                    // Bottom Padding für FAB
                    const SizedBox(height: 100),
                  ]),
                );
              },
              loading: () => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Pflanzen laden...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fehler beim Laden',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bitte versuche es erneut.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(plantsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // FIXED: FAB mit korrektem Background
      floatingActionButton: const QuickActionsFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // NEW: Verbesserter Empty State
  Widget _buildEmptyDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Illustration
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 50,
                    color: AppColors.primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Willkommen bei GrowTracker!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Beginne jetzt mit der Dokumentation deiner ersten Pflanze und verfolge jeden Schritt deines Grows.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.goNamed('add_plant'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Erste Pflanze hinzufügen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Tips Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Tipp',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mit GrowTracker kannst du alle Pflanzenarten verwalten - von Cannabis über Tomaten bis hin zu Zimmerpflanzen. Jede Pflanze erhält automatisch eine eindeutige ID und einen QR-Code.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // FIXED: Navigate to profile screen instead of showing snackbar
        context.goNamed('profile');
        break;
      case 'settings':
        // FIXED: Navigate to settings screen instead of showing snackbar
        context.goNamed('settings');
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export-Feature kommt bald!')),
        );
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await SupabaseService.client.auth.signOut();
              if (mounted) {
                context.goNamed('welcome');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Abmelden', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
