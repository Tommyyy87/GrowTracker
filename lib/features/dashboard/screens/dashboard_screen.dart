// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/features/dashboard/widgets/attention_cards.dart';
import 'package:grow_tracker/features/dashboard/widgets/current_grows_section.dart';
import 'package:grow_tracker/features/dashboard/widgets/dashboard_header.dart';
import 'package:grow_tracker/features/dashboard/widgets/dashboard_stats.dart';
import 'package:grow_tracker/features/dashboard/widgets/empty_dashboard.dart';
import 'package:grow_tracker/features/dashboard/widgets/quick_actions_fab.dart';
import 'package:grow_tracker/features/dashboard/widgets/recent_activity_section.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart';

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
            // ANGEPASST: SliverAppBar für den neuen Header
            SliverAppBar(
              expandedHeight: 200.0, // KORREKT: Höhe für neuen Header
              floating: false, // Wichtig für ein sanftes Scroll-Verhalten
              pinned: true, // Lässt den Header oben "kleben"
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: const FlexibleSpaceBar(
                background: DashboardHeader(),
              ),
            ),

            // Dashboard Content
            plantsAsync.when(
              data: (plants) {
                if (plants.isEmpty) {
                  // NEU: Verwendung des ausgelagerten EmptyDashboard Widgets
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: EmptyDashboard(),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),

                    // Statistiken
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

                    // Attention Cards
                    AttentionCards(plants: plants),

                    const SizedBox(height: 24),

                    // Current Grows Section
                    CurrentGrowsSection(
                      plants: plants,
                      isGridView: _isGridView,
                      onViewToggle: () =>
                          setState(() => _isGridView = !_isGridView),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    const RecentActivitySection(),
                    const SizedBox(height: 24),

                    // Bottom Padding für FAB
                    const SizedBox(height: 100),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('Fehler: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const QuickActionsFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
