// lib/features/dashboard/widgets/recent_activity_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/plant.dart';
import '../../plants/controllers/plant_controller.dart';

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Letzte Aktivitäten',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Was ist seit deinem letzten Besuch passiert',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Activity Content
        plantsAsync.when(
          data: (plants) {
            final activities = _generateRecentActivities(plants);

            if (activities.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildActivitiesList(activities);
          },
          loading: () => _buildLoadingState(),
          error: (_, __) => _buildErrorState(context),
        ),
      ],
    );
  }

  List<ActivityItem> _generateRecentActivities(List<Plant> plants) {
    final activities = <ActivityItem>[];
    final now = DateTime.now();

    // Sortiere Pflanzen nach Update-Datum
    final sortedPlants = List<Plant>.from(plants)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final plant in sortedPlants.take(10)) {
      final daysSinceUpdate = now.difference(plant.updatedAt).inDays;

      // Nur Aktivitäten der letzten 30 Tage
      if (daysSinceUpdate <= 30) {
        activities.add(ActivityItem(
          plant: plant,
          type: _determineActivityType(plant),
          timestamp: plant.updatedAt,
          description: _generateActivityDescription(plant),
        ));
      }
    }

    // Füge weitere simulierte Aktivitäten hinzu (für Demo-Zwecke)
    _addSimulatedActivities(activities, plants);

    // Sortiere nach Datum (neueste zuerst)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(6).toList(); // Maximal 6 Aktivitäten
  }

  ActivityType _determineActivityType(Plant plant) {
    final daysSinceCreation = DateTime.now().difference(plant.createdAt).inDays;

    if (daysSinceCreation == 0) {
      return ActivityType.plantAdded;
    } else if (plant.status == PlantStatus.harvest) {
      return ActivityType.harvest;
    } else if (plant.status == PlantStatus.flowering) {
      return ActivityType.statusUpdate;
    } else {
      return ActivityType.generalUpdate;
    }
  }

  String _generateActivityDescription(Plant plant) {
    final type = _determineActivityType(plant);

    switch (type) {
      case ActivityType.plantAdded:
        return 'Neue Pflanze "${plant.name}" hinzugefügt';
      case ActivityType.harvest:
        return 'Pflanze "${plant.name}" ist erntereif!';
      case ActivityType.statusUpdate:
        return 'Status von "${plant.name}" auf ${plant.status.displayName} geändert';
      case ActivityType.photoAdded:
        return 'Neues Foto für "${plant.name}" hinzugefügt';
      case ActivityType.noteAdded:
        return 'Notiz für "${plant.name}" aktualisiert';
      case ActivityType.generalUpdate:
        return 'Informationen zu "${plant.name}" aktualisiert';
    }
  }

  void _addSimulatedActivities(
      List<ActivityItem> activities, List<Plant> plants) {
    if (plants.isNotEmpty && activities.length < 3) {
      final now = DateTime.now();

      // Simuliere einige Aktivitäten für Demo-Zwecke
      activities.add(ActivityItem(
        plant: plants.first,
        type: ActivityType.photoAdded,
        timestamp: now.subtract(const Duration(hours: 6)),
        description: 'Wachstumsfoto für "${plants.first.name}" hinzugefügt',
      ));

      if (plants.length > 1) {
        activities.add(ActivityItem(
          plant: plants[1],
          type: ActivityType.noteAdded,
          timestamp: now.subtract(const Duration(days: 1)),
          description: 'Pflegenotizen für "${plants[1].name}" aktualisiert',
        ));
      }
    }
  }

  Widget _buildActivitiesList(List<ActivityItem> activities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 56,
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _ActivityTile(
            activity: activity,
            onTap: () => context.goNamed(
              'plant_detail',
              pathParameters: {'plantId': activity.plant.id},
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Aktivitäten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beginne mit der Dokumentation deiner Pflanzen und verfolge hier alle Änderungen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aktivitäten konnten nicht geladen werden.',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getActivityColor().withAlpha(51), // 0.2 * 255
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getActivityIcon(),
          color: _getActivityColor(),
          size: 20,
        ),
      ),
      title: Text(
        activity.description,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatTimestamp(activity.timestamp),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey.shade400,
      ),
    );
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.plantAdded:
        return Colors.green;
      case ActivityType.harvest:
        return Colors.orange;
      case ActivityType.statusUpdate:
        return Colors.blue;
      case ActivityType.photoAdded:
        return Colors.purple;
      case ActivityType.noteAdded:
        return Colors.teal;
      case ActivityType.generalUpdate:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.plantAdded:
        return Icons.add_circle_outline;
      case ActivityType.harvest:
        return Icons.agriculture;
      case ActivityType.statusUpdate:
        return Icons.update;
      case ActivityType.photoAdded:
        return Icons.camera_alt;
      case ActivityType.noteAdded:
        return Icons.note_add;
      case ActivityType.generalUpdate:
        return Icons.edit;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inHours < 1) {
      return 'Vor ${difference.inMinutes} Min';
    } else if (difference.inDays < 1) {
      return 'Vor ${difference.inHours} Std';
    } else if (difference.inDays < 7) {
      return 'Vor ${difference.inDays} Tag${difference.inDays == 1 ? '' : 'en'}';
    } else {
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
  }
}

enum ActivityType {
  plantAdded,
  harvest,
  statusUpdate,
  photoAdded,
  noteAdded,
  generalUpdate,
}

class ActivityItem {
  final Plant plant;
  final ActivityType type;
  final DateTime timestamp;
  final String description;

  ActivityItem({
    required this.plant,
    required this.type,
    required this.timestamp,
    required this.description,
  });
}
