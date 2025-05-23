// lib/features/plants/screens/add_plant/steps/cultivation_details_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/plant.dart';
import '../add_plant_wizard.dart';

class CultivationDetailsStep extends ConsumerStatefulWidget {
  const CultivationDetailsStep({super.key});

  @override
  ConsumerState<CultivationDetailsStep> createState() =>
      _CultivationDetailsStepState();
}

class _CultivationDetailsStepState
    extends ConsumerState<CultivationDetailsStep> {
  final _notesController = TextEditingController();
  final _harvestDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(addPlantDataProvider);
    _notesController.text = data.notes ?? '';
    _harvestDaysController.text = data.estimatedHarvestDays?.toString() ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _harvestDaysController.dispose();
    super.dispose();
  }

  void _updateNotes() {
    ref.read(addPlantDataProvider.notifier).update((currentData) {
      return AddPlantData(
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        name: currentData.name,
        plantType: currentData.plantType,
        initialStatus: currentData.initialStatus,
        strain: currentData.strain,
        breeder: currentData.breeder,
        seedDate: currentData.seedDate,
        germinationDate: currentData.germinationDate,
        plantedDate: currentData.plantedDate,
        medium: currentData.medium,
        location: currentData.location,
        estimatedHarvestDays: currentData.estimatedHarvestDays,
        photoPath: currentData.photoPath,
      );
    });
  }

  void _updateHarvestDays() {
    final text = _harvestDaysController.text.trim();
    final days = text.isEmpty ? null : int.tryParse(text);
    ref.read(addPlantDataProvider.notifier).update((currentData) {
      return AddPlantData(
        estimatedHarvestDays: days,
        name: currentData.name,
        plantType: currentData.plantType,
        initialStatus: currentData.initialStatus,
        strain: currentData.strain,
        breeder: currentData.breeder,
        seedDate: currentData.seedDate,
        germinationDate: currentData.germinationDate,
        plantedDate: currentData.plantedDate,
        medium: currentData.medium,
        location: currentData.location,
        notes: currentData.notes,
        photoPath: currentData.photoPath,
      );
    });
  }

  Future<void> _selectDate(String dateType) async {
    final currentData = ref.read(addPlantDataProvider);
    DateTime? initialDateForPicker;

    switch (dateType) {
      case 'seed':
        initialDateForPicker = currentData.seedDate ??
            DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'germination':
        initialDateForPicker = currentData.germinationDate ??
            currentData.seedDate?.add(const Duration(days: 5)) ??
            DateTime.now().subtract(const Duration(days: 25));
        break;
      case 'planted':
        initialDateForPicker = currentData.plantedDate ?? DateTime.now();
        break;
      default:
        initialDateForPicker = DateTime.now();
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateForPicker,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _getDatePickerTitle(dateType),
    );

    if (selectedDate != null) {
      ref.read(addPlantDataProvider.notifier).update((currentDataInternal) {
        DateTime? newSeedDate = currentDataInternal.seedDate;
        DateTime? newGerminationDate = currentDataInternal.germinationDate;
        DateTime? newPlantedDate = currentDataInternal.plantedDate;

        switch (dateType) {
          case 'seed':
            newSeedDate = selectedDate;
            break;
          case 'germination':
            newGerminationDate = selectedDate;
            break;
          case 'planted':
            newPlantedDate = selectedDate;
            break;
        }
        return AddPlantData(
          seedDate: newSeedDate,
          germinationDate: newGerminationDate,
          plantedDate: newPlantedDate,
          name: currentDataInternal.name,
          plantType: currentDataInternal.plantType,
          initialStatus: currentDataInternal.initialStatus,
          strain: currentDataInternal.strain,
          breeder: currentDataInternal.breeder,
          medium: currentDataInternal.medium,
          location: currentDataInternal.location,
          estimatedHarvestDays: currentDataInternal.estimatedHarvestDays,
          notes: currentDataInternal.notes,
          photoPath: currentDataInternal.photoPath,
        );
      });
    }
  }

  String _getDatePickerTitle(String dateType) {
    switch (dateType) {
      case 'seed':
        return 'Aussaatdatum wählen';
      case 'germination':
        return 'Keimungsdatum wählen';
      case 'planted':
        return 'Pflanzdatum wählen';
      default:
        return 'Datum wählen';
    }
  }

  void _clearDate(String dateType) {
    ref.read(addPlantDataProvider.notifier).update((currentData) {
      DateTime? newSeedDate = currentData.seedDate;
      DateTime? newGerminationDate = currentData.germinationDate;
      // Pflanzdatum (plantedDate) ist ein Pflichtfeld und sollte hier nicht auf null gesetzt werden,
      // da der Clear-Button dafür nicht angezeigt wird.
      DateTime? newPlantedDate = currentData.plantedDate; 

      switch (dateType) {
        case 'seed':
          newSeedDate = null;
          break;
        case 'germination':
          newGerminationDate = null;
          break;
        // Kein 'case' für 'planted', da es nicht gelöscht werden soll/kann über diesen Mechanismus
      }
      return AddPlantData(
        seedDate: newSeedDate,
        germinationDate: newGerminationDate,
        plantedDate: newPlantedDate,
        name: currentData.name,
        plantType: currentData.plantType,
        initialStatus: currentData.initialStatus,
        strain: currentData.strain,
        breeder: currentData.breeder,
        medium: currentData.medium,
        location: currentData.location,
        estimatedHarvestDays: currentData.estimatedHarvestDays,
        notes: currentData.notes,
        photoPath: currentData.photoPath,
      );
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unbekannt';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // _getRequiredDateFields ist nicht mehr nötig und wurde entfernt.

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(addPlantDataProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Lege die Anbau-Details für deine Pflanze fest.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Wichtige Daten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gib die bekannten Daten ein. Unbekannte Daten können leer gelassen werden.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Aussaatdatum',
              'seed',
              data.seedDate,
              'Wann wurde der Samen eingepflanzt? (optional)',
              isRequired: false,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Keimungsdatum',
              'germination',
              data.germinationDate,
              'Wann sind die ersten Triebe sichtbar geworden? (optional)',
              isRequired: false,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Pflanzdatum *',
              'planted',
              data.plantedDate,
              'Wann wurde die Pflanze gesetzt / Dokumentation begonnen?',
              isRequired: true,
              defaultToToday: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Ernteschätzung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wie viele Tage dauert es voraussichtlich bis zur Ernte? (optional)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _harvestDaysController,
              onChanged: (_) => _updateHarvestDays(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Tage bis zur Ernte',
                hintText: 'z.B. 75 für 75 Tage oder 70 für 10 Wochen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.schedule_rounded),
                suffixText: 'Tage',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Anbaumedium *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PlantMedium.values.map((medium) {
                final isSelected = data.medium == medium;
                return ChoiceChip(
                  label: Text(medium.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(addPlantDataProvider.notifier).update((currentData) {
                      return AddPlantData(
                        medium: selected ? medium : null,
                        name: currentData.name,
                        plantType: currentData.plantType,
                        initialStatus: currentData.initialStatus,
                        strain: currentData.strain,
                        breeder: currentData.breeder,
                        seedDate: currentData.seedDate,
                        germinationDate: currentData.germinationDate,
                        plantedDate: currentData.plantedDate,
                        location: currentData.location,
                        estimatedHarvestDays: currentData.estimatedHarvestDays,
                        notes: currentData.notes,
                        photoPath: currentData.photoPath,
                      );
                    });
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(51),
                  backgroundColor: Colors.grey.shade100,
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Standort *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PlantLocation.values.map((location) {
                final isSelected = data.location == location;
                return ChoiceChip(
                  label: Text(location.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(addPlantDataProvider.notifier).update((currentData) {
                      return AddPlantData(
                        location: selected ? location : null,
                        name: currentData.name,
                        plantType: currentData.plantType,
                        initialStatus: currentData.initialStatus,
                        strain: currentData.strain,
                        breeder: currentData.breeder,
                        seedDate: currentData.seedDate,
                        germinationDate: currentData.germinationDate,
                        plantedDate: currentData.plantedDate,
                        medium: currentData.medium,
                        estimatedHarvestDays: currentData.estimatedHarvestDays,
                        notes: currentData.notes,
                        photoPath: currentData.photoPath,
                      );
                    });
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(51),
                  backgroundColor: Colors.grey.shade100,
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              onChanged: (_) => _updateNotes(),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Zusätzliche Notizen',
                hintText: 'z.B. Besonderheiten, Ziele, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ernteschätzung',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Die Ernteschätzung wird basierend auf dem Pflanzdatum (oder Aussaat/Keimung, falls früher) berechnet.',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String dateType,
    DateTime? currentDate,
    String helpText, {
    bool isRequired = false,
    bool defaultToToday = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helpText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(dateType),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: currentDate != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(currentDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: currentDate != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (currentDate != null && !isRequired)
              IconButton(
                onPressed: () => _clearDate(dateType),
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                ),
                tooltip: 'Datum löschen',
              ),
            if (defaultToToday && currentDate == null && dateType == 'planted')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextButton(
                  onPressed: () {
                    ref.read(addPlantDataProvider.notifier).update((currentData) {
                      return AddPlantData(
                        plantedDate: DateTime.now(),
                        name: currentData.name,
                        plantType: currentData.plantType,
                        initialStatus: currentData.initialStatus,
                        strain: currentData.strain,
                        breeder: currentData.breeder,
                        seedDate: currentData.seedDate,
                        germinationDate: currentData.germinationDate,
                        medium: currentData.medium,
                        location: currentData.location,
                        estimatedHarvestDays: currentData.estimatedHarvestDays,
                        notes: currentData.notes,
                        photoPath: currentData.photoPath,
                      );
                    });
                  },
                  child: const Text('Heute'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}