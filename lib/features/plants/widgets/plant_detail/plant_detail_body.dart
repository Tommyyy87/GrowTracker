// lib/features/plants/widgets/plant_detail/plant_detail_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/harvest.dart';
import '../../../../data/models/plant.dart';
import '../../../../data/services/supabase_service.dart';
import '../../controllers/plant_controller.dart';
import '../dialogs/add_note_dialog.dart';
import '../harvest_section.dart';
import '../plant_info_card.dart';
import '../status_timeline.dart';

class PlantDetailBody extends ConsumerWidget {
  final Plant plant;
  final AsyncValue<List<Harvest>> harvestsAsync;

  const PlantDetailBody({
    super.key,
    required this.plant,
    required this.harvestsAsync,
  });

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    final controller = ref.read(plantControllerProvider.notifier);
    final photoPath = source == ImageSource.camera
        ? await controller.takePlantPhoto()
        : await controller.pickPlantPhoto();

    if (photoPath == null || !context.mounted) return;

    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Benutzer nicht angemeldet.'),
        backgroundColor: AppColors.errorColor,
      ));
      return;
    }

    try {
      final uploadedUrl = await ref
          .read(plantRepositoryProvider)
          .uploadPlantPhoto(userId, plant.id, photoPath);
      final updatedPlant = plant.copyWith(photoUrl: () => uploadedUrl);
      await controller.updatePlant(updatedPlant);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto erfolgreich aktualisiert!'),
          backgroundColor: AppColors.successColor,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler beim Hochladen des Fotos: $e'),
          backgroundColor: AppColors.errorColor,
        ));
      }
    }
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddNoteDialog(plant: plant),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlantInfoCard(plant: plant),
          const SizedBox(height: 16),
          StatusTimeline(plant: plant),
          const SizedBox(height: 16),
          harvestsAsync.when(
            data: (harvests) =>
                HarvestSection(plant: plant, harvests: harvests),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Fehler beim Laden der Ernte-Daten.'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (plant.notes != null && plant.notes!.isNotEmpty) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 20, color: AppColors.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Notizen',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plant.notes!,
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktionen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _addPhoto(context, ref),
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Foto ändern'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddNoteDialog(context),
                          icon: const Icon(Icons.note_add),
                          label: const Text('Notiz ändern'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
