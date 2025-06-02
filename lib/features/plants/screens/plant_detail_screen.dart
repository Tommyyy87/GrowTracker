// lib/features/plants/screens/plant_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/qr_code_service.dart';
import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../controllers/plant_controller.dart';
import '../widgets/status_timeline.dart';
import '../widgets/plant_info_card.dart';
import '../widgets/harvest_section.dart';
import '../../../data/services/supabase_service.dart';

class PlantDetailScreen extends ConsumerStatefulWidget {
  final String plantId;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });

  @override
  ConsumerState<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends ConsumerState<PlantDetailScreen> {
  final Set<LabelField> _selectedLabelFields = {
    LabelField.displayId,
    LabelField.plantName,
    LabelField.strain,
    LabelField
        .ownerName, // Besitzername standardmäßig hinzufügen, wenn gewünscht
  };

  void _showQrOptionsDialog(BuildContext context, Plant plant) {
    final qrService = ref.read(qrCodeServiceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 16.0, left: 8.0, right: 8.0),
                  child: Text(
                    'QR-Code Optionen für "${plant.name}"',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.primaryColor),
                  title: const Text('QR-Code anzeigen'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showQrCodeDialog(context, plant, qrService);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_rounded,
                      color: AppColors.primaryColor),
                  title: const Text('Als PNG exportieren/teilen'),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _exportQrAsPng(context, plant, qrService);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.primaryColor),
                  title: const Text('Als Etikett (PDF) exportieren/teilen'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _showPdfLabelOptionsDialog(context, plant, qrService);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrCodeDialog(
      BuildContext context, Plant plant, QrCodeService qrService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
                child: Text('QR-Code: ${plant.name}',
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: qrService.generateQrWidget(plant.id, size: 220),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${plant.displayId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (plant.ownerName != null && plant.ownerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Besitzer: ${plant.ownerName}',
                    style: TextStyle(color: Colors.grey.shade700)),
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

  Future<void> _exportQrAsPng(
      BuildContext context, Plant plant, QrCodeService qrService) async {
    final filePath = await qrService.createQrCodePngFile(plant);
    if (!mounted) return;
    if (filePath != null) {
      await qrService.shareFile(
        filePath,
        subject: 'QR-Code für ${plant.name}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PNG QR-Code wird geteilt...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fehler beim Erstellen des PNG QR-Codes'),
            backgroundColor: AppColors.errorColor),
      );
    }
  }

  void _showPdfLabelOptionsDialog(
      BuildContext context, Plant plant, QrCodeService qrService) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (stfContext, setDialogState) {
          return AlertDialog(
            title: const Text('Etikett-Optionen (PDF)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Felder für das Etikett auswählen:'),
                  const SizedBox(height: 8),
                  ...LabelField.values.map((field) {
                    String title;
                    bool isVisible = true;
                    switch (field) {
                      case LabelField.plantName:
                        title = 'Pflanzenname';
                        break;
                      case LabelField.displayId:
                        title = 'Anzeige-ID';
                        break;
                      case LabelField.ownerName:
                        title = 'Besitzer';
                        if (plant.ownerName == null ||
                            plant.ownerName!.isEmpty) {
                          isVisible = false;
                        }
                        break;
                      case LabelField.strain:
                        title = 'Sorte/Strain';
                        break;
                      case LabelField.plantType:
                        title = 'Pflanzenart';
                        break;
                      case LabelField.status:
                        title = 'Status';
                        break;
                      case LabelField.age:
                        title = 'Alter';
                        break;
                    }
                    if (!isVisible) {
                      return const SizedBox.shrink();
                    }

                    return CheckboxListTile(
                      title: Text(title),
                      value: _selectedLabelFields.contains(field),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedLabelFields.add(field);
                          } else {
                            _selectedLabelFields.remove(field);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text('Vorschau (schematisch):'),
                  const SizedBox(height: 4),
                  Center(
                      child: qrService.buildLabelPreview(
                          _selectedLabelFields, plant)),
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
                  Navigator.of(dialogContext).pop();
                  await _exportLabelAsPdf(context, plant, qrService);
                },
                child: const Text('PDF erstellen & Teilen'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _exportLabelAsPdf(
      BuildContext context, Plant plant, QrCodeService qrService) async {
    final filePath =
        await qrService.createPlantLabelPdfFile(plant, _selectedLabelFields);
    if (!mounted) return;
    if (filePath != null) {
      await qrService.shareFile(filePath, subject: 'Etikett für ${plant.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF-Etikett wird geteilt...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fehler beim Erstellen des PDF-Etiketts'),
            backgroundColor: AppColors.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantAsync = ref.watch(plantDetailProvider(widget.plantId));
    final harvestsAsync = ref.watch(plantHarvestsProvider(widget.plantId));

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
            return _buildPlantDetailContent(context, ref, plant, harvestsAsync);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            // ignore: avoid_print
            print('Error loading plant detail: $error\n$stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                      'Fehler beim Laden der Pflanzendetails: ${error.toString()}'),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(plantDetailProvider(widget.plantId));
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildPlantDetailContent(
    BuildContext context,
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
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'QR-Code Optionen',
              onPressed: () => _showQrOptionsDialog(context, plant),
            ),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(context, ref, plant, value),
              itemBuilder: (popupContext) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Bearbeiten')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'harvest',
                  child: Row(children: [
                    Icon(Icons.agriculture, size: 20),
                    SizedBox(width: 8),
                    Text('Ernte dokumentieren')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Löschen', style: TextStyle(color: Colors.red))
                  ]),
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
                  fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryColor, AppColors.gradientEnd],
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
                                      size: 80, color: Colors.white54)),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
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
                                        size: 80, color: Colors.white54)),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                  stops: [0.4, 1.0]),
                            ),
                          ),
                        ])
                      : const Center(
                          child: Icon(Icons.eco_rounded,
                              size: 80, color: Colors.white54)),
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
                  data: (harvests) =>
                      HarvestSection(plant: plant, harvests: harvests),
                  loading: () => const Card(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()))),
                  error: (_, __) => const Card(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Fehler beim Laden der Ernte-Daten.'))),
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
                              Text('Notizen',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(plant.notes!,
                              style: TextStyle(
                                  color: Colors.grey.shade700, height: 1.5)),
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
                        const Text('Aktionen',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addPhoto(context, ref, plant),
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
                                onPressed: () => _addNote(context, ref, plant),
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
                const SizedBox(height: 100),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bearbeiten-Funktion kommt bald!')),
        );
        break;
      case 'harvest':
        _showHarvestDialog(context, ref, plant);
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
    DateTime selectedHarvestDate = DateTime.now();
    DateTime? selectedDryingCompletedDate;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (innerDialogContext, setDialogState) {
        return AlertDialog(
          title: const Text('Ernte dokumentieren'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                      "Erntedatum: ${DateFormat('dd.MM.yyyy').format(selectedHarvestDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: innerDialogContext,
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
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(selectedDryingCompletedDate == null
                      ? "Trocknung abgeschlossen am (optional)"
                      : "Trocknung abgeschlossen: ${DateFormat('dd.MM.yyyy').format(selectedDryingCompletedDate!)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: innerDialogContext,
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
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Notizen - optional',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
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
                if (!mounted) return;

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
                }
                if (mounted) {
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
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Plant plant) {
    showDialog(
      context: context,
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
              if (!mounted) return;
              final controller = ref.read(plantControllerProvider.notifier);
              final success = await controller.deletePlant(plant.id);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                if (success) {
                  context.goNamed('dashboard');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pflanze wurde gelöscht'),
                        backgroundColor: AppColors.successColor),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fehler beim Löschen'),
                        backgroundColor: AppColors.errorColor),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _addPhoto(BuildContext outerContext, WidgetRef ref, Plant plant) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: outerContext,
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

    if (source == null) {
      if (outerContext.mounted) {
        ScaffoldMessenger.of(outerContext).showSnackBar(
          const SnackBar(content: Text('Keine Quelle für Foto ausgewählt.')),
        );
      }
      return;
    }

    if (!outerContext.mounted) return;

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
        final success = await controller.updatePlant(updatedPlant);

        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            SnackBar(
                content: Text(success
                    ? 'Foto erfolgreich aktualisiert!'
                    : 'Fehler beim Aktualisieren des Fotos'),
                backgroundColor:
                    success ? AppColors.successColor : AppColors.errorColor),
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
    final notesController = TextEditingController(text: plant.notes ?? '');
    showDialog(
      context: outerContext,
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
              if (!mounted) return;
              final controller = ref.read(plantControllerProvider.notifier);
              final newNotes = notesController.text.trim();
              final updatedPlant = plant.copyWith(
                  notes: () => newNotes.isEmpty ? null : newNotes);
              final success = await controller.updatePlant(updatedPlant);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
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
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
