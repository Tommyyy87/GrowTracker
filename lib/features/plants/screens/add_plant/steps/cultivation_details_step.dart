// lib/features/plants/screens/add_plant/steps/cultivation_details_step.dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final data = ref.read(addPlantDataProvider);
    _notesController.text = data.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateNotes() {
    ref.read(addPlantDataProvider.notifier).update((state) => state
      ..notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim());
  }

  Future<void> _selectDate() async {
    final data = ref.read(addPlantDataProvider);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: data.plantedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Aussaat-/Keimungsdatum wählen',
    );

    if (selectedDate != null) {
      ref
          .read(addPlantDataProvider.notifier)
          .update((state) => state..plantedDate = selectedDate);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Datum wählen';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

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

            // Beschreibung
            Text(
              'Lege die Anbau-Details für deine Pflanze fest.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Aussaat-/Keimungsdatum
            Text(
              'Aussaat-/Keimungsdatum *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: data.plantedDate != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(data.plantedDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: data.plantedDate != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
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
                          'Gut zu wissen',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Das Aussaatdatum hilft dir später dabei, das Alter deiner Pflanze zu verfolgen und den optimalen Erntezeitpunkt zu bestimmen.',
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
}
