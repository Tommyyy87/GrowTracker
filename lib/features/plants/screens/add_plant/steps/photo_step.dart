// lib/features/plants/screens/add_plant/steps/photo_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../add_plant_wizard.dart';
import '../../../controllers/plant_controller.dart'; // Für ImagePicker Methoden

class PhotoStep extends ConsumerWidget {
  const PhotoStep({super.key});

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final plantController = ref.read(plantControllerProvider.notifier);
    String? path;
    if (source == ImageSource.camera) {
      path = await plantController.takePlantPhoto();
    } else {
      path = await plantController.pickPlantPhoto();
    }

    // Update photoPath, auch wenn path null ist (um es zu löschen)
    ref.read(addPlantDataProvider.notifier).update((state) =>
        state.copyWith(photoPath: path, setPhotoPathNull: path == null));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(addPlantDataProvider);
    final dataNotifier = ref.read(addPlantDataProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: data.photoPath != null && data.photoPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(data.photoPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image_search_rounded,
                        size: 60, color: Colors.grey)),
          ),
          const SizedBox(height: 20),
          if (data.photoPath != null && data.photoPath!.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.errorColor),
              label: const Text('Foto entfernen',
                  style: TextStyle(color: AppColors.errorColor)),
              onPressed: () => dataNotifier.update((state) =>
                  state.copyWith(photoPath: null, setPhotoPathNull: true)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Galerie'),
                  onPressed: () => _pickImage(ref, ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Kamera'),
                  onPressed: () => _pickImage(ref, ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ein Foto hilft dir, deine Pflanze später leichter wiederzuerkennen. (Optional)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
