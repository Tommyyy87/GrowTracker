import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_tracker/data/models/plant.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart';

class PlantDetailActions extends ConsumerWidget {
  final Plant plant;

  const PlantDetailActions({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.eco,
                  label: 'Update Status',
                  onPressed: () => _showStatusUpdateDialog(context, ref),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.thermostat,
                  label: 'Add Reading',
                  onPressed: () {
                    // TODO: Implement Add Reading functionality
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.cut,
                  label: 'Harvest',
                  onPressed: () => _showHarvestConfirmationDialog(context, ref),
                ),
                // Add more actions as needed
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showHarvestConfirmationDialog(BuildContext context, WidgetRef ref) {
    if (plant.status == PlantStatus.harvest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This plant has already been harvested.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Harvest'),
          content: Text(
              'Are you sure you want to mark "${plant.name}" as harvested?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                ref
                    .read(plantControllerProvider.notifier)
                    .updatePlantStatus(plant.id, PlantStatus.harvest);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${plant.name} marked as harvested!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Select New Status'),
          children: PlantStatus.values.map((status) {
            return SimpleDialogOption(
              onPressed: () {
                ref
                    .read(plantControllerProvider.notifier)
                    .updatePlantStatus(plant.id, status);
                Navigator.of(dialogContext).pop();
              },
              child: Text(status.name),
            );
          }).toList(),
        );
      },
    );
  }
}
