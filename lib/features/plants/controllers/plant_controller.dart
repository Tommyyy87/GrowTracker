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
      final currentPlant = await _repository.getPlantById(plantId);
      if (currentPlant != null &&
          currentPlant.status != PlantStatus.harvest &&
          currentPlant.status != PlantStatus.drying &&
          currentPlant.status != PlantStatus.curing &&
          currentPlant.status != PlantStatus.completed) {
        await updatePlantStatus(plantId, PlantStatus.harvest);
      }
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

      // Erweiterte Statistiken für das neue Dashboard
      final activePlants = plants
          .where((p) =>
              p.status != PlantStatus.completed &&
              p.status != PlantStatus.harvest &&
              p.status != PlantStatus.drying &&
              p.status != PlantStatus.curing)
          .toList();

      final completedPlants =
          plants.where((p) => p.status == PlantStatus.completed).toList();

      final harvestingPlants = plants
          .where((p) =>
              p.status == PlantStatus.harvest ||
              p.status == PlantStatus.drying ||
              p.status == PlantStatus.curing)
          .toList();

      // Pflanzen die Aufmerksamkeit brauchen
      final harvestReady = plants
          .where((p) =>
              p.daysUntilHarvest != null &&
              p.daysUntilHarvest! <= 7 &&
              p.daysUntilHarvest! >= 0 &&
              p.status != PlantStatus.harvest &&
              p.status != PlantStatus.drying &&
              p.status != PlantStatus.curing &&
              p.status != PlantStatus.completed)
          .length;

      final overdue = plants
          .where((p) =>
              p.daysUntilHarvest != null &&
              p.daysUntilHarvest! < 0 &&
              p.status != PlantStatus.completed)
          .length;

      // Durchschnittsalter nur für aktive Pflanzen
      final activeAges = activePlants
          .where((p) => p.ageInDays >= 0)
          .map((p) => p.ageInDays)
          .toList();
      final averageAge = activeAges.isNotEmpty
          ? activeAges.reduce((a, b) => a + b) / activeAges.length
          : 0.0;

      // Wachstumstrends (simuliert für Demo)
      final thisWeekPlants = plants
          .where((p) => DateTime.now().difference(p.createdAt).inDays <= 7)
          .length;

      final lastWeekPlants = plants.where((p) {
        final daysSince = DateTime.now().difference(p.createdAt).inDays;
        return daysSince > 7 && daysSince <= 14;
      }).length;

      final growthTrend = thisWeekPlants - lastWeekPlants;

      return {
        'total': plants.length,
        'active': activePlants.length,
        'completed': completedPlants.length,
        'harvest': harvestingPlants.length,
        'harvestReady': harvestReady,
        'overdue': overdue,
        'averageAge': averageAge,
        'statusCounts': statusCounts,
        'growthTrend': growthTrend,
        'thisWeekPlants': thisWeekPlants,
        'lastWeekPlants': lastWeekPlants,

        // Zusätzliche Dashboard-Statistiken
        'plantsByType': _getPlantsByType(plants),
        'plantsByLocation': _getPlantsByLocation(plants),
        'upcomingHarvests': _getUpcomingHarvests(plants),
        'healthyPlants': _getHealthyPlantsCount(plants),
        'needsAttention': _getPlantsNeedingAttention(plants).length,
      };
    } catch (e) {
      debugPrint('Error getting plant stats: $e');
      return {};
    }
  }

  Map<String, int> _getPlantsByType(List<Plant> plants) {
    final typeCount = <String, int>{};
    for (final plant in plants) {
      final type = plant.plantType.displayName;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    return typeCount;
  }

  Map<String, int> _getPlantsByLocation(List<Plant> plants) {
    final locationCount = <String, int>{};
    for (final plant in plants) {
      final location = plant.location.displayName;
      locationCount[location] = (locationCount[location] ?? 0) + 1;
    }
    return locationCount;
  }

  List<Map<String, dynamic>> _getUpcomingHarvests(List<Plant> plants) {
    final upcoming = plants
        .where((p) =>
            p.daysUntilHarvest != null &&
            p.daysUntilHarvest! > 0 &&
            p.daysUntilHarvest! <= 30)
        .toList();

    upcoming.sort((a, b) => a.daysUntilHarvest!.compareTo(b.daysUntilHarvest!));

    return upcoming
        .take(5)
        .map((plant) => {
              'plantId': plant.id,
              'name': plant.name,
              'daysUntilHarvest': plant.daysUntilHarvest,
              'estimatedHarvestDate':
                  plant.estimatedHarvestDate?.toIso8601String(),
            })
        .toList();
  }

  int _getHealthyPlantsCount(List<Plant> plants) {
    return plants.where((plant) {
      // Definiere "gesund" als Pflanzen ohne Probleme
      final hasOverdueHarvest =
          plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0;
      final hasLongUpdate =
          DateTime.now().difference(plant.updatedAt).inDays > 14;

      return !hasOverdueHarvest && !hasLongUpdate;
    }).length;
  }

  List<Plant> _getPlantsNeedingAttention(List<Plant> plants) {
    return plants.where((plant) {
      // Überfällige Ernten
      if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
        return true;
      }

      // Lange keine Updates
      final daysSinceUpdate = DateTime.now().difference(plant.updatedAt).inDays;
      if (daysSinceUpdate > 14 && plant.status != PlantStatus.completed) {
        return true;
      }

      // Bald erntereif
      if (plant.daysUntilHarvest != null &&
          plant.daysUntilHarvest! <= 7 &&
          plant.daysUntilHarvest! >= 0 &&
          plant.status != PlantStatus.harvest) {
        return true;
      }

      return false;
    }).toList();
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

  Future<List<Plant>> getPlantsNeedingAttention() async {
    try {
      final plants = await _repository.getAllPlants();
      return _getPlantsNeedingAttention(plants);
    } catch (e) {
      debugPrint('Error getting plants needing attention: $e');
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

final plantsNeedingAttentionProvider = FutureProvider<List<Plant>>((ref) async {
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantsNeedingAttention();
});
