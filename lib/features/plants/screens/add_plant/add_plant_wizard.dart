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

  bool get isBasicInfoComplete =>
      name != null &&
      name!.isNotEmpty &&
      plantType != null &&
      strain != null &&
      strain!.isNotEmpty &&
      initialStatus != null;

  // Wichtig: documentationStartDate ist jetzt das Pflichtfeld für diesen Schritt
  bool get isCultivationComplete =>
      documentationStartDate != null && medium != null && location != null;

  bool get isReadyToCreate => isBasicInfoComplete && isCultivationComplete;

  // Stellt sicher, dass immer ein Datum für die Erstellung der Pflanze vorhanden ist
  DateTime get effectiveDocumentationDate =>
      documentationStartDate ?? DateTime.now();

  AddPlantData copyWith({
    String? name,
    PlantType? plantType,
    PlantStatus? initialStatus,
    String? strain,
    String? breeder,
    DateTime? seedDate,
    DateTime? germinationDate,
    DateTime? documentationStartDate,
    PlantMedium? medium,
    PlantLocation? location,
    int? estimatedHarvestDays,
    String? notes,
    String? photoPath,
    // Erlaube explizites Null-Setzen für optionale Felder
    bool setBreederNull = false,
    bool setSeedDateNull = false,
    bool setGerminationDateNull = false,
    bool setEstimatedHarvestDaysNull = false,
    bool setNotesNull = false,
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
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createPlant() async {
    final data = ref.read(addPlantDataProvider);
    if (!data.isReadyToCreate) {
      if (mounted) {
        // mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bitte fülle alle Pflichtfelder aus.'),
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
        documentationStartDate:
            data.effectiveDocumentationDate, // Verwende das effektive Datum
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
        ref.read(addPlantDataProvider.notifier).state =
            AddPlantData(); // Reset data
        context.goNamed('dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Pflanze konnte nicht erstellt werden. Details siehe Konsole.'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen der Pflanze: ${e.toString()}'),
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
      case 2:
        return true; // Fotoseite kann immer übersprungen werden
      case 3:
        return data.isReadyToCreate;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Neue Pflanze (${_currentStep + 1}/${_stepTitles.length})',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(addPlantDataProvider.notifier).state =
                AddPlantData(); // Reset data
            context.goNamed('dashboard');
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitles[_currentStep],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _stepTitles.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Deaktiviert Swipe-Navigation
              children: const [
                BasicInfoStep(),
                CultivationDetailsStep(),
                PhotoStep(),
                ConfirmationStep(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('Zurück'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0
                      ? 1
                      : 1, // Button gleich breit machen, wenn nur einer da ist
                  child: ElevatedButton(
                    onPressed: _canProceed()
                        ? (_currentStep == _stepTitles.length - 1
                            ? _createPlant // Auf der letzten Seite wird erstellt
                            : _nextStep) // Sonst zum nächsten Schritt
                        : null, // Deaktiviert, wenn _canProceed false ist
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == _stepTitles.length - 1
                                ? 'Pflanze erstellen'
                                : 'Weiter',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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
