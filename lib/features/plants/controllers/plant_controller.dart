// lib/features/plants/controllers/plant_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:uuid/uuid.dart'; // Für Uuid().v4()

import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../data/services/supabase_service.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getAllPlants();
});

final plantDetailProvider =
    FutureProvider.family<Plant?, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getPlantById(plantId);
});

class PlantController extends StateNotifier<AsyncValue<List<Plant>>> {
  PlantController(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    // _ref hinzugefügt
    loadPlants();
  }

  final PlantRepository _repository;
  final Ref _ref; // Ref speichern
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> loadPlants() async {
    try {
      state = const AsyncValue.loading();
      final plants = await _repository.getAllPlants();
      state = AsyncValue.data(plants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      debugPrint('Error loading plants in controller: $error');
    }
  }

  Future<Plant?> createPlant({
    required String name,
    required PlantType plantType,
    required String strain,
    String? breeder,
    DateTime? seedDate,
    DateTime? germinationDate,
    required DateTime plantedDate,
    required PlantMedium medium,
    required PlantLocation location,
    PlantStatus initialStatus = PlantStatus.seeded,
    int? estimatedHarvestDays,
    String? notes,
    String? photoPath,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('User not authenticated for creating plant.');
        throw Exception('User not authenticated');
      }

      String? photoUrlToSave = photoPath;
      // if (photoPath != null && photoPath.isNotEmpty) {
      //   final plantIdForPhoto = const Uuid().v4();
      //   photoUrlToSave = await _repository.uploadPlantPhoto(plantIdForPhoto, photoPath);
      // }

      final plant = Plant.create(
        name: name,
        plantType: plantType,
        strain: strain,
        breeder: breeder,
        seedDate: seedDate,
        germinationDate: germinationDate,
        plantedDate: plantedDate,
        medium: medium,
        location: location,
        status: initialStatus,
        estimatedHarvestDays: estimatedHarvestDays,
        notes: notes,
        photoUrl: photoUrlToSave,
        userId: userId,
      );

      final createdPlant = await _repository.createPlant(plant);
      await loadPlants();
      _ref.invalidate(plantsProvider); // _ref verwenden
      _ref.invalidate(plantStatsProvider); // _ref verwenden
      return createdPlant;
    } catch (e) {
      debugPrint('Error creating plant in PlantController: $e');
      return null;
    }
  }

  Future<bool> updatePlant(Plant plant) async {
    try {
      await _repository.updatePlant(plant);
      await loadPlants();
      _ref.invalidate(plantDetailProvider(plant.id)); // _ref verwenden
      _ref.invalidate(plantsProvider); // _ref verwenden
      _ref.invalidate(plantStatsProvider); // _ref verwenden
      return true;
    } catch (e) {
      debugPrint('Error updating plant: $e');
      return false;
    }
  }

  Future<bool> updatePlantStatus(String plantId, PlantStatus newStatus) async {
    try {
      final plant = await _repository.getPlantById(plantId);
      if (plant == null) return false;

      final updatedPlant = plant.copyWith(status: newStatus);
      return await updatePlant(updatedPlant);
    } catch (e) {
      debugPrint('Error updating plant status: $e');
      return false;
    }
  }

  Future<bool> updateHarvestEstimate(String plantId, int? estimatedDays) async {
    try {
      final plant = await _repository.getPlantById(plantId);
      if (plant == null) return false;

      final updatedPlant = plant.copyWith(estimatedHarvestDays: estimatedDays);
      return await updatePlant(updatedPlant);
    } catch (e) {
      debugPrint('Error updating harvest estimate: $e');
      return false;
    }
  }

  Future<bool> deletePlant(String plantId) async {
    try {
      await _repository.deletePlant(plantId);
      await loadPlants();
      _ref.invalidate(plantsProvider); // _ref verwenden
      _ref.invalidate(plantStatsProvider); // _ref verwenden
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
        imageQuality: 85,
      );
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
        imageQuality: 85,
      );
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
      if (dryWeight != null) {
        await updatePlantStatus(plantId, PlantStatus.completed);
      } else {
        await updatePlantStatus(plantId, PlantStatus.drying);
      }
      _ref.invalidate(plantHarvestsProvider(plantId)); // _ref verwenden
      _ref.invalidate(plantDetailProvider(plantId)); // _ref verwenden
      return true;
    } catch (e) {
      debugPrint('Error adding harvest: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPlantStats() async {
    try {
      final plants = await _repository.getAllPlants();
      if (plants.isEmpty) {
        return {
          'total': 0,
          'active': 0,
          'completed': 0,
          'statusCounts': <PlantStatus, int>{
            for (var v in PlantStatus.values) v: 0
          },
          'averageAge': 0.0,
          'harvestReady': 0,
        };
      }
      final statusCounts = <PlantStatus, int>{};
      for (final status in PlantStatus.values) {
        statusCounts[status] = plants
            .where((p) => p.status == status)
            .length; // Korrigiert zu statusCounts
      }

      double totalAge = 0;
      if (plants.isNotEmpty) {
        totalAge =
            plants.map((p) => p.ageInDays).reduce((a, b) => a + b).toDouble();
      }

      return {
        'total': plants.length,
        'active': plants
            .where((p) =>
                p.status != PlantStatus.completed &&
                p.status != PlantStatus.drying &&
                p.status != PlantStatus.curing)
            .length,
        'completed':
            plants.where((p) => p.status == PlantStatus.completed).length,
        'statusCounts': statusCounts,
        'averageAge': plants.isNotEmpty ? totalAge / plants.length : 0.0,
        'harvestReady': plants
            .where((p) =>
                p.daysUntilHarvest != null &&
                p.daysUntilHarvest! <= 7 &&
                p.daysUntilHarvest! >= 0)
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
        return daysLeft != null && daysLeft >= 0 && daysLeft <= daysThreshold;
      }).toList();
    } catch (e) {
      debugPrint('Error getting plants near harvest: $e');
      return [];
    }
  }
}

final plantControllerProvider =
    StateNotifierProvider<PlantController, AsyncValue<List<Plant>>>((ref) {
  // ref ist hier verfügbar
  final repository = ref.read(plantRepositoryProvider);
  return PlantController(repository, ref); // ref an den Konstruktor übergeben
});

final plantHarvestsProvider =
    FutureProvider.family<List<Harvest>, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getHarvestsForPlant(plantId);
});

final plantStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  await ref.watch(plantsProvider.future);
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantStats();
});

final plantsNearHarvestProvider = FutureProvider<List<Plant>>((ref) async {
  await ref.watch(plantsProvider.future);
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantsNearHarvest();
});
