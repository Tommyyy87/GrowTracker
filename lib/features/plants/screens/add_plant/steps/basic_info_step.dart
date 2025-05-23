// lib/features/plants/screens/add_plant/steps/basic_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/plant.dart';
import '../add_plant_wizard.dart';

class BasicInfoStep extends ConsumerStatefulWidget {
  const BasicInfoStep({super.key});

  @override
  ConsumerState<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends ConsumerState<BasicInfoStep> {
  final _nameController = TextEditingController();
  final _strainController = TextEditingController();
  final _breederController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(addPlantDataProvider);
    _nameController.text = data.name ?? '';
    _strainController.text = data.strain ?? '';
    _breederController.text = data.breeder ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strainController.dispose();
    _breederController.dispose();
    super.dispose();
  }

  void _updateData() {
    ref.read(addPlantDataProvider.notifier).update((state) => state
      ..name = _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim()
      ..strain = _strainController.text.trim().isEmpty
          ? null
          : _strainController.text.trim()
      ..breeder = _breederController.text.trim().isEmpty
          ? null
          : _breederController.text.trim());
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
              'Gib die grundlegenden Informationen zu deiner Pflanze ein.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Name
            TextField(
              controller: _nameController,
              onChanged: (_) => _updateData(),
              decoration: InputDecoration(
                labelText: 'Name der Pflanze *',
                hintText: 'z.B. Meine White Widow #1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.eco_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Pflanzentyp
            Text(
              'Pflanzenart *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PlantType.values.map((type) {
                final isSelected = data.plantType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(addPlantDataProvider.notifier).update(
                        (state) => state..plantType = selected ? type : null);
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

            // Sorte/Genetik
            TextField(
              controller: _strainController,
              onChanged: (_) => _updateData(),
              decoration: InputDecoration(
                labelText: 'Sorte/Genetik *',
                hintText: 'z.B. White Widow, Cherry Tomaten',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.local_florist_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Hersteller (optional)
            TextField(
              controller: _breederController,
              onChanged: (_) => _updateData(),
              decoration: InputDecoration(
                labelText: 'Hersteller/Saatgut-Anbieter',
                hintText: 'z.B. Royal Queen Seeds, Kiepenkerl',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 32),

            // Hinweis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipp',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wähle einen eindeutigen Namen, damit du deine Pflanzen später leicht unterscheiden kannst.',
                          style: TextStyle(
                            color: Colors.blue.shade600,
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
