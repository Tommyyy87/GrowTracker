// lib/features/plants/widgets/dialogs/harvest_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../../controllers/plant_controller.dart';

class HarvestDialog extends ConsumerStatefulWidget {
  final String plantId;

  const HarvestDialog({
    super.key,
    required this.plantId,
  });

  @override
  ConsumerState<HarvestDialog> createState() => _HarvestDialogState();
}

class _HarvestDialogState extends ConsumerState<HarvestDialog> {
  final _freshWeightController = TextEditingController();
  final _dryWeightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedHarvestDate = DateTime.now();
  DateTime? _selectedDryingCompletedDate;

  @override
  void dispose() {
    _freshWeightController.dispose();
    _dryWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedHarvestDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedHarvestDate) {
      setState(() {
        _selectedHarvestDate = picked;
      });
    }
  }

  Future<void> _pickDryingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDryingCompletedDate ?? DateTime.now(),
      firstDate: _selectedHarvestDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDryingCompletedDate) {
      setState(() {
        _selectedDryingCompletedDate = picked;
      });
    }
  }

  Future<void> _saveHarvest() async {
    final controller = ref.read(plantControllerProvider.notifier);
    final success = await controller.addHarvest(
      plantId: widget.plantId,
      freshWeight:
          double.tryParse(_freshWeightController.text.replaceAll(',', '.')),
      dryWeight:
          double.tryParse(_dryWeightController.text.replaceAll(',', '.')),
      harvestDate: _selectedHarvestDate,
      dryingCompletedDate: _selectedDryingCompletedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Dialog schließen

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Ernte dokumentiert!'
            : 'Fehler beim Speichern der Ernte'),
        backgroundColor:
            success ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ernte dokumentieren'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                  "Erntedatum: ${DateFormat('dd.MM.yyyy').format(_selectedHarvestDate)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickHarvestDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _freshWeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Frischgewicht (g)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDryingCompletedDate == null
                  ? "Trocknung abgeschlossen am (optional)"
                  : "Trocknung abgeschlossen: ${DateFormat('dd.MM.yyyy').format(_selectedDryingCompletedDate!)}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDryingDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dryWeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Trockengewicht (g) - optional',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Notizen - optional',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveHarvest,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
