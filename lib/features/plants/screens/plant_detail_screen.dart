// lib/features/plants/screens/plant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant.dart';
import '../controllers/plant_controller.dart';
import '../widgets/status_timeline.dart';
import '../widgets/plant_info_card.dart';
import '../widgets/harvest_section.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    final harvestsAsync = ref.watch(plantHarvestsProvider(plantId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: plantAsync.when(
        data: (plant) {
          if (plant == null) {
            return const Center(
              child: Text('Pflanze nicht gefunden'),
            );
          }
          return _buildPlantDetail(context, ref, plant, harvestsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler beim Laden: $error'),
              TextButton(
                onPressed: () => ref.refresh(plantDetailProvider(plantId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantDetail(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
    AsyncValue<List<dynamic>> harvestsAsync,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar mit Foto
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('dashboard'),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(context, ref, plant, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Bearbeiten'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'harvest',
                  child: Row(
                    children: [
                      Icon(Icons.agriculture, size: 20),
                      SizedBox(width: 8),
                      Text('Ernte dokumentieren'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'qr',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, size: 20),
                      SizedBox(width: 8),
                      Text('QR-Code anzeigen'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Löschen', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              plant.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
              child: plant.photoUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image.network oder Image.file je nach URL
                        Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        Icons.eco_rounded,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status und Basis-Info
                PlantInfoCard(plant: plant),
                const SizedBox(height: 16),

                // Status Timeline
                StatusTimeline(plant: plant),
                const SizedBox(height: 16),

                // Ernte-Sektion
                harvestsAsync.when(
                  data: (harvests) => HarvestSection(
                    plant: plant,
                    harvests: harvests,
                  ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Notizen
                if (plant.notes != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Notizen',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            plant.notes!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Zusätzliche Aktionen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktionen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addPhoto(context, ref, plant),
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Foto hinzufügen'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addNote(context, ref, plant),
                                icon: const Icon(Icons.note_add),
                                label: const Text('Notiz hinzufügen'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, Plant plant, String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen (später implementieren)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bearbeiten-Funktion kommt bald!')),
        );
        break;
      case 'harvest':
        _showHarvestDialog(context, ref, plant);
        break;
      case 'qr':
        _showQRCode(context, plant);
        break;
      case 'delete':
        _showDeleteDialog(context, ref, plant);
        break;
    }
  }

  void _showHarvestDialog(BuildContext context, WidgetRef ref, Plant plant) {
    final freshWeightController = TextEditingController();
    final dryWeightController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ernte dokumentieren'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: freshWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Frischgewicht (g)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dryWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Trockengewicht (g) - optional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notizen - optional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final controller = ref.read(plantControllerProvider.notifier);
              final success = await controller.addHarvest(
                plantId: plant.id,
                freshWeight: double.tryParse(freshWeightController.text),
                dryWeight: double.tryParse(dryWeightController.text),
                harvestDate: DateTime.now(),
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Ernte dokumentiert!'
                        : 'Fehler beim Speichern'),
                    backgroundColor:
                        success ? AppColors.successColor : AppColors.errorColor,
                  ),
                );
                if (success) {
                  ref.invalidate(plantDetailProvider(plant.id));
                  ref.invalidate(plantHarvestsProvider(plant.id));
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showQRCode(BuildContext context, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR-Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.qr_code, size: 80),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              plant.displayId,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'QR-Code Generierung wird bald implementiert',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pflanze löschen'),
        content: Text(
            'Möchtest du "${plant.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final controller = ref.read(plantControllerProvider.notifier);
              final success = await controller.deletePlant(plant.id);

              if (context.mounted) {
                Navigator.of(context).pop();
                if (success) {
                  context.goNamed('dashboard');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pflanze wurde gelöscht'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fehler beim Löschen'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addPhoto(BuildContext context, WidgetRef ref, Plant plant) {
    // Photo hinzufügen - später implementieren
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto hinzufügen kommt bald!')),
    );
  }

  void _addNote(BuildContext context, WidgetRef ref, Plant plant) {
    final notesController = TextEditingController(text: plant.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notizen bearbeiten'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notizen',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final controller = ref.read(plantControllerProvider.notifier);
              final updatedPlant = plant.copyWith(
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
              );
              final success = await controller.updatePlant(updatedPlant);

              if (context.mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ref.invalidate(plantDetailProvider(plant.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notizen gespeichert!')),
                  );
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
