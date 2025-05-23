// lib/features/plants/screens/add_plant/steps/confirmation_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add_plant_wizard.dart';
// import '../../../../../data/models/plant.dart'; // Entfernt, da PlantStatus etc. über AddPlantData verfügbar sein sollten

class ConfirmationStep extends ConsumerWidget {
  const ConfirmationStep({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unbekannt';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatHarvestEstimate(int? days, DateTime? baseDate) {
    if (days == null || baseDate == null) return 'Keine Schätzung';

    final harvestDate = baseDate.add(Duration(days: days));
    final weeksFloat = days / 7;
    final weeks = weeksFloat.round();

    return '$days Tage (ca. $weeks Wochen) → ${_formatDate(harvestDate)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);

    DateTime? harvestBaseDate;
    if (data.seedDate != null) {
      harvestBaseDate = data.seedDate;
    } else if (data.germinationDate != null) {
      harvestBaseDate = data.germinationDate;
    } else if (data.plantedDate != null) {
      harvestBaseDate = data.plantedDate;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Überprüfe deine Angaben und erstelle deine Pflanze.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: data.photoPath != null &&
                                  File(data.photoPath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(data.photoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.eco_rounded,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.name ?? '--',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                data.plantType?.displayName ?? '--',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              if (data.initialStatus != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data.initialStatus!.displayName,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      'Sorte/Genetik',
                      data.strain ?? '--',
                      Icons.local_florist_rounded,
                    ),
                    if (data.breeder != null && data.breeder!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Hersteller',
                        data.breeder!,
                        Icons.business_rounded,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Wichtige Daten',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.seedDate != null) ...[
                      _buildDetailRow(
                        'Aussaatdatum',
                        _formatDate(data.seedDate),
                        Icons.eco_rounded,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (data.germinationDate != null) ...[
                      _buildDetailRow(
                        'Keimungsdatum',
                        _formatDate(data.germinationDate),
                        Icons.spa_rounded,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildDetailRow(
                      'Pflanzdatum',
                      _formatDate(data.plantedDate),
                      Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Medium',
                      data.medium?.displayName ?? '--',
                      Icons.grass_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Standort',
                      data.location?.displayName ?? '--',
                      Icons.location_on_rounded,
                    ),
                    if (data.estimatedHarvestDays != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Ernteschätzung',
                        _formatHarvestEstimate(
                            data.estimatedHarvestDays, harvestBaseDate),
                        Icons.agriculture_rounded,
                      ),
                    ],
                    if (data.notes != null && data.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notizen',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data.notes!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (data.estimatedHarvestDays != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture_rounded,
                        color: Colors.green.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ernteschätzung aktiviert',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Du erhältst eine Benachrichtigung, wenn die geschätzte Erntezeit näher rückt.',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 14,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_rounded,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR-Code inklusive',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deine Pflanze erhält automatisch einen einzigartigen QR-Code für schnellen Zugriff.',
                          style: TextStyle(
                            color: Colors.purple.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
