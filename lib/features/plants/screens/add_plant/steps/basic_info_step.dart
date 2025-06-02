// lib/features/plants/screens/add_plant/steps/basic_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/plant.dart';
import '../../../widgets/selectable_choice_card.dart';
import '../add_plant_wizard.dart';

class BasicInfoStep extends ConsumerWidget {
  const BasicInfoStep({super.key});

  Future<void> _selectDate(
      BuildContext context,
      WidgetRef ref,
      DateTime? initialDate,
      void Function(DateTime) onDateSelectedInProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != initialDate) {
      onDateSelectedInProvider(picked);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _getPlantTypeIcon(PlantType type) {
    switch (type) {
      case PlantType.cannabis:
        return Icons.local_florist_outlined;
      case PlantType.tomato:
        return Icons
            .set_meal_outlined; // flutter pub add flutter_icons oder spezifisches Icon
      case PlantType.chili:
        return Icons.whatshot_outlined;
      case PlantType.herbs:
        return Icons.grass_outlined;
      case PlantType.other:
        return Icons.question_mark_outlined;
    }
  }

  IconData _getPlantStatusIcon(PlantStatus status) {
    switch (status) {
      case PlantStatus.seeded:
        return Icons.grain_outlined;
      case PlantStatus.germinated:
        return Icons.eco_outlined;
      case PlantStatus.vegetative:
        return Icons.energy_savings_leaf_outlined;
      case PlantStatus.flowering:
        return Icons.filter_vintage_outlined;
      case PlantStatus.harvest:
        return Icons.agriculture_outlined;
      case PlantStatus.drying:
        return Icons.wb_sunny_outlined;
      case PlantStatus.curing:
        return Icons.inventory_2_outlined;
      case PlantStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);
    final dataNotifier = ref.read(addPlantDataProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        // Optional: GlobalKey<FormState>() hier, wenn du pro Step validieren willst
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: data.name,
              decoration: const InputDecoration(
                labelText: 'Name der Pflanze*',
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              onChanged: (value) =>
                  dataNotifier.update((state) => state.copyWith(name: value)),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Name ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              // NEUES FELD FÜR BESITZERNAME
              initialValue: data.ownerName,
              decoration: const InputDecoration(
                labelText: 'Besitzername (optional)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (value) => dataNotifier.update((state) =>
                  state.copyWith(
                      ownerName: value.isEmpty ? null : value,
                      setOwnerNameNull: value.isEmpty)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.strain,
              decoration: const InputDecoration(
                labelText: 'Sorte/Strain*',
                prefixIcon: Icon(Icons.biotech_outlined),
              ),
              onChanged: (value) =>
                  dataNotifier.update((state) => state.copyWith(strain: value)),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Sorte ist erforderlich'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: data.breeder,
              decoration: const InputDecoration(
                labelText: 'Züchter/Marke (optional)',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              onChanged: (value) => dataNotifier.update((state) =>
                  state.copyWith(
                      breeder: value.isEmpty ? null : value,
                      setBreederNull: value.isEmpty)),
            ),
            _buildSectionTitle(context, 'Pflanzenart*'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: PlantType.values.map((type) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 3,
                  child: SelectableChoiceCard<PlantType>(
                    value: type,
                    groupValue: data.plantType,
                    onChanged: (value) => dataNotifier
                        .update((state) => state.copyWith(plantType: value)),
                    label: type.displayName,
                    icon: _getPlantTypeIcon(type),
                  ),
                );
              }).toList(),
            ),
            if (data.plantType == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Pflanzenart ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            _buildSectionTitle(context, 'Aktueller Status*'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: PlantStatus.values.map((status) {
                if (status == PlantStatus.drying ||
                    status == PlantStatus.curing ||
                    status == PlantStatus.completed) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 8) / 2,
                  child: SelectableChoiceCard<PlantStatus>(
                    value: status,
                    groupValue: data.initialStatus,
                    onChanged: (value) => dataNotifier.update(
                        (state) => state.copyWith(initialStatus: value)),
                    label: status.displayName,
                    icon: _getPlantStatusIcon(status),
                    subtitle: status.description.length > 40
                        ? '${status.description.substring(0, 37)}...'
                        : status.description,
                  ),
                );
              }).toList(),
            ),
            if (data.initialStatus == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Status ist erforderlich.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            _buildSectionTitle(context, 'Wichtige Daten (optional)'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(data.seedDate == null
                  ? 'Aussaatdatum'
                  : 'Aussaat: ${DateFormat('dd.MM.yyyy').format(data.seedDate!)}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.seedDate,
                  (date) => dataNotifier.update((state) =>
                      state.copyWith(seedDate: date, setSeedDateNull: false))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.spa_outlined),
              title: Text(data.germinationDate == null
                  ? 'Keimdatum'
                  : 'Keimung: ${DateFormat('dd.MM.yyyy').format(data.germinationDate!)}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () => _selectDate(
                  context,
                  ref,
                  data.germinationDate,
                  (date) => dataNotifier.update((state) => state.copyWith(
                      germinationDate: date, setGerminationDateNull: false))),
            ),
          ],
        ),
      ),
    );
  }
}
