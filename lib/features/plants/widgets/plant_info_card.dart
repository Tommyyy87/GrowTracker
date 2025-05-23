// lib/features/plants/widgets/plant_info_card.dart
import 'package:flutter/material.dart';

import '../../../data/models/plant.dart';

class PlantInfoCard extends StatelessWidget {
  final Plant plant;

  const PlantInfoCard({
    super.key,
    required this.plant,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.strain, // Behält strain, da dies Sortenname ist
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plant.breeder != null)
                        Text(
                          plant.breeder!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(int.parse(plant.statusColor.substring(1),
                                radix: 16) +
                            0xFF000000)
                        .withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plant.status.displayName,
                    style: TextStyle(
                      color: Color(
                          int.parse(plant.statusColor.substring(1), radix: 16) +
                              0xFF000000),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (plant.estimatedHarvestDate != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: plant.daysUntilHarvest != null &&
                          plant.daysUntilHarvest! <= 7
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: plant.daysUntilHarvest != null &&
                            plant.daysUntilHarvest! <= 7
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      plant.daysUntilHarvest != null &&
                              plant.daysUntilHarvest! <= 7
                          ? Icons.warning_rounded
                          : Icons.agriculture_rounded,
                      color: plant.daysUntilHarvest != null &&
                              plant.daysUntilHarvest! <= 7
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ernteschätzung',
                            style: TextStyle(
                              fontSize: 12,
                              color: plant.daysUntilHarvest != null &&
                                      plant.daysUntilHarvest! <= 7
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            plant.harvestEstimateText,
                            style: TextStyle(
                              fontSize: 14,
                              color: plant.daysUntilHarvest != null &&
                                      plant.daysUntilHarvest! <= 7
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plant.estimatedHarvestDate != null)
                            Text(
                              'ca. ${_formatDate(plant.estimatedHarvestDate!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: plant.daysUntilHarvest != null &&
                                        plant.daysUntilHarvest! <= 7
                                    ? Colors.orange.shade600
                                    : Colors.green.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Column(
              children: [
                _buildInfoRow(
                  'ID',
                  plant.displayId,
                  Icons.tag_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Pflanzenart',
                  plant.plantType.displayName,
                  Icons.category_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Alter',
                  '${plant.ageInDays} Tage',
                  Icons.schedule_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  plant.primaryDisplayDateLabel, // Korrigiert
                  _formatDate(plant.primaryDisplayDate), // Korrigiert
                  Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Medium',
                  plant.medium.displayName,
                  Icons.grass_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Standort',
                  plant.location.displayName,
                  Icons.location_on_rounded,
                ),
                if (plant.seedDate != null &&
                    plant.primaryDisplayDate != plant.seedDate) ...[ // Korrigiert
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Aussaat',
                    _formatDate(plant.seedDate!),
                    Icons.eco_rounded,
                  ),
                ],
                if (plant.germinationDate != null &&
                    plant.primaryDisplayDate != plant.germinationDate) ...[ // Korrigiert
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Keimung',
                    _formatDate(plant.germinationDate!),
                    Icons.local_florist_rounded,
                  ),
                ],
                // Überlegung: plantedDate ist jetzt das Hauptdatum. Anzeigen, wenn es von seed/germ abweicht?
                // Aktuell ist primaryDisplayDate das früheste von seed, germination oder plantedDate.
                // Wenn plantedDate explizit als "Start der Dokumentation" angezeigt werden soll, wenn es von seed/germ abweicht:
                if (plant.plantedDate != plant.primaryDisplayDate) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Gepflanzt / Doku-Start', // Angepasst
                    _formatDate(plant.plantedDate), // Verwendet plantedDate
                    Icons.description_rounded,
                  ),
                ],
              ],
            ),
            if (plant.status.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plant.status.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}