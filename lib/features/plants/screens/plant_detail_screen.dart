import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/qr_code_service.dart';
import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../controllers/plant_controller.dart';
import '../widgets/dialogs/delete_plant_dialog.dart';
import '../widgets/dialogs/harvest_dialog.dart';
import '../widgets/plant_detail/plant_detail_body.dart';

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
    LabelField.ownerName,
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
    if (!context.mounted) return;
    if (filePath != null) {
      await qrService.shareFile(
        filePath,
        subject: 'QR-Code für ${plant.name}',
      );
      if (!context.mounted) return;
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
                    // Logic to build checkboxes
                    return CheckboxListTile(
                      title:
                          Text(field.toString().split('.').last), // Simplified
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
                    );
                  }),
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
                  // The context from the dialog builder might be different
                  // so we pop it first.
                  Navigator.of(dialogContext).pop();
                  // Then call the export function with the original screen context.
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
    if (!context.mounted) return;
    if (filePath != null) {
      await qrService.shareFile(filePath, subject: 'Etikett für ${plant.name}');
      if (!context.mounted) return;
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
          return _buildPlantDetailView(context, plant, harvestsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Fehler: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildPlantDetailView(
    BuildContext context,
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
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'QR-Code Optionen',
              onPressed: () => _showQrOptionsDialog(context, plant),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, plant, value),
              itemBuilder: (popupContext) => [
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
            background: _buildAppBarBackground(plant),
          ),
        ),
        SliverToBoxAdapter(
          child: PlantDetailBody(plant: plant, harvestsAsync: harvestsAsync),
        ),
      ],
    );
  }

  Widget _buildAppBarBackground(Plant plant) {
    final hasHttpPhoto =
        plant.photoUrl != null && plant.photoUrl!.startsWith('http');
    final hasFilePhoto =
        plant.photoUrl != null && File(plant.photoUrl!).existsSync();

    ImageProvider? imageProvider;
    if (hasHttpPhoto) {
      imageProvider = NetworkImage(plant.photoUrl!);
    } else if (hasFilePhoto) {
      imageProvider = FileImage(File(plant.photoUrl!));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryColor, AppColors.gradientEnd],
        ),
      ),
      child: imageProvider != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 80, color: Colors.white54)),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Icon(Icons.eco_rounded, size: 80, color: Colors.white54),
            ),
    );
  }

  void _handleMenuAction(BuildContext context, Plant plant, String action) {
    switch (action) {
      case 'harvest':
        showDialog(
          context: context,
          builder: (_) => HarvestDialog(plantId: plant.id),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (_) => DeletePlantDialog(plant: plant),
        );
        break;
    }
  }
}
