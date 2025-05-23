// lib/data/repositories/plant_repository.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/plant.dart';
import '../models/harvest.dart';
import '../services/supabase_service.dart';

class PlantRepository {
  final _supabase = SupabaseService.client;

  // Alle Pflanzen des Benutzers abrufen
  Future<List<Plant>> getAllPlants() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('plants')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching plants: $e');
      rethrow;
    }
  }

  // Einzelne Pflanze abrufen
  Future<Plant?> getPlantById(String plantId) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('plants')
          .select()
          .eq('id', plantId)
          .eq('user_id', userId)
          .single();

      return Plant.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching plant: $e');
      return null;
    }
  }

  // Pflanze erstellen
  Future<Plant> createPlant(Plant plant) async {
    try {
      final response = await _supabase
          .from('plants')
          .insert(plant.toJson())
          .select()
          .single();

      return Plant.fromJson(response);
    } catch (e) {
      debugPrint('Error creating plant: $e');
      rethrow;
    }
  }

  // Pflanze aktualisieren
  Future<Plant> updatePlant(Plant plant) async {
    try {
      final response = await _supabase
          .from('plants')
          .update(plant.toJson())
          .eq('id', plant.id)
          .eq('user_id', plant.userId)
          .select()
          .single();

      return Plant.fromJson(response);
    } catch (e) {
      debugPrint('Error updating plant: $e');
      rethrow;
    }
  }

  // Pflanze löschen
  Future<void> deletePlant(String plantId) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('plants')
          .delete()
          .eq('id', plantId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting plant: $e');
      rethrow;
    }
  }

  // Pflanzen nach Status filtern
  Future<List<Plant>> getPlantsByStatus(PlantStatus status) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('plants')
          .select()
          .eq('user_id', userId)
          .eq('status', status.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching plants by status: $e');
      rethrow;
    }
  }

  // Pflanzen nach Typ filtern
  Future<List<Plant>> getPlantsByType(PlantType type) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('plants')
          .select()
          .eq('user_id', userId)
          .eq('plant_type', type.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching plants by type: $e');
      rethrow;
    }
  }

  // Ernte-Daten abrufen
  Future<List<Harvest>> getHarvestsForPlant(String plantId) async {
    try {
      final response = await _supabase
          .from('harvests')
          .select()
          .eq('plant_id', plantId)
          .order('harvest_date', ascending: false);

      return (response as List)
          .map((json) => Harvest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching harvests: $e');
      rethrow;
    }
  }

  // Ernte erstellen/aktualisieren
  Future<Harvest> saveHarvest(Harvest harvest) async {
    try {
      final response = await _supabase
          .from('harvests')
          .upsert(harvest.toJson())
          .select()
          .single();

      return Harvest.fromJson(response);
    } catch (e) {
      debugPrint('Error saving harvest: $e');
      rethrow;
    }
  }

  // Foto hochladen
  Future<String> uploadPlantPhoto(String plantId, String filePath) async {
    try {
      final fileName =
          '${plantId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('plant-photos')
          .upload('$plantId/$fileName', File(filePath));

      final publicUrl = _supabase.storage
          .from('plant-photos')
          .getPublicUrl('$plantId/$fileName');

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  // Anzahl der Pflanzen pro Status
  Future<Map<PlantStatus, int>> getPlantCountsByStatus() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final plants = await getAllPlants();
      final counts = <PlantStatus, int>{};

      for (final status in PlantStatus.values) {
        counts[status] = plants.where((p) => p.status == status).length;
      }

      return counts;
    } catch (e) {
      debugPrint('Error fetching plant counts: $e');
      rethrow;
    }
  }

  // Stream für Real-time Updates
  Stream<List<Plant>> watchPlants() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      return Stream.error('User not authenticated');
    }

    return _supabase
        .from('plants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Plant.fromJson(json)).toList());
  }
}
