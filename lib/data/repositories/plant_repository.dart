// lib/data/repositories/plant_repository.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/plant.dart';
import '../models/harvest.dart';
import '../services/supabase_service.dart';

class PlantRepository {
  final _supabase = SupabaseService.client;

  Future<void> _ensureProfileExists() async {
    final userId = SupabaseService.currentUserId;
    final userEmail = SupabaseService.currentUserEmail;

    if (userId == null) {
      throw Exception('Benutzer nicht authentifiziert');
    }

    try {
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        // ignore: avoid_print
        print(
            'Profil nicht gefunden für User ID: $userId. Erstelle automatisch...');
        final username = userEmail != null
            ? userEmail.split('@')[0]
            : 'Benutzer${DateTime.now().millisecondsSinceEpoch}';
        await _supabase.from('profiles').insert({
          'id': userId,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        // ignore: avoid_print
        print('Profil erfolgreich erstellt für: $username');
      } else {
        // ignore: avoid_print
        print('Profil existiert bereits für User ID: $userId');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Fehler beim Überprüfen/Erstellen des Profils: $e');
      rethrow;
    }
  }

  Future<Plant> createPlant(Plant plant) async {
    // Akzeptiert bereits das volle Plant-Objekt
    try {
      await _ensureProfileExists();

      final response = await _supabase
          .from('plants')
          .insert(plant.toJson()) // plant.toJson() enthält bereits owner_name
          .select()
          .single();
      return Plant.fromJson(response);
    } catch (e) {
      // ignore: avoid_print
      print('Error creating plant in repository: $e');
      if (e.toString().contains('plants_user_id_fkey')) {
        // ignore: avoid_print
        print(
            'Foreign Key Constraint Fehler - Versuche Profil erneut zu erstellen...');
        await _ensureProfileExists();
        try {
          final response = await _supabase
              .from('plants')
              .insert(plant.toJson())
              .select()
              .single();
          return Plant.fromJson(response);
        } catch (retryError) {
          // ignore: avoid_print
          print('Erneuter Versuch fehlgeschlagen: $retryError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<Plant> updatePlant(Plant plant) async {
    try {
      await _ensureProfileExists();
      final response = await _supabase
          .from('plants')
          .update(
              plant.toJson()) // toJson() enthält auch owner_name für Updates
          .eq('id', plant.id)
          .eq('user_id', plant.userId)
          .select()
          .single();
      return Plant.fromJson(response);
    } catch (e) {
      // ignore: avoid_print
      print('Error updating plant in repository: $e');
      rethrow;
    }
  }

  Future<String> uploadPlantPhoto(
      String userId, String plantId, String filePath) async {
    try {
      final file = File(filePath);
      final fileExtension = filePath.split('.').last.toLowerCase();
      final uniqueFileName = '${const Uuid().v4()}.$fileExtension';
      final storagePath = '$userId/$plantId/$uniqueFileName';

      await _supabase.storage.from('plant-photos').upload(storagePath, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final publicUrl =
          _supabase.storage.from('plant-photos').getPublicUrl(storagePath);
      // ignore: avoid_print
      print('Photo uploaded to: $publicUrl');
      return publicUrl;
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading photo to Supabase: $e');
      rethrow;
    }
  }

  Future<List<Plant>> getAllPlants() async {
    try {
      await _ensureProfileExists();
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
      // ignore: avoid_print
      print('Error fetching plants: $e');
      rethrow;
    }
  }

  Future<Plant?> getPlantById(String plantId) async {
    try {
      await _ensureProfileExists();
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
      // ignore: avoid_print
      print('Error fetching plant: $e');
      return null;
    }
  }

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
      // ignore: avoid_print
      print('Error deleting plant: $e');
      rethrow;
    }
  }

  Future<List<Plant>> getPlantsByStatus(PlantStatus status) async {
    try {
      await _ensureProfileExists();
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
      // ignore: avoid_print
      print('Error fetching plants by status: $e');
      rethrow;
    }
  }

  Future<List<Plant>> getPlantsByType(PlantType type) async {
    try {
      await _ensureProfileExists();
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
      // ignore: avoid_print
      print('Error fetching plants by type: $e');
      rethrow;
    }
  }

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
      // ignore: avoid_print
      print('Error fetching harvests: $e');
      rethrow;
    }
  }

  Future<Harvest> saveHarvest(Harvest harvest) async {
    try {
      final response = await _supabase
          .from('harvests')
          .upsert(harvest.toJson())
          .select()
          .single();
      return Harvest.fromJson(response);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving harvest: $e');
      rethrow;
    }
  }

  Future<Map<PlantStatus, int>> getPlantCountsByStatus() async {
    try {
      await _ensureProfileExists();
      final userId = SupabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final plants = await getAllPlants();
      final counts = <PlantStatus, int>{};
      for (final status in PlantStatus.values) {
        counts[status] = plants.where((p) => p.status == status).length;
      }
      return counts;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching plant counts: $e');
      rethrow;
    }
  }

  Stream<List<Plant>> watchPlants() {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return Stream.error('User not authenticated');
    return _supabase
        .from('plants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Plant.fromJson(json)).toList());
  }
}
