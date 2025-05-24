// lib/features/plants/screens/add_plant/steps/cultivation_details_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/plant.dart'; // Für Enums
import '../add_plant_wizard.dart'; // Stellt AddPlantData und Provider bereit

class CultivationDetailsStep extends ConsumerWidget {
  const CultivationDetailsStep({super.key});

  Future<void> _selectDate(BuildContext context, WidgetRef ref,
      DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Erlaube Zukunftsdaten
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);
    final dataNotifier = ref.read(addPlantDataProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        // Optional: Form-Widget für Validierung
        // autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start der Dokumentation*',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ab diesem Datum wird das Alter der Pflanze berechnet, falls kein Aussaat- oder Keimdatum angegeben wurde.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data.documentationStartDate == null
                  ? 'Dokumentationsstart wählen*'
                  : 'Start: ${DateFormat('dd.MM.yyyy').format(data.documentationStartDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.documentationStartDate,
                  (date) => dataNotifier.update(
                      (state) => state.copyWith(documentationStartDate: date))),
            ),
            // Validator-Nachricht, wenn das Feld leer ist und es ein Pflichtfeld ist
            if (data.documentationStartDate == null)
              Padding(
                padding: const EdgeInsets.only(
                    left: 0.0, top: 4.0), // Angepasst auf linksbündig
                child: Text(
                  'Dokumentationsstart ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<PlantMedium>(
              value: data.medium,
              decoration: const InputDecoration(labelText: 'Anbaumedium*'),
              items: PlantMedium.values
                  .map((medium) => DropdownMenuItem(
                        value: medium,
                        child: Text(medium.displayName),
                      ))
                  .toList(),
              onChanged: (value) =>
                  dataNotifier.update((state) => state.copyWith(medium: value)),
              validator: (value) =>
                  value == null ? 'Medium ist erforderlich' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantLocation>(
              value: data.location,
              decoration: const InputDecoration(labelText: 'Standort*'),
              items: PlantLocation.values
                  .map((location) => DropdownMenuItem(
                        value: location,
                        child: Text(location.displayName),
                      ))
                  .toList(),
              onChanged: (value) => dataNotifier
                  .update((state) => state.copyWith(location: value)),
              validator: (value) =>
                  value == null ? 'Standort ist erforderlich' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.estimatedHarvestDays?.toString(),
              decoration: const InputDecoration(
                  labelText: 'Geschätzte Tage bis Ernte (optional)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => dataNotifier.update((state) =>
                  state.copyWith(
                      estimatedHarvestDays: int.tryParse(value),
                      setEstimatedHarvestDaysNull: value.isEmpty)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.notes,
              decoration: const InputDecoration(
                labelText: 'Notizen (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => dataNotifier.update((state) =>
                  state.copyWith(
                      notes: value.isEmpty ? null : value,
                      setNotesNull: value.isEmpty)),
            ),
          ],
        ),
      ),
    );
  }
}
