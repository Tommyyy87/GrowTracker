// lib/features/plants/screens/add_plant/steps/confirmation_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import '../../../../../data/models/plant.dart'; // Wird nicht direkt für Enums benötigt hier
import '../add_plant_wizard.dart';

class ConfirmationStep extends ConsumerWidget {
  const ConfirmationStep({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Nicht gesetzt';
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bitte überprüfe deine Angaben:',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          if (data.photoPath != null && data.photoPath!.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(data.photoPath!),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (data.photoPath != null && data.photoPath!.isNotEmpty)
            const SizedBox(height: 20),
          _buildInfoRow('Name:', data.name ?? '-'),
          _buildInfoRow('Pflanzenart:', data.plantType?.displayName ?? '-'),
          _buildInfoRow('Status:', data.initialStatus?.displayName ?? '-'),
          _buildInfoRow('Sorte/Strain:', data.strain ?? '-'),
          if (data.breeder != null && data.breeder!.isNotEmpty)
            _buildInfoRow('Züchter:', data.breeder!),
          const Divider(height: 24),
          // Verwende effectiveDocumentationDate, da dies immer einen Wert hat
          _buildInfoRow(
              'Doku-Start:', _formatDate(data.effectiveDocumentationDate)),
          if (data.seedDate != null)
            _buildInfoRow('Aussaatdatum:', _formatDate(data.seedDate)),
          if (data.germinationDate != null)
            _buildInfoRow('Keimdatum:', _formatDate(data.germinationDate)),
          _buildInfoRow('Medium:', data.medium?.displayName ?? '-'),
          _buildInfoRow('Standort:', data.location?.displayName ?? '-'),
          if (data.estimatedHarvestDays != null &&
              data.estimatedHarvestDays! > 0)
            _buildInfoRow('Tage bis Ernte (geschätzt):',
                data.estimatedHarvestDays.toString()),
          if (data.notes != null && data.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Notizen:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(data.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
