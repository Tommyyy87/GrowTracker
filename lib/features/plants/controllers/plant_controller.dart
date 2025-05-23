// lib/features/plants/controllers/plant_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/plant.dart';
import '../../../data/models/harvest.dart';
import '../../../data/repositories/plant_repository.dart';
import '../../../data/services/supabase_service.dart';

// Plant Repository Provider
final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

// Plants List Provider
final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getAllPlants();
});

// Plant Detail Provider
final plantDetailProvider =
    FutureProvider.family<Plant?, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getPlantById(plantId);
});

// Plant Controller für State Management
class PlantController extends StateNotifier<AsyncValue<List<Plant>>> {
  PlantController(this._repository) : super(const AsyncValue.loading()) {
    loadPlants();
  }

  final PlantRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();

  // Alle Pflanzen laden
  Future<void> loadPlants() async {
    try {
      state = const AsyncValue.loading();
      final plants = await _repository.getAllPlants();
      state = AsyncValue.data(plants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Neue Pflanze erstellen
  Future<Plant?> createPlant({
    required String name,
    required PlantType plantType,
    required String strain,
    String? breeder,
    required DateTime plantedDate,
    required PlantMedium medium,
    required PlantLocation location,
    String? notes,
    String? photoPath,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Foto hochladen falls vorhanden
      String? photoUrl;
      if (photoPath != null) {
        // Hier würde normalerweise das Foto hochgeladen werden
        // photoUrl = await _repository.uploadPlantPhoto(tempId, photoPath);
        // Für jetzt setzen wir nur den lokalen Pfad
        photoUrl = photoPath;
      }

      final plant = Plant.create(
        name: name,
        plantType: plantType,
        strain: strain,
        breeder: breeder,
        plantedDate: plantedDate,
        medium: medium,
        location: location,
        notes: notes,
        photoUrl: photoUrl,
        userId: userId,
      );

      final createdPlant = await _repository.createPlant(plant);

      // Liste aktualisieren
      await loadPlants();

      return createdPlant;
    } catch (e) {
      debugPrint('Error creating plant: $e');
      return null;
    }
  }

  // Pflanze aktualisieren
  Future<bool> updatePlant(Plant plant) async {
    try {
      await _repository.updatePlant(plant);
      await loadPlants();
      return true;
    } catch (e) {
      debugPrint('Error updating plant: $e');
      return false;
    }
  }

  // Pflanzenstatus ändern
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

  // Pflanze löschen
  Future<bool> deletePlant(String plantId) async {
    try {
      await _repository.deletePlant(plantId);
      await loadPlants();
      return true;
    } catch (e) {
      debugPrint('Error deleting plant: $e');
      return false;
    }
  }

  // Foto aus Kamera aufnehmen
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

  // Foto aus Galerie auswählen
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

  // Ernte dokumentieren
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

      // Pflanzenstatus auf "harvest" oder "drying" setzen
      if (dryWeight != null) {
        await updatePlantStatus(plantId, PlantStatus.completed);
      } else {
        await updatePlantStatus(plantId, PlantStatus.drying);
      }

      return true;
    } catch (e) {
      debugPrint('Error adding harvest: $e');
      return false;
    }
  }

  // Statistiken abrufen
  Future<Map<String, dynamic>> getPlantStats() async {
    try {
      final plants = await _repository.getAllPlants();
      final statusCounts = await _repository.getPlantCountsByStatus();

      return {
        'total': plants.length,
        'active': plants.where((p) => p.status != PlantStatus.completed).length,
        'completed':
            plants.where((p) => p.status == PlantStatus.completed).length,
        'statusCounts': statusCounts,
        'averageAge': plants.isNotEmpty
            ? plants.map((p) => p.ageInDays).reduce((a, b) => a + b) /
                plants.length
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting plant stats: $e');
      return {};
    }
  }
}

// Plant Controller Provider
final plantControllerProvider =
    StateNotifierProvider<PlantController, AsyncValue<List<Plant>>>((ref) {
  final repository = ref.read(plantRepositoryProvider);
  return PlantController(repository);
});

// Harvest Provider für eine bestimmte Pflanze
final plantHarvestsProvider =
    FutureProvider.family<List<Harvest>, String>((ref, plantId) async {
  final repository = ref.read(plantRepositoryProvider);
  return repository.getHarvestsForPlant(plantId);
});

// Plant Stats Provider
final plantStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final controller = ref.read(plantControllerProvider.notifier);
  return controller.getPlantStats();
});
