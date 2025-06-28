import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/core/services/qr_code_service.dart';
import 'package:grow_tracker/data/models/plant.dart';

/// Displays a modal bottom sheet with QR code options for the given plant.
void showQrOptionsDialog(BuildContext context, WidgetRef ref, Plant plant) {
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
                padding:
                    const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
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

/// Shows a simple dialog with the plant's QR code.
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
            child: Text(
              'QR-Code: ${plant.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
              child: Text(
                'Besitzer: ${plant.ownerName}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
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

/// Exports the QR code as a PNG file and shares it.
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
        backgroundColor: AppColors.errorColor,
      ),
    );
  }
}

/// Shows a dialog to configure and export a plant label as a PDF.
void _showPdfLabelOptionsDialog(
    BuildContext context, Plant plant, QrCodeService qrService) {
  final Set<LabelField> selectedLabelFields = {
    LabelField.displayId,
    LabelField.plantName,
    LabelField.strain,
    LabelField.ownerName,
  };

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
                  return CheckboxListTile(
                    title: Text(field.displayName),
                    value: selectedLabelFields.contains(field),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedLabelFields.add(field);
                        } else {
                          selectedLabelFields.remove(field);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                const Text('Vorschau (schematisch):'),
                const SizedBox(height: 4),
                Center(
                  child:
                      qrService.buildLabelPreview(selectedLabelFields, plant),
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
                Navigator.of(dialogContext).pop();
                await _exportLabelAsPdf(
                    context, plant, qrService, selectedLabelFields);
              },
              child: const Text('PDF erstellen & Teilen'),
            ),
          ],
        );
      });
    },
  );
}

/// Exports the configured plant label as a PDF file and shares it.
Future<void> _exportLabelAsPdf(BuildContext context, Plant plant,
    QrCodeService qrService, Set<LabelField> selectedFields) async {
  final filePath =
      await qrService.createPlantLabelPdfFile(plant, selectedFields);
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
        backgroundColor: AppColors.errorColor,
      ),
    );
  }
}
