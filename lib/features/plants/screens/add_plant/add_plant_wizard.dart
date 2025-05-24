// lib/features/plants/screens/add_plant/add_plant_wizard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/plant.dart'; // Brauchen wir für Enums
import '../../controllers/plant_controller.dart';
import 'steps/basic_info_step.dart';
import 'steps/cultivation_details_step.dart';
import 'steps/photo_step.dart';
import 'steps/confirmation_step.dart';

// AddPlantData ist jetzt hier definiert und verwendet documentationStartDate
class AddPlantData {
  final String? name;
  final PlantType? plantType;
  final PlantStatus? initialStatus;
  final String? strain;
  final String? breeder;
  final DateTime? seedDate;
  final DateTime? germinationDate;
  final DateTime? documentationStartDate; // Umbenannt und zentral
  final PlantMedium? medium;
  final PlantLocation? location;
  final int? estimatedHarvestDays;
  final String? notes;
  final String? photoPath;

  AddPlantData({
    this.name,
    this.plantType,
    this.initialStatus,
    this.strain,
    this.breeder,
    this.seedDate,
    this.germinationDate,
    this.documentationStartDate,
    this.medium,
    this.location,
    this.estimatedHarvestDays,
    this.notes,
    this.photoPath,
  });

  // Validierung für den ersten Schritt (Basis-Informationen)
  bool get isBasicInfoComplete =>
      name != null &&
      name!.isNotEmpty &&
      plantType != null && // Jetzt Auswahl über Kachel
      initialStatus != null && // Jetzt Auswahl über Kachel
      strain != null &&
      strain!.isNotEmpty;

  // Validierung für den zweiten Schritt (Anbau-Details)
  bool get isCultivationComplete =>
      documentationStartDate != null &&
      medium != null && // Jetzt Auswahl über Kachel
      location != null; // Jetzt Auswahl über Kachel

  // Gesamtvalidierung, bevor eine Pflanze erstellt werden kann
  bool get isReadyToCreate => isBasicInfoComplete && isCultivationComplete;

  // Stellt sicher, dass immer ein Datum für die Erstellung der Pflanze vorhanden ist
  DateTime get effectiveDocumentationDate {
    // Priorität: Aussaat, dann Keimung, dann Doku-Start (falls gesetzt), sonst heute
    if (seedDate != null) return seedDate!;
    if (germinationDate != null) return germinationDate!;
    if (documentationStartDate != null) return documentationStartDate!;
    return DateTime.now();
  }

  AddPlantData copyWith({
    String? name,
    PlantType? plantType,
    PlantStatus? initialStatus,
    String? strain,
    String? breeder,
    bool setBreederNull = false,
    DateTime? seedDate,
    bool setSeedDateNull = false,
    DateTime? germinationDate,
    bool setGerminationDateNull = false,
    DateTime? documentationStartDate,
    PlantMedium? medium,
    PlantLocation? location,
    int? estimatedHarvestDays,
    bool setEstimatedHarvestDaysNull = false,
    String? notes,
    bool setNotesNull = false,
    String? photoPath,
    bool setPhotoPathNull = false,
  }) {
    return AddPlantData(
      name: name ?? this.name,
      plantType: plantType ?? this.plantType,
      initialStatus: initialStatus ?? this.initialStatus,
      strain: strain ?? this.strain,
      breeder: setBreederNull ? null : (breeder ?? this.breeder),
      seedDate: setSeedDateNull ? null : (seedDate ?? this.seedDate),
      germinationDate: setGerminationDateNull
          ? null
          : (germinationDate ?? this.germinationDate),
      documentationStartDate:
          documentationStartDate ?? this.documentationStartDate,
      medium: medium ?? this.medium,
      location: location ?? this.location,
      estimatedHarvestDays: setEstimatedHarvestDaysNull
          ? null
          : (estimatedHarvestDays ?? this.estimatedHarvestDays),
      notes: setNotesNull ? null : (notes ?? this.notes),
      photoPath: setPhotoPathNull ? null : (photoPath ?? this.photoPath),
    );
  }
}

final addPlantDataProvider =
    StateProvider<AddPlantData>((ref) => AddPlantData());

class AddPlantWizard extends ConsumerStatefulWidget {
  const AddPlantWizard({super.key});

  @override
  ConsumerState<AddPlantWizard> createState() => _AddPlantWizardState();
}

class _AddPlantWizardState extends ConsumerState<AddPlantWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isCreating = false;

  final List<String> _stepTitles = [
    'Basis-Informationen',
    'Anbau-Details',
    'Foto hinzufügen',
    'Bestätigung',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Formular-Validierung explizit aufrufen, falls ein FormKey pro Step existiert
    // Hier gehen wir davon aus, dass die Validierung im `_canProceed` behandelt wird.
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _createPlant() async {
    final data = ref.read(addPlantDataProvider);
    if (!data.isReadyToCreate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bitte fülle alle Pflichtfelder (*) aus.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      return;
    }

    setState(() => _isCreating = true);

    try {
      final controller = ref.read(plantControllerProvider.notifier);
      final plant = await controller.createPlant(
        name: data.name!,
        plantType: data.plantType!,
        strain: data.strain!,
        breeder: data.breeder,
        seedDate: data.seedDate,
        germinationDate: data.germinationDate,
        documentationStartDate: data.effectiveDocumentationDate,
        medium: data.medium!,
        location: data.location!,
        initialStatus: data.initialStatus!,
        estimatedHarvestDays: data.estimatedHarvestDays,
        notes: data.notes,
        photoPath: data.photoPath,
      );

      if (plant != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.name} wurde erfolgreich erstellt!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        ref.read(addPlantDataProvider.notifier).state = AddPlantData();
        context.goNamed('dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Pflanze konnte nicht erstellt werden. Überprüfe die Daten.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  bool _canProceed() {
    final data = ref.watch(addPlantDataProvider);
    switch (_currentStep) {
      case 0:
        return data.isBasicInfoComplete;
      case 1:
        return data.isCultivationComplete;
      case 2: // Foto-Seite
        return true; // Kann immer übersprungen werden
      case 3: // Bestätigungsseite
        return data.isReadyToCreate;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Die Variable 'data' wird hier nicht mehr benötigt, da _canProceed()
    // den Provider direkt überwacht.

    // Umrechnung von Opacity (0.0 - 1.0) zu Alpha (0 - 255)
    final int footerBoxShadowAlpha = (0.2 * 255).round();
    final int primaryColorBorderAlpha = (0.5 * 255).round();

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Heller Hintergrund für den Body
      appBar: AppBar(
        title: Text(
          'Neue Pflanze (${_currentStep + 1}/${_stepTitles.length})',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            // Dialog anzeigen, ob der Benutzer wirklich abbrechen möchte
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Erstellung abbrechen?'),
                content: const Text(
                    'Möchtest du das Erstellen der Pflanze wirklich abbrechen? Deine bisherigen Eingaben gehen verloren.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Weiter bearbeiten'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Dialog schließen
                      ref.read(addPlantDataProvider.notifier).state =
                          AddPlantData();
                      context.goNamed('dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor),
                    child: const Text('Abbrechen & Verwerfen'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Material(
            // Material für den Schatten
            elevation: 1, // Leichter Schatten unter dem Header
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white, // Weißer Hintergrund für den Header-Bereich
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepTitles[_currentStep],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _stepTitles.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor),
                    minHeight: 6, // Etwas dickerer Fortschrittsbalken
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                // Wird nicht direkt genutzt wegen NeverScrollableScrollPhysics,
                // aber gut für zukünftige Änderungen.
                setState(() {
                  _currentStep = index;
                });
              },
              children: const [
                BasicInfoStep(),
                CultivationDetailsStep(),
                PhotoStep(),
                ConfirmationStep(),
              ],
            ),
          ),
          Container(
            // Footer für Buttons
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(
                      footerBoxShadowAlpha), // Verwendung der Alpha-Variable
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                      label: const Text('Zurück'),
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(
                            color: AppColors.primaryColor.withAlpha(
                                primaryColorBorderAlpha)), // Verwendung der Alpha-Variable
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isCreating
                        ? Container()
                        : Icon(
                            _currentStep == _stepTitles.length - 1
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 18),
                    label: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _currentStep == _stepTitles.length - 1
                                ? 'Pflanze erstellen'
                                : 'Weiter',
                          ),
                    onPressed: _canProceed() && !_isCreating
                        ? (_currentStep == _stepTitles.length - 1
                            ? _createPlant
                            : _nextStep)
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
