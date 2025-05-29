// lib/data/repositories/profile_repository.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import '../models/plant.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final _supabase = SupabaseService.client;

  /// Lädt das vollständige Benutzerprofil
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  /// Aktualisiert das Benutzerprofil
  Future<UserProfile?> updateProfile(UserProfile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Lädt Avatar-Bild hoch
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileExtension = filePath.split('.').last.toLowerCase();
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final storagePath = 'avatars/$userId/$fileName';

      await _supabase.storage.from('avatars').upload(storagePath, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(storagePath);
      debugPrint('Avatar uploaded to: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }

  /// Löscht altes Avatar und lädt neues hoch
  Future<String> updateAvatar(
      String userId, String filePath, String? oldAvatarUrl) async {
    try {
      // Lösche altes Avatar falls vorhanden
      if (oldAvatarUrl != null && oldAvatarUrl.contains('avatars/')) {
        final oldPath = oldAvatarUrl.split('avatars/')[1];
        try {
          await _supabase.storage.from('avatars').remove([oldPath]);
        } catch (e) {
          debugPrint('Could not delete old avatar: $e');
        }
      }

      // Lade neues Avatar hoch
      return await uploadAvatar(userId, filePath);
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    }
  }

  /// Berechnet und aktualisiert User-Statistiken
  Future<UserProfile?> updateUserStatistics(String userId) async {
    try {
      // Lade alle Pflanzen des Users
      final plantsResponse =
          await _supabase.from('plants').select().eq('user_id', userId);

      final plants = (plantsResponse as List)
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();

      // Berechne Statistiken
      final totalPlants = plants.length;
      final completedGrows =
          plants.where((p) => p.status == PlantStatus.completed).length;

      // Plant Type Statistiken
      final plantTypeCount = <String, int>{};
      for (final plant in plants) {
        final type = plant.plantType.displayName;
        plantTypeCount[type] = (plantTypeCount[type] ?? 0) + 1;
      }

      // Location Statistiken
      final locationCount = <String, int>{};
      for (final plant in plants) {
        final location = plant.location.displayName;
        locationCount[location] = (locationCount[location] ?? 0) + 1;
      }

      // Medium Statistiken
      final mediumCount = <String, int>{};
      for (final plant in plants) {
        final medium = plant.medium.displayName;
        mediumCount[medium] = (mediumCount[medium] ?? 0) + 1;
      }

      // Durchschnittliche Grow-Dauer (nur für abgeschlossene)
      final completedPlants =
          plants.where((p) => p.status == PlantStatus.completed);
      double averageGrowDays = 0;
      if (completedPlants.isNotEmpty) {
        final totalDays = completedPlants
            .map((p) =>
                DateTime.now().difference(p.documentationStartDate).inDays)
            .reduce((a, b) => a + b);
        averageGrowDays = totalDays / completedPlants.length;
      }

      // Experience-Berechnung
      int experience = 0;
      experience += totalPlants * 10; // 10 XP pro Pflanze
      experience += completedGrows * 50; // 50 XP pro abgeschlossenem Grow

      // Bonus XP für Vielfalt
      experience += plantTypeCount.length * 25; // 25 XP pro Pflanzenart

      final level = UserProfile.getLevelFromExperience(experience);

      // Aktualisiere Streak (vereinfacht - basierend auf letzter Aktivität)
      final currentProfile = await getCurrentUserProfile();
      final currentStreak = await _calculateStreak(userId);
      final longestStreak = currentProfile != null
          ? (currentStreak > currentProfile.longestStreak
              ? currentStreak
              : currentProfile.longestStreak)
          : currentStreak;

      // Prüfe und verleihe Achievements
      final achievements = await _checkAndAwardAchievements(
          userId,
          totalPlants,
          completedGrows,
          currentStreak,
          plantTypeCount.length,
          currentProfile?.achievements ?? []);

      final statistics = {
        'plantTypeCount': plantTypeCount,
        'locationCount': locationCount,
        'mediumCount': mediumCount,
        'averageGrowDays': averageGrowDays,
        'successRate':
            totalPlants > 0 ? (completedGrows / totalPlants * 100) : 0.0,
        'diversityScore': plantTypeCount.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Aktualisiere Profile
      final updatedProfile = await _supabase
          .from('profiles')
          .update({
            'total_plants': totalPlants,
            'completed_grows': completedGrows,
            'level': level,
            'experience': experience,
            'current_streak': currentStreak,
            'longest_streak': longestStreak,
            'last_activity': DateTime.now().toIso8601String(),
            'achievements': achievements,
            'statistics': statistics,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(updatedProfile);
    } catch (e) {
      debugPrint('Error updating user statistics: $e');
      rethrow;
    }
  }

  /// Berechnet den aktuellen Streak (vereinfacht)
  Future<int> _calculateStreak(String userId) async {
    try {
      // Vereinfachte Streak-Berechnung basierend auf Pflanzen-Updates
      final plants = await _supabase
          .from('plants')
          .select('updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      if (plants.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final plant in plants) {
        final updateDate = DateTime.parse(plant['updated_at'] as String);
        final daysDiff = lastDate != null
            ? lastDate.difference(updateDate).inDays
            : DateTime.now().difference(updateDate).inDays;

        if (daysDiff <= 1) {
          streak++;
          lastDate = updateDate;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  /// Prüft und verleiht neue Achievements
  Future<List<String>> _checkAndAwardAchievements(
    String userId,
    int totalPlants,
    int completedGrows,
    int currentStreak,
    int plantTypes,
    List<String> currentAchievements,
  ) async {
    final newAchievements = List<String>.from(currentAchievements);

    // Plant Count Achievements
    if (totalPlants >= 1 && !newAchievements.contains('first_plant')) {
      newAchievements.add('first_plant');
    }
    if (totalPlants >= 10 && !newAchievements.contains('plant_collector')) {
      newAchievements.add('plant_collector');
    }
    if (totalPlants >= 50 && !newAchievements.contains('greenhouse_master')) {
      newAchievements.add('greenhouse_master');
    }

    // Completion Achievements
    if (completedGrows >= 1 && !newAchievements.contains('first_harvest')) {
      newAchievements.add('first_harvest');
    }
    if (completedGrows >= 5 && !newAchievements.contains('serial_grower')) {
      newAchievements.add('serial_grower');
    }
    if (completedGrows >= 25 && !newAchievements.contains('harvest_master')) {
      newAchievements.add('harvest_master');
    }

    // Streak Achievements
    if (currentStreak >= 7 &&
        !newAchievements.contains('consistent_gardener')) {
      newAchievements.add('consistent_gardener');
    }
    if (currentStreak >= 30 && !newAchievements.contains('dedicated_grower')) {
      newAchievements.add('dedicated_grower');
    }

    // Diversity Achievement
    if (plantTypes >= 5 && !newAchievements.contains('diversity_lover')) {
      newAchievements.add('diversity_lover');
    }

    // Early Adopter (für neue User in den ersten Monaten der App)
    final profile = await getCurrentUserProfile();
    if (profile != null &&
        profile.memberForDays <= 90 &&
        !newAchievements.contains('early_adopter')) {
      newAchievements.add('early_adopter');
    }

    return newAchievements;
  }

  /// Lädt globale User-Rankings (für Social Proof) - FIXED
  Future<Map<String, dynamic>> getUserRanking(String userId) async {
    try {
      // Gesamtanzahl User - MODERNE SUPABASE API
      final totalUsersQuery = await _supabase
          .from('profiles')
          .select('id')
          .count(CountOption.exact);

      final totalUsers = totalUsersQuery.count;

      // User's Rank basierend auf Experience
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) return {};

      final higherExpUsersQuery = await _supabase
          .from('profiles')
          .select('id')
          .gt('experience', userProfile.experience)
          .count(CountOption.exact);

      final rank = higherExpUsersQuery.count + 1;
      final percentile =
          totalUsers > 0 ? ((totalUsers - rank) / totalUsers * 100).round() : 0;

      return {
        'rank': rank,
        'totalUsers': totalUsers,
        'percentile': percentile,
        'topPercent': percentile >= 90,
      };
    } catch (e) {
      debugPrint('Error getting user ranking: $e');
      return {};
    }
  }

  /// Account löschen
  Future<void> deleteAccount(String userId) async {
    try {
      // Lösche Avatar
      try {
        final profile = await getCurrentUserProfile();
        if (profile?.avatarUrl != null &&
            profile!.avatarUrl!.contains('avatars/')) {
          final avatarPath = profile.avatarUrl!.split('avatars/')[1];
          await _supabase.storage.from('avatars').remove([avatarPath]);
        }
      } catch (e) {
        debugPrint('Could not delete avatar during account deletion: $e');
      }

      // Lösche alle Plant Photos
      try {
        await _supabase.storage.from('plant-photos').remove(['$userId/']);
      } catch (e) {
        debugPrint('Could not delete plant photos during account deletion: $e');
      }

      // Lösche Profile (Cascade löscht automatisch Plants, Harvests etc.)
      await _supabase.from('profiles').delete().eq('id', userId);

      // Lösche Auth User
      await _supabase.auth.admin.deleteUser(userId);
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  /// Passwort ändern
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  /// E-Mail ändern
  Future<void> changeEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    } catch (e) {
      debugPrint('Error changing email: $e');
      rethrow;
    }
  }
}
