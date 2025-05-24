// lib/features/plants/screens/add_plant/steps/cultivation_details_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/plant.dart'; // Für Enums
import '../../../widgets/selectable_choice_card.dart'; // Importiere das neue Widget
import '../add_plant_wizard.dart'; // Stellt AddPlantData und Provider bereit

class CultivationDetailsStep extends ConsumerWidget {
  const CultivationDetailsStep({super.key});

  Future<void> _selectDate(BuildContext context, WidgetRef ref,
      DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  // Helper-Methode zum Erstellen der Label für die Kachel-Sektionen
  Widget _buildSectionTitle(BuildContext context, String title,
      {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isOptional)
            Text(
              ' (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.normal, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  // Helper-Methoden für Icons (Beispiele)
  IconData _getPlantMediumIcon(PlantMedium medium) {
    switch (medium) {
      case PlantMedium.soil:
        return Icons.terrain_outlined;
      case PlantMedium.coco:
        return Icons.eco_outlined; // Generisch, da kein spezifisches Coco-Icon
      case PlantMedium.hydro:
        return Icons.water_drop_outlined;
      case PlantMedium.rockwool:
        return Icons.grid_on_outlined; // Generisch
    }
  }

  IconData _getPlantLocationIcon(PlantLocation location) {
    switch (location) {
      case PlantLocation.indoor:
        return Icons.home_outlined;
      case PlantLocation.outdoor:
        return Icons.wb_sunny_outlined;
      case PlantLocation.greenhouse:
        return Icons.villa_outlined; // Ähnelt einem Gewächshaus
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);
    final dataNotifier = ref.read(addPlantDataProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start der Dokumentation*',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Ab diesem Datum wird das Alter der Pflanze berechnet. Relevant, falls kein Aussaat- oder Keimdatum im vorherigen Schritt angegeben wurde.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_note_outlined),
              title: Text(data.documentationStartDate == null
                  ? 'Dokumentationsstart wählen*'
                  : 'Start: ${DateFormat('dd.MM.yyyy').format(data.documentationStartDate!)}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.documentationStartDate,
                  (date) => dataNotifier.update(
                      (state) => state.copyWith(documentationStartDate: date))),
            ),
            if (data.documentationStartDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Dokumentationsstart ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),

            // Anbaumedium Auswahl
            _buildSectionTitle(context, 'Anbaumedium*'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: PlantMedium.values.map((medium) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 8) /
                      2, // 2 Kacheln
                  child: SelectableChoiceCard<PlantMedium>(
                    value: medium,
                    groupValue: data.medium,
                    onChanged: (value) => dataNotifier
                        .update((state) => state.copyWith(medium: value)),
                    label: medium.displayName,
                    icon: _getPlantMediumIcon(medium),
                  ),
                );
              }).toList(),
            ),
            if (data.medium == null) // Validierungsnachricht
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Anbaumedium ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),

            // Standort Auswahl
            _buildSectionTitle(context, 'Standort*'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: PlantLocation.values.map((location) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) /
                      3, // 3 Kacheln
                  child: SelectableChoiceCard<PlantLocation>(
                    value: location,
                    groupValue: data.location,
                    onChanged: (value) => dataNotifier
                        .update((state) => state.copyWith(location: value)),
                    label: location.displayName,
                    icon: _getPlantLocationIcon(location),
                  ),
                );
              }).toList(),
            ),
            if (data.location == null) // Validierungsnachricht
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Standort ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 20),
            TextFormField(
              initialValue: data.estimatedHarvestDays?.toString(),
              decoration: const InputDecoration(
                  labelText: 'Geschätzte Tage bis Ernte (optional)',
                  prefixIcon: Icon(Icons.timelapse_outlined),
                  hintText: 'z.B. 60'),
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
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'Besondere Vorkommnisse, Düngeschema etc.'),
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
