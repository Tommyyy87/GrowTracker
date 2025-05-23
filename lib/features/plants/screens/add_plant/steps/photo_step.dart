// lib/features/plants/screens/add_plant/steps/photo_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/plant_controller.dart';
import '../add_plant_wizard.dart';

class PhotoStep extends ConsumerWidget {
  const PhotoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);
    final controller = ref.read(plantControllerProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Beschreibung
            Text(
              'Füge ein Foto deiner Pflanze hinzu (optional).',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Foto-Vorschau oder Platzhalter
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child:
                    data.photoPath != null && File(data.photoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(data.photoPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Kein Foto ausgewählt',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 32),

            // Foto-Aktionen
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final photoPath = await controller.takePlantPhoto();
                      if (photoPath != null) {
                        ref
                            .read(addPlantDataProvider.notifier)
                            .update((currentData) => AddPlantData(
                                  photoPath: photoPath,
                                  name: currentData.name,
                                  plantType: currentData.plantType,
                                  initialStatus: currentData.initialStatus,
                                  strain: currentData.strain,
                                  breeder: currentData.breeder,
                                  seedDate: currentData.seedDate,
                                  germinationDate: currentData.germinationDate,
                                  plantedDate: currentData.plantedDate,
                                  medium: currentData.medium,
                                  location: currentData.location,
                                  estimatedHarvestDays:
                                      currentData.estimatedHarvestDays,
                                  notes: currentData.notes,
                                ));
                      }
                    },
                    icon: Icon(Icons.camera_alt_rounded,
                        color: theme.colorScheme.primary),
                    label: Text('Kamera',
                        style: TextStyle(color: theme.colorScheme.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      // foregroundColor: theme.colorScheme.primary, // Alternative globale Zuweisung
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final photoPath = await controller.pickPlantPhoto();
                      if (photoPath != null) {
                        ref
                            .read(addPlantDataProvider.notifier)
                            .update((currentData) => AddPlantData(
                                  photoPath: photoPath,
                                  name: currentData.name,
                                  plantType: currentData.plantType,
                                  initialStatus: currentData.initialStatus,
                                  strain: currentData.strain,
                                  breeder: currentData.breeder,
                                  seedDate: currentData.seedDate,
                                  germinationDate: currentData.germinationDate,
                                  plantedDate: currentData.plantedDate,
                                  medium: currentData.medium,
                                  location: currentData.location,
                                  estimatedHarvestDays:
                                      currentData.estimatedHarvestDays,
                                  notes: currentData.notes,
                                ));
                      }
                    },
                    icon: Icon(Icons.photo_library_rounded,
                        color: theme.colorScheme.primary),
                    label: Text('Galerie',
                        style: TextStyle(color: theme.colorScheme.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      // foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            if (data.photoPath != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref
                        .read(addPlantDataProvider.notifier)
                        .update((currentData) => AddPlantData(
                              photoPath: null, // Foto entfernen
                              name: currentData.name,
                              plantType: currentData.plantType,
                              initialStatus: currentData.initialStatus,
                              strain: currentData.strain,
                              breeder: currentData.breeder,
                              seedDate: currentData.seedDate,
                              germinationDate: currentData.germinationDate,
                              plantedDate: currentData.plantedDate,
                              medium: currentData.medium,
                              location: currentData.location,
                              estimatedHarvestDays:
                                  currentData.estimatedHarvestDays,
                              notes: currentData.notes,
                            ));
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Foto entfernen'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Informationsbox
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto-Tipp',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ein Foto hilft dir dabei, deine Pflanzen schnell zu identifizieren. Du kannst später jederzeit weitere Fotos hinzufügen.',
                          style: TextStyle(
                            color: Colors.orange.shade600,
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

            // Platzhalter-Hinweis
            if (data.photoPath == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kein Problem! Wenn du jetzt kein Foto hinzufügst, wird automatisch ein Platzhalter-Bild verwendet.',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
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
}
