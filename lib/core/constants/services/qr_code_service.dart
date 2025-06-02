// lib/core/services/qr_code_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart'; // Importiert die Klasse Share
import 'package:flutter/services.dart' show rootBundle;

// WICHTIG: Stelle sicher, dass dieser Pfad korrekt ist und die Datei
// lib/core/constants/app_strings.dart existiert und eine Klasse AppStrings enthält!
import '../constants/app_strings.dart';
import '../../../data/models/plant.dart';

enum LabelField {
  plantName,
  displayId,
  ownerName,
  strain,
  plantType,
  status,
  age,
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

    ByteData? regularFontData;
    ByteData? boldFontData;
    try {
      regularFontData =
          await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    } catch (e) {
      // ignore: avoid_print
      print(
          "Roboto-Schriftarten konnten nicht geladen werden: $e. Standard-PDF-Schriftarten werden verwendet.");
    }

    final pw.Font? regularTtf =
        regularFontData != null ? pw.Font.ttf(regularFontData) : null;
    final pw.Font? boldTtf =
        boldFontData != null ? pw.Font.ttf(boldFontData) : null;

    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: regularTtf ?? await PdfGoogleFonts.robotoRegular(),
      bold: boldTtf ?? await PdfGoogleFonts.robotoBold(),
    );

    const PdfPageFormat labelFormat = PdfPageFormat(
        7 * PdfPageFormat.cm, 4 * PdfPageFormat.cm,
        marginAll: 0.5 * PdfPageFormat.cm);

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        theme: theme,
        build: (pw.Context context) {
          List<pw.Widget> content = [];
          final defaultBoldFont = boldTtf ?? pw.Font.helveticaBold();

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
            content
                .add(_buildPdfTextRow('ID:', plant.displayId, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.plantName)) {
            content.add(_buildPdfTextRow('Name:', plant.name, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.ownerName) &&
              plant.ownerName != null &&
              plant.ownerName!.isNotEmpty) {
            content.add(_buildPdfTextRow(
                'Besitzer:', plant.ownerName!, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.strain)) {
            content
                .add(_buildPdfTextRow('Sorte:', plant.strain, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.plantType)) {
            content.add(_buildPdfTextRow(
                'Art:', plant.plantType.displayName, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.status)) {
            content.add(_buildPdfTextRow(
                'Status:', plant.status.displayName, defaultBoldFont));
          }
          if (selectedFields.contains(LabelField.age)) {
            content.add(_buildPdfTextRow(
                'Alter:', '${plant.ageInDays} Tage', defaultBoldFont));
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

  pw.Widget _buildPdfTextRow(String label, String value, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 7),
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
      // Standard-API-Aufruf für share_plus
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
            _previewTextRow('ID:', plant.displayId),
          if (selectedFields.contains(LabelField.plantName))
            _previewTextRow('Name:', plant.name),
          if (selectedFields.contains(LabelField.ownerName) &&
              plant.ownerName != null &&
              plant.ownerName!.isNotEmpty)
            _previewTextRow('Besitzer:', plant.ownerName!),
          if (selectedFields.contains(LabelField.strain))
            _previewTextRow('Sorte:', plant.strain),
          if (selectedFields.contains(LabelField.plantType))
            _previewTextRow('Art:', plant.plantType.displayName),
          if (selectedFields.contains(LabelField.status))
            _previewTextRow('Status:', plant.status.displayName),
          if (selectedFields.contains(LabelField.age))
            _previewTextRow('Alter:', '${plant.ageInDays} Tage'),
        ],
      ),
    );
  }

  Widget _previewTextRow(String label, String value) {
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
