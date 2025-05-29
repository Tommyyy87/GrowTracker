// lib/features/profile/widgets/profile_stats_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_profile.dart';

class ProfileStatsCard extends StatelessWidget {
  final UserProfile profile;
  final Map<String, dynamic>? ranking;

  const ProfileStatsCard({
    super.key,
    required this.profile,
    this.ranking,
  });

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Meine Statistiken',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Main Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Gesamt Pflanzen',
                  profile.totalPlants.toString(),
                  Icons.eco,
                  Colors.green,
                ),
                _buildStatCard(
                  'Abgeschlossen',
                  profile.completedGrows.toString(),
                  Icons.check_circle,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Erfolgsrate',
                  '${profile.successRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Aktuelle Serie',
                  '${profile.currentStreak} Tage',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Expanded Stats
            Column(
              children: [
                _buildExpandedStat(
                  'Mitglied seit',
                  '${profile.memberForDays} Tage (${DateFormat('MMM yyyy').format(profile.createdAt)})',
                  Icons.calendar_today,
                ),
                _buildExpandedStat(
                  'Längste Serie',
                  '${profile.longestStreak} Tage',
                  Icons.military_tech,
                ),
                _buildExpandedStat(
                  'Lieblings-Pflanzenart',
                  profile.favoritePlantType,
                  Icons.favorite,
                ),
                if (profile.statistics['averageGrowDays'] != null &&
                    profile.statistics['averageGrowDays'] > 0)
                  _buildExpandedStat(
                    'Durchschnittliche Grow-Dauer',
                    '${(profile.statistics['averageGrowDays'] as double).toStringAsFixed(0)} Tage',
                    Icons.schedule,
                  ),
                if (profile.statistics['diversityScore'] != null)
                  _buildExpandedStat(
                    'Vielfalt-Score',
                    '${profile.statistics['diversityScore']} verschiedene Arten',
                    Icons.diversity_3,
                  ),
              ],
            ),

            // Ranking Info (Social Proof)
            if (ranking != null && ranking!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade50,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.leaderboard,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dein Ranking',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platz ${ranking!['rank'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.purple.shade800,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'von ${ranking!['totalUsers'] ?? 'N/A'} Growern',
                              style: TextStyle(
                                color: Colors.purple.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (ranking!['topPercent'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Top ${ranking!['percentile']}%',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedStat(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade600,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
