// lib/features/plants/screens/add_plant/steps/basic_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/plant.dart'; // Für Enums PlantType, PlantStatus
import '../add_plant_wizard.dart'; // Stellt AddPlantData und Provider bereit

class BasicInfoStep extends ConsumerWidget {
  const BasicInfoStep({super.key});

  Future<void> _selectDate(
      BuildContext context,
      WidgetRef ref,
      DateTime? initialDate,
      // Diese Funktion wird aufgerufen, wenn ein Datum ausgewählt wurde
      // und aktualisiert den entsprechenden Datumsfeld im addPlantDataProvider
      void Function(DateTime) onDateSelectedInProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(
          days: 365)), // Erlaube auch zukünftige Daten für Planung
    );
    if (picked != null && picked != initialDate) {
      onDateSelectedInProvider(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Beobachte den aktuellen Zustand der AddPlantData
    final data = ref.watch(addPlantDataProvider);
    // Hole den Notifier, um den Zustand zu aktualisieren
    final dataNotifier = ref.read(addPlantDataProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        // autovalidateMode: AutovalidateMode.onUserInteraction, // Bei Bedarf aktivieren
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: data.name,
              decoration: const InputDecoration(labelText: 'Name der Pflanze*'),
              // Aktualisiere das 'name'-Feld im Provider bei jeder Änderung
              onChanged: (value) =>
                  dataNotifier.update((state) => state.copyWith(name: value)),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Name ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantType>(
              value: data.plantType,
              decoration: const InputDecoration(labelText: 'Pflanzenart*'),
              items: PlantType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              onChanged: (value) => dataNotifier
                  .update((state) => state.copyWith(plantType: value)),
              validator: (value) =>
                  value == null ? 'Pflanzenart ist erforderlich' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantStatus>(
              value: data.initialStatus,
              decoration: const InputDecoration(labelText: 'Aktueller Status*'),
              items: PlantStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ))
                  .toList(),
              onChanged: (value) => dataNotifier
                  .update((state) => state.copyWith(initialStatus: value)),
              validator: (value) =>
                  value == null ? 'Status ist erforderlich' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.strain,
              decoration: const InputDecoration(labelText: 'Sorte/Strain*'),
              onChanged: (value) =>
                  dataNotifier.update((state) => state.copyWith(strain: value)),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Sorte ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.breeder,
              decoration:
                  const InputDecoration(labelText: 'Züchter/Marke (optional)'),
              onChanged: (value) => dataNotifier.update((state) =>
                  state.copyWith(
                      breeder: value.isEmpty ? null : value,
                      setBreederNull: value.isEmpty)),
            ),
            const SizedBox(height: 24),
            Text('Wichtige Daten (optional):',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data.seedDate == null
                  ? 'Aussaatdatum'
                  : 'Aussaat: ${DateFormat('dd.MM.yyyy').format(data.seedDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.seedDate,
                  // Hier wird das seedDate-Feld im Provider aktualisiert
                  (date) => dataNotifier
                      .update((state) => state.copyWith(seedDate: date))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data.germinationDate == null
                  ? 'Keimdatum'
                  : 'Keimung: ${DateFormat('dd.MM.yyyy').format(data.germinationDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.germinationDate,
                  // Hier wird das germinationDate-Feld im Provider aktualisiert
                  (date) => dataNotifier.update(
                      (state) => state.copyWith(germinationDate: date))),
            ),
          ],
        ),
      ),
    );
  }
}
