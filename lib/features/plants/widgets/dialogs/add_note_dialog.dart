// lib/features/plants/widgets/dialogs/add_note_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';

import '../../../../data/models/plant.dart';
import '../../controllers/plant_controller.dart';

class AddNoteDialog extends ConsumerStatefulWidget {
  final Plant plant;

  const AddNoteDialog({
    super.key,
    required this.plant,
  });

  @override
  ConsumerState<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<AddNoteDialog> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.plant.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final controller = ref.read(plantControllerProvider.notifier);
    final newNotes = _notesController.text.trim();
    final updatedPlant =
        widget.plant.copyWith(notes: () => newNotes.isEmpty ? null : newNotes);
    final success = await controller.updatePlant(updatedPlant);

    if (!mounted) return;
    Navigator.of(context).pop(); // Dialog schließen

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? 'Notizen gespeichert!' : 'Fehler beim Speichern.'),
        backgroundColor:
            success ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notizen bearbeiten'),
      content: TextField(
        controller: _notesController,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Notizen',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
