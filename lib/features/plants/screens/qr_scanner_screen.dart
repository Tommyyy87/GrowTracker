// lib/features/plants/screens/qr_scanner_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/data/services/supabase_service.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  String? _feedbackMessage;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String scannedData = barcodes.first.rawValue!;
      debugPrint('QR Code gescannt: $scannedData');

      if (mounted) {
        setState(() {
          _isProcessing = true;
          _feedbackMessage = 'Verarbeite Code...';
        });
      }

      final plantId = scannedData;

      try {
        final plantRepository = ref.read(plantRepositoryProvider);
        final plant = await plantRepository.getPlantById(plantId);

        if (!mounted) return;

        if (plant != null) {
          if (plant.userId == SupabaseService.currentUserId) {
            setState(() {
              _feedbackMessage =
                  'Pflanze "${plant.name}" gefunden. Lade Details...';
            });
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                context.goNamed('plant_detail',
                    pathParameters: {'plantId': plant.id});
              }
            });
          } else {
            setState(() {
              _feedbackMessage =
                  'Diese Pflanze gehört einem anderen Benutzer.';
              _isProcessing = false;
            });
          }
        } else {
          setState(() {
            _feedbackMessage =
                'Ungültiger GrowTracker QR-Code. Pflanze nicht gefunden.';
            _isProcessing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _feedbackMessage = 'Fehler bei der Verarbeitung: ${e.toString()}';
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Diese Methode hat die korrekte 2-Parameter-Signatur
  Widget _buildErrorWidget(
      BuildContext context, MobileScannerException error) {
    final String errorMessage = error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Kamerafehler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Kamera neu starten"),
              onPressed: () => cameraController.start(),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code scannen'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleScannedCode,
            // KORREKTUR: Wir übergeben die Methode direkt.
            // Ihre Signatur passt nun exakt zu dem, was der Builder erwartet.
            errorBuilder: _buildErrorWidget,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isProcessing
                    ? Colors.orange.withAlpha((255 * 0.7).round())
                    : Colors.white.withAlpha((255 * 0.7).round()),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_feedbackMessage != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((255 * 0.75).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Temporärer statischer Button (siehe Anleitung von letzter Nachricht)
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70),
                    iconSize: 32.0,
                    onPressed: () => cameraController.switchCamera(),
                  ),
                  
                   // Temporärer statischer Button (siehe Anleitung von letzter Nachricht)
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.white70),
                    iconSize: 32.0,
                    onPressed: () => cameraController.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}