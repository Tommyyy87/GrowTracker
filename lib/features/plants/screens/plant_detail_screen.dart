// lib/features/plants/screens/plant_detail_screen.dart
import 'dart:io'; // Für File-Operationen (z.B. Image.file)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Für ImageSource
// Importiere intl für Datumsformatierung, falls noch nicht global verfügbar
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../controllers/plant_controller.dart';
import '../widgets/status_timeline.dart';
import '../widgets/plant_info_card.dart';
import '../widgets/harvest_section.dart';
import '../../../data/services/supabase_service.dart';

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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pflanze nicht gefunden.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.goNamed('dashboard'),
                      child: const Text('Zum Dashboard'),
                    )
                  ],
                ),
              );
            }
            // Übergabe des BuildContext an _buildPlantDetail
            return _buildPlantDetailContent(context, ref, plant, harvestsAsync);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            debugPrint('Error loading plant detail: $error\n$stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                      'Fehler beim Laden der Pflanzendetails: ${error.toString()}'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(plantDetailProvider(plantId)),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }),
    );
  }

  // Der BuildContext wird jetzt hier übergeben
  Widget _buildPlantDetailContent(
    BuildContext context, // BuildContext hier als Parameter
    WidgetRef ref,
    Plant plant,
    AsyncValue<List<Harvest>> harvestsAsync,
  ) {
    return CustomScrollView(
      slivers: [
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
              onSelected: (value) => _handleMenuAction(
                  context, ref, plant, value), // context hier verwenden
              itemBuilder: (popupContext) => [
                // popupContext für das Menü
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
            titlePadding:
                const EdgeInsets.only(left: 50, bottom: 16, right: 50),
            centerTitle: true,
            title: Text(
              plant.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  // Gradient für den gesamten Hintergrund der FlexibleSpaceBar
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Korrekte Position für colors
                    AppColors.primaryColor,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
              child: plant.photoUrl != null &&
                      plant.photoUrl!.startsWith('http')
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          plant.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image,
                                size: 80, color: Colors.white54),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                // Innerer Gradient über dem Bild
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                                stops: [0.4, 1.0]),
                          ),
                        ),
                      ],
                    )
                  : plant.photoUrl != null && File(plant.photoUrl!).existsSync()
                      ? Stack(fit: StackFit.expand, children: [
                          Image.file(
                            File(plant.photoUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.eco_rounded,
                                  size: 80, color: Colors.white54),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  // Innerer Gradient über dem Bild
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                  stops: [0.4, 1.0]),
                            ),
                          ),
                        ])
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlantInfoCard(plant: plant),
                const SizedBox(height: 16),
                StatusTimeline(plant: plant),
                const SizedBox(height: 16),
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
                  error: (_, __) => const Card(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Fehler beim Laden der Ernte-Daten.'),
                  )),
                ),
                const SizedBox(height: 16),
                if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 20, color: AppColors.primaryColor),
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
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                                onPressed: () => _addPhoto(context, ref,
                                    plant), // context hier verwenden
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Foto ändern'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addNote(context, ref,
                                    plant), // context hier verwenden
                                icon: const Icon(Icons.note_add),
                                label: const Text('Notiz ändern'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // context wird jetzt als Parameter übergeben
  void _handleMenuAction(
      BuildContext context, WidgetRef ref, Plant plant, String action) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bearbeiten-Funktion kommt bald!')),
        );
        break;
      case 'harvest':
        _showHarvestDialog(context, ref, plant); // context weitergeben
        break;
      case 'qr':
        _showQRCode(context, plant); // context weitergeben
        break;
      case 'delete':
        _showDeleteDialog(context, ref, plant); // context weitergeben
        break;
    }
  }

  void _showHarvestDialog(BuildContext context, WidgetRef ref, Plant plant) {
    final freshWeightController = TextEditingController();
    final dryWeightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedHarvestDate = DateTime.now();
    DateTime? selectedDryingCompletedDate;

    showDialog(
      context: context, // Dieser context ist der von _buildPlantDetailContent
      builder: (dialogContext) =>
          StatefulBuilder(builder: (innerDialogContext, setDialogState) {
        // innerDialogContext für den Dialog-State
        return AlertDialog(
          title: const Text('Ernte dokumentieren'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                      "Erntedatum: ${DateFormat('dd.MM.yyyy').format(selectedHarvestDate)}"), // intl Format
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: innerDialogContext, // innerDialogContext
                      initialDate: selectedHarvestDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != selectedHarvestDate) {
                      setDialogState(() {
                        selectedHarvestDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: freshWeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Frischgewicht (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(selectedDryingCompletedDate == null
                      ? "Trocknung abgeschlossen am (optional)"
                      : "Trocknung abgeschlossen: ${DateFormat('dd.MM.yyyy').format(selectedDryingCompletedDate!)}"), // intl Format und Null-Check
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: innerDialogContext, // innerDialogContext
                      initialDate:
                          selectedDryingCompletedDate ?? DateTime.now(),
                      firstDate: selectedHarvestDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null &&
                        picked != selectedDryingCompletedDate) {
                      setDialogState(() {
                        selectedDryingCompletedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dryWeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!context.mounted) return; // Äußerer context check

                final controller = ref.read(plantControllerProvider.notifier);
                final success = await controller.addHarvest(
                  plantId: plant.id,
                  freshWeight: double.tryParse(
                      freshWeightController.text.replaceAll(',', '.')),
                  dryWeight: double.tryParse(
                      dryWeightController.text.replaceAll(',', '.')),
                  harvestDate: selectedHarvestDate,
                  dryingCompletedDate: selectedDryingCompletedDate,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    // Äußerer context für ScaffoldMessenger
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Ernte dokumentiert!'
                            : 'Fehler beim Speichern der Ernte'),
                        backgroundColor: success
                            ? AppColors.successColor
                            : AppColors.errorColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      }),
    );
  }

  void _showQRCode(BuildContext context, Plant plant) {
    showDialog(
      context: context, // context von _buildPlantDetailContent
      builder: (dialogContext) => AlertDialog(
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
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  plant.qrCode,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              plant.displayId,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Plant plant) {
    showDialog(
      context: context, // context von _buildPlantDetailContent
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pflanze löschen'),
        content: Text(
            'Möchtest du "${plant.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!context.mounted) return; // Äußerer context check

              final controller = ref.read(plantControllerProvider.notifier);
              final success = await controller.deletePlant(plant.id);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  // Äußerer context für Navigation und ScaffoldMessenger
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addPhoto(BuildContext outerContext, WidgetRef ref, Plant plant) async {
    // outerContext als Parameter
    final source = await showModalBottomSheet<ImageSource>(
      context: outerContext, // outerContext hier verwenden
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(bc).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.of(bc).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    if (!outerContext.mounted) return; // Prüfe outerContext

    final controller = ref.read(plantControllerProvider.notifier);
    String? photoPath;

    if (source == ImageSource.camera) {
      photoPath = await controller.takePlantPhoto();
    } else {
      photoPath = await controller.pickPlantPhoto();
    }

    if (!outerContext.mounted) return;

    if (photoPath != null) {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            const SnackBar(
                content: Text('Benutzer nicht angemeldet.'),
                backgroundColor: AppColors.errorColor),
          );
        }
        return;
      }
      try {
        final uploadedPhotoUrl = await ref
            .read(plantRepositoryProvider)
            .uploadPlantPhoto(userId, plant.id, photoPath);
        final updatedPlant = plant.copyWith(photoUrl: () => uploadedPhotoUrl);
        await controller.updatePlant(updatedPlant);
        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            const SnackBar(content: Text('Foto erfolgreich hinzugefügt!')),
          );
        }
      } catch (e) {
        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            SnackBar(
                content: Text('Fehler beim Hochladen des Fotos: $e'),
                backgroundColor: AppColors.errorColor),
          );
        }
      }
    } else {
      if (outerContext.mounted) {
        ScaffoldMessenger.of(outerContext).showSnackBar(
          const SnackBar(content: Text('Kein Foto ausgewählt.')),
        );
      }
    }
  }

  void _addNote(BuildContext outerContext, WidgetRef ref, Plant plant) {
    // outerContext als Parameter
    final notesController = TextEditingController(text: plant.notes ?? '');
    showDialog(
      context: outerContext, // outerContext hier verwenden
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!outerContext.mounted) return; // outerContext check

              final controller = ref.read(plantControllerProvider.notifier);
              final newNotes = notesController.text.trim();
              final updatedPlant = plant.copyWith(
                  notes: () => newNotes.isEmpty ? null : newNotes);
              final success = await controller.updatePlant(updatedPlant);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                if (outerContext.mounted) {
                  // outerContext für ScaffoldMessenger
                  if (success) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(content: Text('Notizen gespeichert!')),
                    );
                  } else {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler beim Speichern der Notizen.'),
                        backgroundColor: AppColors.errorColor,
                      ),
                    );
                  }
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
