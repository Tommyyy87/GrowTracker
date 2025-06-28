import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../constants/app_strings.dart';
import 'package:grow_tracker/data/models/plant.dart';

enum LabelField {
  plantName,
  displayId,
  ownerName,
  strain,
  plantType,
  status,
  age,
}

// KORREKTUR: displayName wurde hier hinzugefügt, um den Compiler-Fehler zu beheben.
extension LabelFieldExtension on LabelField {
  String get displayName {
    switch (this) {
      case LabelField.plantName:
        return 'Pflanzenname';
      case LabelField.displayId:
        return 'ID';
      case LabelField.ownerName:
        return 'Besitzer';
      case LabelField.strain:
        return 'Sorte/Strain';
      case LabelField.plantType:
        return 'Art';
      case LabelField.status:
        return 'Status';
      case LabelField.age:
        return 'Alter';
    }
  }
}

class QrCodeService {
  Widget generateQrWidget(String data, {double size = 200.0}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      errorStateBuilder: (cxt, err) {
        return const Center(
          child: Text(
            'QR-Code konnte nicht generiert werden.',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Future<Uint8List?> generateQrPngBytes(String data,
      {double size = 200.0}) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );
      final imageData = await painter.toImageData(size);
      return imageData?.buffer.asUint8List();
    } catch (e) {
      // ignore: avoid_print
      print('Fehler beim Generieren des QR-PNG: $e');
      return null;
    }
  }

  Future<String?> createQrCodePngFile(Plant plant) async {
    final qrData = plant.id;
    final pngBytes = await generateQrPngBytes(qrData);
    if (pngBytes == null) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${AppStrings.appName}_QR_${_sanitizeFileName(plant.name)}_${plant.displayId}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      // ignore: avoid_print
      print('Fehler beim Erstellen der QR-PNG Datei: $e');
      return null;
    }
  }

  Future<Uint8List> generatePlantLabelPdf(
    Plant plant,
    Set<LabelField> selectedFields,
  ) async {
    final pdf = pw.Document();
    final qrData = plant.id;

    final fontData = await rootBundle.load("assets/fonts/Roboto-Variable.ttf");
    final ttf = pw.Font.ttf(fontData);

    const PdfPageFormat labelFormat = PdfPageFormat(
        7 * PdfPageFormat.cm, 4 * PdfPageFormat.cm,
        marginAll: 0.5 * PdfPageFormat.cm);

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          content.add(
            pw.Container(
              height: 2.5 * PdfPageFormat.cm,
              width: 2.5 * PdfPageFormat.cm,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                color: PdfColors.black,
              ),
            ),
          );
          content.add(pw.SizedBox(height: 0.2 * PdfPageFormat.cm));

          if (selectedFields.contains(LabelField.displayId)) {
            content.add(_buildPdfTextRow('ID:', plant.displayId));
          }
          if (selectedFields.contains(LabelField.plantName)) {
            content.add(_buildPdfTextRow('Name:', plant.name));
          }
          if (selectedFields.contains(LabelField.ownerName) &&
              plant.ownerName != null &&
              plant.ownerName!.isNotEmpty) {
            content.add(_buildPdfTextRow('Besitzer:', plant.ownerName!));
          }
          if (selectedFields.contains(LabelField.strain)) {
            content.add(_buildPdfTextRow('Sorte:', plant.strain));
          }
          if (selectedFields.contains(LabelField.plantType)) {
            content.add(_buildPdfTextRow('Art:', plant.plantType.displayName));
          }
          if (selectedFields.contains(LabelField.status)) {
            content.add(_buildPdfTextRow('Status:', plant.status.displayName));
          }
          if (selectedFields.contains(LabelField.age)) {
            content.add(_buildPdfTextRow('Alter:', '${plant.ageInDays} Tage'));
          }

          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: content,
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildPdfTextRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
          ),
          pw.SizedBox(width: 2),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.left,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> createPlantLabelPdfFile(
      Plant plant, Set<LabelField> selectedFields) async {
    final pdfBytes = await generatePlantLabelPdf(plant, selectedFields);
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${AppStrings.appName}_Label_${_sanitizeFileName(plant.name)}_${plant.displayId}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      // ignore: avoid_print
      print('Fehler beim Erstellen der PDF-Datei: $e');
      return null;
    }
  }

  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(filePath)], subject: subject);
    } catch (e) {
      // ignore: avoid_print
      print('Fehler beim Teilen der Datei: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
  }

  Widget buildLabelPreview(Set<LabelField> selectedFields, Plant plant) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 50, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          if (selectedFields.contains(LabelField.displayId))
            _previewTextRowPreview('ID:', plant.displayId),
          if (selectedFields.contains(LabelField.plantName))
            _previewTextRowPreview('Name:', plant.name),
          if (selectedFields.contains(LabelField.ownerName) &&
              plant.ownerName != null &&
              plant.ownerName!.isNotEmpty)
            _previewTextRowPreview('Besitzer:', plant.ownerName!),
          if (selectedFields.contains(LabelField.strain))
            _previewTextRowPreview('Sorte:', plant.strain),
          if (selectedFields.contains(LabelField.plantType))
            _previewTextRowPreview('Art:', plant.plantType.displayName),
          if (selectedFields.contains(LabelField.status))
            _previewTextRowPreview('Status:', plant.status.displayName),
          if (selectedFields.contains(LabelField.age))
            _previewTextRowPreview('Alter:', '${plant.ageInDays} Tage'),
        ],
      ),
    );
  }

  Widget _previewTextRowPreview(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

final qrCodeServiceProvider = Provider<QrCodeService>((ref) {
  return QrCodeService();
});
