// lib/features/plants/screens/add_plant/add_plant_wizard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/plant.dart';
import '../../controllers/plant_controller.dart';
import 'steps/basic_info_step.dart';
import 'steps/cultivation_details_step.dart';
import 'steps/photo_step.dart';
import 'steps/confirmation_step.dart';

class AddPlantData {
  final String? name;
  final String? ownerName; // NEU
  final PlantType? plantType;
  final PlantStatus? initialStatus;
  final String? strain;
  final String? breeder;
  final DateTime? seedDate;
  final DateTime? germinationDate;
  final DateTime? documentationStartDate;
  final PlantMedium? medium;
  final PlantLocation? location;
  final int? estimatedHarvestDays;
  final String? notes;
  final String? photoPath;

  AddPlantData({
    this.name,
    this.ownerName, // NEU
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
      initialStatus != null &&
      strain != null &&
      strain!.isNotEmpty;

  bool get isCultivationComplete =>
      documentationStartDate != null && medium != null && location != null;

  bool get isReadyToCreate => isBasicInfoComplete && isCultivationComplete;

  DateTime get effectiveDocumentationDate {
    if (seedDate != null) return seedDate!;
    if (germinationDate != null) return germinationDate!;
    if (documentationStartDate != null) return documentationStartDate!;
    return DateTime.now();
  }

  AddPlantData copyWith({
    String? name,
    String? ownerName, // NEU
    bool setOwnerNameNull = false, // NEU
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
      ownerName: setOwnerNameNull ? null : (ownerName ?? this.ownerName), // NEU
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
        ownerName: data.ownerName, // NEU
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
        ref.read(addPlantDataProvider.notifier).state =
            AddPlantData(); // Reset data
        // Navigiere zur Detailseite der neu erstellten Pflanze
        context.goNamed('plant_detail', pathParameters: {'plantId': plant.id});
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
      case 2:
        return true;
      case 3:
        return data.isReadyToCreate;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int footerBoxShadowAlpha = (0.2 * 255).round();
    final int primaryColorBorderAlpha = (0.5 * 255).round();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                      Navigator.of(dialogContext).pop();
                      ref.read(addPlantDataProvider.notifier).state =
                          AddPlantData();
                      context.goNamed('dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                        foregroundColor:
                            Colors.white // Für Textfarbe auf rotem Button
                        ),
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
            elevation: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
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
                    minHeight: 6,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(footerBoxShadowAlpha),
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
                            color: AppColors.primaryColor
                                .withAlpha(primaryColorBorderAlpha)),
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
