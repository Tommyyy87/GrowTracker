// lib/features/plants/widgets/dialogs/delete_plant_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';

import '../../../../data/models/plant.dart';
import '../../controllers/plant_controller.dart';

class DeletePlantDialog extends ConsumerWidget {
  final Plant plant;

  const DeletePlantDialog({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Pflanze löschen'),
      content: Text(
          'Möchtest du "${plant.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () async {
            final controller = ref.read(plantControllerProvider.notifier);
            final success = await controller.deletePlant(plant.id);

            if (!context.mounted) return;
            Navigator.of(context).pop(); // Dialog schließen

            if (success) {
              context.goNamed('dashboard');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Pflanze wurde gelöscht'),
                    backgroundColor: AppColors.successColor),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fehler beim Löschen'),
                    backgroundColor: AppColors.errorColor),
              );
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Löschen'),
        ),
      ],
    );
  }
}
