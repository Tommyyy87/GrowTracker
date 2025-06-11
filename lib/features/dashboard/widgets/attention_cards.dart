import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/plant.dart';

class AttentionCards extends StatelessWidget {
  final List<Plant> plants;

  const AttentionCards({
    super.key,
    required this.plants,
  });

  List<Plant> _getAttentionPlants() {
    final attentionPlants = <Plant>[];

    for (final plant in plants) {
      // Pflanzen die Ernte-bereit oder überfällig sind
      if (plant.daysUntilHarvest != null) {
        if (plant.daysUntilHarvest! <= 0) {
          attentionPlants.add(plant); // Überfällig
        } else if (plant.daysUntilHarvest! <= 7 &&
            plant.status != PlantStatus.harvest &&
            plant.status != PlantStatus.drying &&
            plant.status != PlantStatus.completed) {
          attentionPlants.add(plant); // Bald erntereif
        }
      }

      // Pflanzen die sehr lange im gleichen Status sind
      final daysSinceUpdate = DateTime.now().difference(plant.updatedAt).inDays;
      if (daysSinceUpdate > 14 &&
          plant.status != PlantStatus.completed &&
          plant.status != PlantStatus.drying) {
        if (!attentionPlants.contains(plant)) {
          attentionPlants.add(plant);
        }
      }
    }

    // Sortiere nach Priorität (überfällig zuerst)
    attentionPlants.sort((a, b) {
      final aDaysUntil = a.daysUntilHarvest ?? 999;
      final bDaysUntil = b.daysUntilHarvest ?? 999;

      // Überfällige zuerst
      if (aDaysUntil < 0 && bDaysUntil >= 0) return -1;
      if (bDaysUntil < 0 && aDaysUntil >= 0) return 1;

      // Dann nach Tagen bis Ernte
      return aDaysUntil.compareTo(bDaysUntil);
    });

    return attentionPlants.take(3).toList(); // Max 3 Cards
  }

  AttentionType _getAttentionType(Plant plant) {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return AttentionType.overdue;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return AttentionType.harvestReady;
    } else {
      final daysSinceUpdate = DateTime.now().difference(plant.updatedAt).inDays;
      if (daysSinceUpdate > 14) {
        return AttentionType.needsUpdate;
      }
    }
    return AttentionType.harvestReady; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final attentionPlants = _getAttentionPlants();

    if (attentionPlants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.priority_high,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benötigt Aufmerksamkeit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${attentionPlants.length} Pflanze${attentionPlants.length == 1 ? '' : 'n'} braucht${attentionPlants.length == 1 ? '' : 'en'} deine Hilfe',
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
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: attentionPlants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final plant = attentionPlants[index];
              final attentionType = _getAttentionType(plant);

              return _AttentionCard(
                plant: plant,
                attentionType: attentionType,
                onTap: () => context.pushNamed('plant_detail',
                    pathParameters: {'plantId': plant.id}),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum AttentionType {
  overdue,
  harvestReady,
  needsUpdate,
}

class _AttentionCard extends StatelessWidget {
  final Plant plant;
  final AttentionType attentionType;
  final VoidCallback onTap;

  const _AttentionCard({
    required this.plant,
    required this.attentionType,
    required this.onTap,
  });

  Color get _backgroundColor {
    switch (attentionType) {
      case AttentionType.overdue:
        return Colors.red.shade50;
      case AttentionType.harvestReady:
        return Colors.orange.shade50;
      case AttentionType.needsUpdate:
        return Colors.blue.shade50;
    }
  }

  Color get _borderColor {
    switch (attentionType) {
      case AttentionType.overdue:
        return Colors.red.shade200;
      case AttentionType.harvestReady:
        return Colors.orange.shade200;
      case AttentionType.needsUpdate:
        return Colors.blue.shade200;
    }
  }

  Color get _iconColor {
    switch (attentionType) {
      case AttentionType.overdue:
        return Colors.red.shade600;
      case AttentionType.harvestReady:
        return Colors.orange.shade600;
      case AttentionType.needsUpdate:
        return Colors.blue.shade600;
    }
  }

  IconData get _icon {
    switch (attentionType) {
      case AttentionType.overdue:
        return Icons.error_outline;
      case AttentionType.harvestReady:
        return Icons.agriculture;
      case AttentionType.needsUpdate:
        return Icons.update;
    }
  }

  String get _message {
    switch (attentionType) {
      case AttentionType.overdue:
        final days = plant.daysUntilHarvest?.abs() ?? 0;
        return 'Überfällig seit $days Tag${days == 1 ? '' : 'en'}';
      case AttentionType.harvestReady:
        final days = plant.daysUntilHarvest ?? 0;
        if (days == 0) return 'Heute erntereif!';
        return 'Ernte in $days Tag${days == 1 ? '' : 'en'}';
      case AttentionType.needsUpdate:
        final daysSince = DateTime.now().difference(plant.updatedAt).inDays;
        return 'Kein Update seit $daysSince Tagen';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _iconColor.withAlpha(51), // 0.2 * 255
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _icon,
                    color: _iconColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              style: TextStyle(
                color: _iconColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${plant.strain} • ${plant.ageInDays} Tage alt',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(plant.statusColor.substring(1),
                                radix: 16) +
                            0xFF000000)
                        .withAlpha(51), // 0.2 * 255
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plant.status.displayName,
                    style: TextStyle(
                      color: Color(
                          int.parse(plant.statusColor.substring(1), radix: 16) +
                              0xFF000000),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
