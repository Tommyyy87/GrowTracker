// lib/features/plants/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:grow_tracker/core/constants/app_colors.dart'; // Für Farben
import 'package:grow_tracker/data/services/supabase_service.dart'; // Für User ID
import 'package:grow_tracker/data/repositories/plant_repository.dart'; // Für Pflanzencheck
// Importiere AppStrings, falls es bei dir funktioniert, ansonsten harte Strings verwenden
// import '../../../core/constants/app_strings.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed
        .normal, // Oder .noDuplicates für weniger Scans desselben Codes
    facing: CameraFacing.back,
    // formats: [BarcodeFormat.qrCode], // Nur QR-Codes scannen
  );
  bool _isProcessing = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    // Optional: Starte die Kamera direkt oder nach einer kurzen Verzögerung
    // cameraController.start(); // Kann auch im build gestartet werden
  }

  Future<void> _handleScannedCode(BarcodeCapture capture) async {
    if (_isProcessing) return; // Verhindere Mehrfachverarbeitung

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String scannedData = barcodes.first.rawValue!;
      // ignore: avoid_print
      print('QR Code gescannt: $scannedData');

      setState(() {
        _isProcessing = true;
        _feedbackMessage = 'Verarbeite Code...';
      });

      // Annahme: Der QR-Code enthält die plant.id (UUID)
      final plantId = scannedData; // Hier ggf. Validierung, ob es eine UUID ist

      try {
        final plantRepository = ref.read(plantRepositoryProvider);
        final plant = await plantRepository.getPlantById(plantId);

        if (!mounted) return;

        if (plant != null) {
          if (plant.userId == SupabaseService.currentUserId) {
            // Eigene Pflanze
            setState(() {
              _feedbackMessage =
                  'Pflanze "${plant.name}" gefunden. Lade Details...';
            });
            // Mit kurzer Verzögerung navigieren, damit der User das Feedback sieht
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.goNamed('plant_detail',
                    pathParameters: {'plantId': plant.id});
              }
            });
            return; // Erfolgreich, Verarbeitung beenden für diesen Scan
          } else {
            // Fremde Pflanze
            setState(() {
              _feedbackMessage =
                  'Diese Pflanze gehört einem anderen Benutzer und ist nicht für dich freigegeben.';
              _isProcessing = false; // Erlaube neuen Scan
            });
          }
        } else {
          // Pflanze nicht in DB gefunden
          setState(() {
            _feedbackMessage =
                'Ungültiger GrowTracker QR-Code. Pflanze nicht gefunden.';
            _isProcessing = false; // Erlaube neuen Scan
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _feedbackMessage = 'Fehler bei der Verarbeitung: ${e.toString()}';
            _isProcessing = false; // Erlaube neuen Scan
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'QR-Code scannen'), // Verwende harten String, falls AppStrings Probleme macht
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleScannedCode,
            // Erlaube Zoom, etc.
            // fit: BoxFit.contain,
            errorBuilder: (context, error, child) {
              // ignore: avoid_print
              print("Kamerafehler: $error");
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text('Kamerafehler',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () async {
                          await cameraController.stop();
                          await cameraController.start();
                        },
                        child: const Text("Kamera neu starten"))
                  ],
                ),
              );
            },
          ),
          // Scan-Bereich Overlay (optional, aber gut für UX)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing
                      ? Colors.orange.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Feedback-Nachricht unten
          if (_feedbackMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Button zum Kamera-Toggle (Front/Back)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.torchState,
                builder: (context, state, child) {
                  switch (state) {
                    case TorchState.off:
                      return const Icon(Icons.flash_off_rounded,
                          color: Colors.white70);
                    case TorchState.on:
                      return const Icon(Icons.flash_on_rounded,
                          color: Colors.amber);
                    default: // unavailable
                      return const Icon(Icons.no_flash_rounded,
                          color: Colors.grey);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  if (state == null)
                    return const Icon(Icons.cameraswitch_rounded,
                        color: Colors.white70);
                  switch (state) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front_rounded,
                          color: Colors.white70);
                    case CameraFacing.back:
                      return const Icon(Icons.camera_rear_rounded,
                          color: Colors.white70);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
