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
  String? name;
  PlantType? plantType;
  String? strain;
  String? breeder;
  DateTime? plantedDate;
  PlantMedium? medium;
  PlantLocation? location;
  String? notes;
  String? photoPath;

  bool get isBasicInfoComplete =>
      name != null && plantType != null && strain != null && strain!.isNotEmpty;

  bool get isCultivationComplete =>
      plantedDate != null && medium != null && location != null;

  bool get isReadyToCreate => isBasicInfoComplete && isCultivationComplete;
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
    if (!data.isReadyToCreate) return;

    setState(() => _isCreating = true);

    try {
      final controller = ref.read(plantControllerProvider.notifier);
      final plant = await controller.createPlant(
        name: data.name!,
        plantType: data.plantType!,
        strain: data.strain!,
        breeder: data.breeder,
        plantedDate: data.plantedDate!,
        medium: data.medium!,
        location: data.location!,
        notes: data.notes,
        photoPath: data.photoPath,
      );

      if (plant != null && mounted) {
        // Erfolgsmeldung anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.name} wurde erfolgreich erstellt!'),
            backgroundColor: AppColors.successColor,
          ),
        );

        // Zurück zum Dashboard
        context.goNamed('dashboard');
      } else {
        throw Exception('Pflanze konnte nicht erstellt werden');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen der Pflanze: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  bool _canProceed() {
    final data = ref.watch(addPlantDataProvider);

    switch (_currentStep) {
      case 0: // Basic Info
        return data.isBasicInfoComplete;
      case 1: // Cultivation Details
        return data.isCultivationComplete;
      case 2: // Photo (optional)
        return true;
      case 3: // Confirmation
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
          onPressed: () => context.goNamed('dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
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

          // Step Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                BasicInfoStep(),
                CultivationDetailsStep(),
                PhotoStep(),
                ConfirmationStep(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
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
                      ),
                      child: const Text('Zurück'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _canProceed()
                        ? (_currentStep == _stepTitles.length - 1
                            ? _createPlant
                            : _nextStep)
                        : null,
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
