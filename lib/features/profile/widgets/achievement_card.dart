// lib/features/profile/widgets/achievement_card.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_profile.dart';

class AchievementCard extends StatelessWidget {
  final List<Achievement> unlockedAchievements;
  final List<Achievement> availableAchievements;
  final VoidCallback? onViewAll;

  const AchievementCard({
    super.key,
    required this.unlockedAchievements,
    required this.availableAchievements,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final totalAchievements = Achievement.allAchievements.length;
    final unlockedCount = unlockedAchievements.length;
    final progressPercentage =
        (unlockedCount / totalAchievements * 100).round();

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
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erfolge',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$unlockedCount von $totalAchievements freigeschaltet ($progressPercentage%)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Alle anzeigen'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: unlockedCount / totalAchievements,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 20),

            // Recent Achievements
            if (unlockedAchievements.isNotEmpty) ...[
              Text(
                'Neueste Erfolge',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...unlockedAchievements.take(3).map((achievement) =>
                  _buildAchievementTile(achievement, isUnlocked: true)),
            ],

            // Next Achievements to Unlock
            if (availableAchievements.isNotEmpty) ...[
              if (unlockedAchievements.isNotEmpty) const SizedBox(height: 16),
              Text(
                unlockedAchievements.isEmpty
                    ? 'Verfügbare Erfolge'
                    : 'Als nächstes freischalten',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...availableAchievements.take(3).map((achievement) =>
                  _buildAchievementTile(achievement, isUnlocked: false)),
            ],

            // Empty State
            if (unlockedAchievements.isEmpty &&
                availableAchievements.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Noch keine Erfolge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beginne mit deinem ersten Grow um Erfolge freizuschalten!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
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

  Widget _buildAchievementTile(Achievement achievement,
      {required bool isUnlocked}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (achievement.isRare
                ? Colors.purple.shade50
                : Colors.green.shade50)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? (achievement.isRare
                  ? Colors.purple.shade200
                  : Colors.green.shade200)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Achievement Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (achievement.isRare
                      ? Colors.purple.shade100
                      : Colors.green.shade100)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getIconData(achievement.iconName),
                  color: isUnlocked
                      ? (achievement.isRare
                          ? Colors.purple.shade600
                          : Colors.green.shade600)
                      : Colors.grey.shade400,
                  size: 24,
                ),
                if (achievement.isRare && isUnlocked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Achievement Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (achievement.isRare)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SELTEN',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: isUnlocked
                        ? Colors.grey.shade700
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? (achievement.isRare
                            ? Colors.purple.shade100
                            : Colors.green.shade100)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    achievement.category,
                    style: TextStyle(
                      color: isUnlocked
                          ? (achievement.isRare
                              ? Colors.purple.shade700
                              : Colors.green.shade700)
                          : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lock/Unlock Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUnlocked ? Icons.check : Icons.lock_outline,
              color: isUnlocked ? Colors.green.shade600 : Colors.grey.shade500,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'eco': Icons.eco,
      'nature': Icons.nature,
      'park': Icons.park,
      'agriculture': Icons.agriculture,
      'trending_up': Icons.trending_up,
      'workspace_premium': Icons.workspace_premium,
      'local_fire_department': Icons.local_fire_department,
      'whatshot': Icons.whatshot,
      'stars': Icons.stars,
      'diversity_3': Icons.diversity_3,
    };

    return iconMap[iconName] ?? Icons.emoji_events;
  }
}
