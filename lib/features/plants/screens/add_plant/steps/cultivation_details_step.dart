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
    ref.read(addPlantDataProvider.notifier).update((state) => state
      ..notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim());
  }

  void _updateHarvestDays() {
    final text = _harvestDaysController.text.trim();
    final days = text.isEmpty ? null : int.tryParse(text);
    ref
        .read(addPlantDataProvider.notifier)
        .update((state) => state..estimatedHarvestDays = days);
  }

  Future<void> _selectDate(String dateType) async {
    final data = ref.read(addPlantDataProvider);
    DateTime? initialDate;
    DateTime? selectedDate;

    switch (dateType) {
      case 'seed':
        initialDate =
            data.seedDate ?? DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'germination':
        initialDate = data.germinationDate ??
            data.seedDate?.add(const Duration(days: 5)) ??
            DateTime.now().subtract(const Duration(days: 25));
        break;
      case 'documentation':
        initialDate = data.documentationStartDate ?? DateTime.now();
        break;
    }

    selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: _getDatePickerTitle(dateType),
    );

    if (selectedDate != null) {
      ref.read(addPlantDataProvider.notifier).update((state) {
        switch (dateType) {
          case 'seed':
            state.seedDate = selectedDate;
            break;
          case 'germination':
            state.germinationDate = selectedDate;
            break;
          case 'documentation':
            state.documentationStartDate = selectedDate;
            break;
        }
        return state;
      });
    }
  }

  String _getDatePickerTitle(String dateType) {
    switch (dateType) {
      case 'seed':
        return 'Aussaatdatum wählen';
      case 'germination':
        return 'Keimungsdatum wählen';
      case 'documentation':
        return 'Start der Dokumentation wählen';
      default:
        return 'Datum wählen';
    }
  }

  void _clearDate(String dateType) {
    ref.read(addPlantDataProvider.notifier).update((state) {
      switch (dateType) {
        case 'seed':
          state.seedDate = null;
          break;
        case 'germination':
          state.germinationDate = null;
          break;
        case 'documentation':
          state.documentationStartDate = null;
          break;
      }
      return state;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unbekannt';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  List<String> _getRequiredDateFields(PlantStatus? status) {
    if (status == null) return [];

    switch (status) {
      case PlantStatus.seeded:
        return ['seed', 'documentation'];
      case PlantStatus.germinated:
        return ['germination', 'documentation'];
      case PlantStatus.vegetative:
      case PlantStatus.flowering:
      case PlantStatus.harvest:
      case PlantStatus.drying:
      case PlantStatus.curing:
      case PlantStatus.completed:
        return ['documentation'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(addPlantDataProvider);
    final requiredDateFields = _getRequiredDateFields(data.initialStatus);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Beschreibung
            Text(
              'Lege die Anbau-Details für deine Pflanze fest.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Datumsfelder basierend auf Status
            if (data.initialStatus != null) ...[
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

              // Aussaatdatum (immer optional)
              _buildDateField(
                'Aussaatdatum',
                'seed',
                data.seedDate,
                'Wann wurde der Samen eingepflanzt?',
                isRequired: requiredDateFields.contains('seed'),
              ),
              const SizedBox(height: 16),

              // Keimungsdatum (immer optional)
              _buildDateField(
                'Keimungsdatum',
                'germination',
                data.germinationDate,
                'Wann sind die ersten Triebe sichtbar geworden?',
                isRequired: requiredDateFields.contains('germination'),
              ),
              const SizedBox(height: 16),

              // Dokumentationsstart (immer erforderlich)
              _buildDateField(
                'Start der Dokumentation',
                'documentation',
                data.documentationStartDate,
                'Ab wann möchtest du diese Pflanze dokumentieren?',
                isRequired: true,
                defaultToToday: true,
              ),
              const SizedBox(height: 24),
            ],

            // Ernteschätzung
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

            // Anbaumedium
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
                    ref.read(addPlantDataProvider.notifier).update(
                        (state) => state..medium = selected ? medium : null);
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(51), // 0.2 * 255 = 51
                  backgroundColor: Colors.grey.shade100,
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Standort
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
                    ref.read(addPlantDataProvider.notifier).update((state) =>
                        state..location = selected ? location : null);
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(51), // 0.2 * 255 = 51
                  backgroundColor: Colors.grey.shade100,
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notizen (optional)
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

            // Informationsbox
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
                          'Die Ernteschätzung wird basierend auf dem frühesten bekannten Datum berechnet und in der Pflanzenansicht angezeigt.',
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
          style: TextStyle(
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
            if (currentDate != null && !isRequired) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _clearDate(dateType),
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                ),
                tooltip: 'Datum löschen',
              ),
            ],
            if (defaultToToday && currentDate == null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ref.read(addPlantDataProvider.notifier).update((state) {
                    state.documentationStartDate = DateTime.now();
                    return state;
                  });
                },
                child: const Text('Heute'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
