// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/achievement_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _availableAchievements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAchievements();
    });
  }

  Future<void> _loadAchievements() async {
    final controller = ref.read(profileControllerProvider.notifier);
    final unlocked = await controller.getUnlockedAchievements();
    final available = await controller.getAvailableAchievements();

    if (mounted) {
      setState(() {
        _unlockedAchievements = unlocked;
        _availableAchievements = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final rankingAsync = ref.watch(userRankingProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mein Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () => context.goNamed('settings'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Statistiken aktualisieren'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.manage_accounts, size: 20),
                    SizedBox(width: 8),
                    Text('Account verwalten'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileControllerProvider);
          ref.invalidate(userRankingProvider);
          await _loadAchievements();
        },
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text('Profil konnte nicht geladen werden'),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  rankingAsync.when(
                    data: (ranking) => ProfileHeader(
                      profile: profile,
                      ranking: ranking,
                      isEditable: true,
                    ),
                    loading: () => ProfileHeader(
                      profile: profile,
                      isEditable: true,
                    ),
                    error: (_, __) => ProfileHeader(
                      profile: profile,
                      isEditable: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Social Proof Messages
                  FutureBuilder<Map<String, String>>(
                    future: ref
                        .read(profileControllerProvider.notifier)
                        .getSocialProofTexts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Column(
                          children: [
                            ...snapshot.data!.entries.map((entry) =>
                                _buildSocialProofCard(entry.key, entry.value)),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Statistics Card
                  rankingAsync.when(
                    data: (ranking) => ProfileStatsCard(
                      profile: profile,
                      ranking: ranking,
                    ),
                    loading: () => ProfileStatsCard(profile: profile),
                    error: (_, __) => ProfileStatsCard(profile: profile),
                  ),

                  const SizedBox(height: 20),

                  // Achievements Card
                  AchievementCard(
                    unlockedAchievements: _unlockedAchievements,
                    availableAchievements: _availableAchievements,
                    onViewAll: () => _showAllAchievements(),
                  ),

                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildQuickActionsCard(),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Profil wird geladen...'),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fehler beim Laden des Profils',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(profileControllerProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialProofCard(String type, String message) {
    Color color;
    IconData icon;

    switch (type) {
      case 'ranking':
        color = Colors.purple;
        icon = Icons.leaderboard;
        break;
      case 'streak':
        color = Colors.red;
        icon = Icons.local_fire_department;
        break;
      case 'achievements':
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 'level':
        color = Colors.blue;
        icon = Icons.stars;
        break;
      default:
        color = AppColors.primaryColor;
        icon = Icons.celebration;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(
                    alpha: 0.8), // FIXED: Ersetzt shade700 mit withValues
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schnellaktionen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Profil bearbeiten',
                    Icons.edit,
                    AppColors.primaryColor,
                    () => context.goNamed('edit_profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Einstellungen',
                    Icons.settings,
                    Colors.blue,
                    () => context.goNamed('settings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Account verwalten',
                    Icons.manage_accounts,
                    Colors.orange,
                    () => context.goNamed('account_management'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Alle Erfolge',
                    Icons.emoji_events,
                    Colors.amber,
                    () => _showAllAchievements(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refreshStatistics();
        break;
      case 'account':
        context.goNamed('account_management');
        break;
    }
  }

  Future<void> _refreshStatistics() async {
    final controller = ref.read(profileControllerProvider.notifier);
    final success = await controller.updateStatistics();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Statistiken erfolgreich aktualisiert!'
              : 'Fehler beim Aktualisieren der Statistiken'),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (success) {
        await _loadAchievements();
      }
    }
  }

  void _showAllAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllAchievementsSheet(
        unlockedAchievements: _unlockedAchievements,
        availableAchievements: _availableAchievements,
      ),
    );
  }
}

class _AllAchievementsSheet extends StatelessWidget {
  final List<Achievement> unlockedAchievements;
  final List<Achievement> availableAchievements;

  const _AllAchievementsSheet({
    required this.unlockedAchievements,
    required this.availableAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final allAchievements = [...unlockedAchievements, ...availableAchievements];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alle Erfolge',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${unlockedAchievements.length} von ${allAchievements.length} freigeschaltet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Achievements List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = allAchievements[index];
                final isUnlocked = unlockedAchievements.contains(achievement);

                return AchievementCard(
                  unlockedAchievements: isUnlocked ? [achievement] : [],
                  availableAchievements: isUnlocked ? [] : [achievement],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
