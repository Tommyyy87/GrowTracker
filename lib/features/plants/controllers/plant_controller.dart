// lib/features/plants/controllers/plant_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../data/services/supabase_service.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repository = ref.read(plantRepositoryProvider);
  final plants = await repository.getAllPlants();
  plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return plants;
});

final plantDetailProvider =
    FutureProvider.family<Plant?, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getPlantById(plantId);
});

class PlantController extends StateNotifier<AsyncValue<List<Plant>>> {
  PlantController(this._repository, this.ref)
      : super(const AsyncValue.loading()) {
    loadPlants();
  }

  final PlantRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();
  final Ref ref;

  Future<void> loadPlants() async {
    try {
      state = const AsyncValue.loading();
      final plants = await _repository.getAllPlants();
      plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(plants);
    } catch (error, stackTrace) {
      debugPrint('Error loading plants in controller: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Plant?> createPlant({
    required String name,
    required PlantType plantType,
    required String strain,
    String? breeder,
    DateTime? seedDate,
    DateTime? germinationDate,
    required DateTime documentationStartDate,
    required PlantMedium medium,
    required PlantLocation location,
    PlantStatus initialStatus = PlantStatus.seeded,
    int? estimatedHarvestDays,
    String? notes,
    String? photoPath,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      debugPrint('Error creating plant: User not authenticated');
      throw Exception('User not authenticated');
    }

    Plant plantToCreate = Plant.create(
      name: name,
      plantType: plantType,
      strain: strain,
      breeder: breeder,
      seedDate: seedDate,
      germinationDate: germinationDate,
      documentationStartDate: documentationStartDate,
      medium: medium,
      location: location,
      status: initialStatus,
      estimatedHarvestDays: estimatedHarvestDays,
      notes: notes,
      photoUrl: null,
      userId: userId,
    );

    try {
      Plant createdPlant = await _repository.createPlant(plantToCreate);
      debugPrint('Plant record created with ID: ${createdPlant.id}');

      String? uploadedPhotoUrl;
      if (photoPath != null && photoPath.isNotEmpty) {
        try {
          uploadedPhotoUrl = await _repository.uploadPlantPhoto(
              userId, createdPlant.id, photoPath);
          debugPrint('Photo uploaded, URL: $uploadedPhotoUrl');
        } catch (e) {
          debugPrint('Error uploading photo during plant creation: $e');
        }
      }

      if (uploadedPhotoUrl != null) {
        // Korrekter Aufruf von copyWith für photoUrl
        Plant plantWithPhoto =
            createdPlant.copyWith(photoUrl: () => uploadedPhotoUrl);
        createdPlant = await _repository.updatePlant(plantWithPhoto);
        debugPrint('Plant record updated with photoUrl');
      }

      ref.invalidate(plantsProvider);
      ref.invalidate(plantDetailProvider(createdPlant.id));
      ref.invalidate(plantStatsProvider);
      return createdPlant;
    } catch (e) {
      debugPrint('Error creating plant in PlantController: $e');
      rethrow;
    }
  }

  Future<bool> updatePlant(Plant plant) async {
    try {
      await _repository.updatePlant(plant);
      ref.invalidate(plantsProvider);
      ref.invalidate(plantDetailProvider(plant.id));
      ref.invalidate(plantStatsProvider);
      return true;
    } catch (e) {
      debugPrint('Error updating plant: $e');
      return false;
    }
  }

  Future<bool> updatePlantStatus(String plantId, PlantStatus newStatus) async {
    try {
      final plant = await _repository.getPlantById(plantId);
      if (plant == null) {
        return false;
      }
      final updatedPlant = plant.copyWith(status: newStatus);
      final success = await updatePlant(updatedPlant);
      if (success) {
        if (newStatus == PlantStatus.harvest ||
            newStatus == PlantStatus.drying ||
            newStatus == PlantStatus.completed ||
            newStatus == PlantStatus.curing) {
          ref.invalidate(plantHarvestsProvider(plantId));
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error updating plant status: $e');
      return false;
    }
  }

  Future<bool> updateHarvestEstimate(String plantId, int? estimatedDays) async {
    try {
      final plant = await _repository.getPlantById(plantId);
      if (plant == null) {
        return false;
      }
      // Korrekter Aufruf von copyWith für estimatedHarvestDays
      final updatedPlant =
          plant.copyWith(estimatedHarvestDays: () => estimatedDays);
      return await updatePlant(updatedPlant);
    } catch (e) {
      debugPrint('Error updating harvest estimate: $e');
      return false;
    }
  }

  Future<bool> deletePlant(String plantId) async {
    try {
      await _repository.deletePlant(plantId);
      ref.invalidate(plantsProvider);
      ref.invalidate(plantStatsProvider);
      return true;
    } catch (e) {
      debugPrint('Error deleting plant: $e');
      return false;
    }
  }

  Future<String?> takePlantPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85);
      return photo?.path;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  Future<String?> pickPlantPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85);
      return photo?.path;
    } catch (e) {
      debugPrint('Error picking photo: $e');
      return null;
    }
  }

  Future<bool> addHarvest({
    required String plantId,
    double? freshWeight,
    double? dryWeight,
    WeightUnit unit = WeightUnit.grams,
    required DateTime harvestDate,
    DateTime? dryingCompletedDate,
    String? notes,
  }) async {
    try {
      final harvest = Harvest.create(
        plantId: plantId,
        freshWeight: freshWeight,
        dryWeight: dryWeight,
        unit: unit,
        harvestDate: harvestDate,
        dryingCompletedDate: dryingCompletedDate,
        notes: notes,
      );
      await _repository.saveHarvest(harvest);
      ref.invalidate(plantHarvestsProvider(plantId));
      PlantStatus newStatus;
      if (dryWeight != null && dryingCompletedDate != null) {
        newStatus = PlantStatus.completed;
      } else if (dryWeight != null) {
        newStatus = PlantStatus.curing;
      } else {
        newStatus = PlantStatus.drying;
      }
      // Setze auch den Status der Pflanze auf "Ernte", wenn noch nicht geschehen
      final currentPlant = await _repository.getPlantById(plantId);
      if (currentPlant != null &&
          currentPlant.status != PlantStatus.harvest &&
          currentPlant.status != PlantStatus.drying &&
          currentPlant.status != PlantStatus.curing &&
          currentPlant.status != PlantStatus.completed) {
        await updatePlantStatus(plantId, PlantStatus.harvest);
      }
      // Dann den spezifischeren Status
      await updatePlantStatus(plantId, newStatus);
      return true;
    } catch (e) {
      debugPrint('Error adding harvest: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPlantStats() async {
    try {
      final plants = await _repository.getAllPlants();
      final statusCounts = await _repository.getPlantCountsByStatus();
      return {
        'total': plants.length,
        'active': plants
            .where((p) =>
                p.status != PlantStatus.completed &&
                p.status != PlantStatus.harvest &&
                p.status != PlantStatus.drying &&
                p.status != PlantStatus.curing)
            .length,
        'harvest': plants
            .where((p) =>
                p.status == PlantStatus.harvest ||
                p.status == PlantStatus.drying ||
                p.status == PlantStatus.curing)
            .length,
        'completed':
            plants.where((p) => p.status == PlantStatus.completed).length,
        'statusCounts': statusCounts,
        'averageAge': plants.isNotEmpty && plants.any((p) => p.ageInDays >= 0)
            ? plants
                    .where((p) => p.ageInDays >= 0)
                    .map((p) => p.ageInDays)
                    .reduce((a, b) => a + b) /
                plants.where((p) => p.ageInDays >= 0).length
            : 0,
        'harvestReady': plants
            .where((p) =>
                p.daysUntilHarvest != null &&
                p.daysUntilHarvest! <= 7 &&
                p.daysUntilHarvest! >= 0 &&
                p.status != PlantStatus.harvest &&
                p.status != PlantStatus.drying &&
                p.status != PlantStatus.curing &&
                p.status != PlantStatus.completed)
            .length,
      };
    } catch (e) {
      debugPrint('Error getting plant stats: $e');
      return {};
    }
  }

  Future<List<Plant>> getPlantsNearHarvest({int daysThreshold = 7}) async {
    try {
      final plants = await _repository.getAllPlants();
      return plants.where((plant) {
        final daysLeft = plant.daysUntilHarvest;
        return daysLeft != null &&
            daysLeft >= 0 &&
            daysLeft <= daysThreshold &&
            plant.status != PlantStatus.harvest &&
            plant.status != PlantStatus.drying &&
            plant.status != PlantStatus.curing &&
            plant.status != PlantStatus.completed;
      }).toList();
    } catch (e) {
      debugPrint('Error getting plants near harvest: $e');
      return [];
    }
  }
}

final plantControllerProvider =
    StateNotifierProvider<PlantController, AsyncValue<List<Plant>>>((ref) {
  final repository = ref.read(plantRepositoryProvider);
  return PlantController(repository, ref);
});

final plantHarvestsProvider =
    FutureProvider.family<List<Harvest>, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getHarvestsForPlant(plantId);
});

final plantStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantStats();
});

final plantsNearHarvestProvider = FutureProvider<List<Plant>>((ref) async {
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantsNearHarvest();
});
