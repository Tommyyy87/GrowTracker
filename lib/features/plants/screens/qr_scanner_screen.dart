// lib/features/plants/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/data/services/supabase_service.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart'; // Stellt plantRepositoryProvider bereit

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    // Optional: Nur QR-Codes scannen für bessere Performance
    // formats: [BarcodeFormat.qrCode],
  );
  bool _isProcessing = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    // Starte die Kamera, sobald das Widget initialisiert ist.
    // Es ist oft besser, dies hier zu tun als im build, um mehrfache Starts zu vermeiden.
    // Jedoch muss sichergestellt werden, dass der Controller nicht bereits läuft oder disposed wurde.
    // Für mobile_scanner ist es oft implizit, aber explizites Starten kann helfen.
    // cameraController.start(); // Kann Probleme verursachen, wenn Widget neu gebaut wird.
    // Besser: Der MobileScanner startet die Kamera selbst, wenn er im Widget-Baum ist.
  }

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
      // ignore: avoid_print
      print('QR Code gescannt: $scannedData');

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
            // Kurze Verzögerung für das Feedback, bevor navigiert wird
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                context.goNamed('plant_detail',
                    pathParameters: {'plantId': plant.id});
              }
            });
            // Kein return hier, damit _isProcessing ggf. zurückgesetzt wird, falls Navigation fehlschlägt
            // oder der User schnell zurück navigiert. Besser im finally Block.
          } else {
            setState(() {
              _feedbackMessage =
                  'Diese Pflanze gehört einem anderen Benutzer und ist nicht für dich freigegeben.';
              _isProcessing = false; // Erlaube neuen Scan
            });
          }
        } else {
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
      // Optional: _isProcessing im finally zurücksetzen, wenn die Navigation nicht stattfindet
      // oder wenn der Scan fehlschlägt, damit der User erneut scannen kann.
      // Hier wird es bereits in den Fehlerfällen und bei fremder Pflanze zurückgesetzt.
      // Bei erfolgreichem Scan und Navigation wird der Screen ohnehin verlassen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code scannen'), // Später AppStrings verwenden
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleScannedCode,
            errorBuilder: (context, error, Widget? child) {
              // ignore: avoid_print
              print("Kamerafehler: $error");
              String errorMessage = "Unbekannter Kamerafehler";
              if (error.errorDetails != null) {
                errorMessage = error.errorDetails!.message ?? errorMessage;
              } else if (error.toString().isNotEmpty) {
                errorMessage = error.toString();
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      Text(errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Kamera neu starten"),
                        onPressed: () async {
                          if (mounted) {
                            try {
                              await cameraController.stop();
                              await Future.delayed(const Duration(
                                  milliseconds: 100)); // Kurze Pause
                              await cameraController.start();
                              if (mounted) {
                                setState(() {
                                  _feedbackMessage =
                                      "Kamera wird neu gestartet...";
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _feedbackMessage = "Fehler beim Neustart: $e";
                                });
                              }
                            }
                          }
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          // Visueller Scan-Rahmen
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isProcessing
                    ? Colors.orange.withAlpha((0.7 * 255).round())
                    : Colors.white.withAlpha((0.7 * 255).round()),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Feedback-Nachricht am unteren Bildschirmrand
          if (_feedbackMessage != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.75 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Kamerasteuerungen (Blitz, Kamera wechseln)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: ValueListenableBuilder<CameraFacing>(
                      valueListenable: cameraController.cameraFacingState,
                      builder: (context, state, child) {
                        switch (state) {
                          case CameraFacing.front:
                            return const Icon(Icons.camera_front_rounded,
                                color: Colors.white70);
                          case CameraFacing.back:
                            return const Icon(Icons.camera_rear_rounded,
                                color: Colors.white70);
                        }
                        // Default (sollte nicht erreicht werden für CameraFacing)
                        // return const Icon(Icons.cameraswitch_rounded, color: Colors.grey);
                      },
                    ),
                    iconSize: 32.0,
                    onPressed: () => cameraController.switchCamera(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: ValueListenableBuilder<TorchState>(
                      valueListenable: cameraController.torchState,
                      builder: (context, state, child) {
                        switch (state) {
                          case TorchState.off:
                            return const Icon(Icons.flash_off_rounded,
                                color: Colors.white70);
                          case TorchState.on:
                            return const Icon(Icons.flash_on_rounded,
                                color: Colors.amber);
                          default: // TorchState.unavailable
                            return const Icon(Icons.no_flash_rounded,
                                color: Colors.grey);
                        }
                      },
                    ),
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
