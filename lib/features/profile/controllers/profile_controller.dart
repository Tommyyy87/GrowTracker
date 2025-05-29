// lib/features/profile/controllers/profile_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/supabase_service.dart';

// Providers
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.read(profileRepositoryProvider);
  return repository.getCurrentUserProfile();
});

final userRankingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return {};

  final repository = ref.read(profileRepositoryProvider);
  return repository.getUserRanking(userId);
});

// Profile Controller
class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileController(this._repository, this.ref)
      : super(const AsyncValue.loading()) {
    loadProfile();
  }

  final ProfileRepository _repository;
  final Ref ref;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> loadProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _repository.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      debugPrint('Error loading profile: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final currentProfile = state.value;
      if (currentProfile == null) return false;

      final updatedProfile = currentProfile.copyWith(
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      final result = await _repository.updateProfile(updatedProfile);
      if (result != null) {
        state = AsyncValue.data(result);
        ref.invalidate(currentUserProfileProvider);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  Future<String?> uploadAvatar(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;

      final currentProfile = state.value;
      final oldAvatarUrl = currentProfile?.avatarUrl;

      final newAvatarUrl =
          await _repository.updateAvatar(userId, photo.path, oldAvatarUrl);

      // Update Profile mit neuer Avatar URL
      await updateProfile(avatarUrl: newAvatarUrl);

      return newAvatarUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  Future<bool> updateStatistics() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      final updatedProfile = await _repository.updateUserStatistics(userId);
      if (updatedProfile != null) {
        state = AsyncValue.data(updatedProfile);
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(userRankingProvider);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating statistics: $e');
      return false;
    }
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final profile = state.value;
      if (profile == null) return [];

      return profile.achievements
          .map((id) => Achievement.getById(id))
          .where((achievement) => achievement != null)
          .cast<Achievement>()
          .toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  Future<List<Achievement>> getAvailableAchievements() async {
    try {
      final profile = state.value;
      if (profile == null) return Achievement.allAchievements;

      return Achievement.allAchievements
          .where(
              (achievement) => !profile.achievements.contains(achievement.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting available achievements: $e');
      return [];
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      await _repository.deleteAccount(userId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      await _repository.changePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  Future<bool> changeEmail(String newEmail) async {
    try {
      await _repository.changeEmail(newEmail);
      return true;
    } catch (e) {
      debugPrint('Error changing email: $e');
      return false;
    }
  }

  // Gamification Methods
  int getExperienceFromAction(UserAction action) {
    switch (action) {
      case UserAction.createPlant:
        return 10;
      case UserAction.updatePlant:
        return 5;
      case UserAction.completePlant:
        return 50;
      case UserAction.addPhoto:
        return 3;
      case UserAction.addNote:
        return 2;
      case UserAction.addHarvest:
        return 25;
      case UserAction.dailyLogin:
        return 1;
    }
  }

  Future<void> awardExperience(UserAction action) async {
    try {
      final profile = state.value;
      if (profile == null) return;

      final xpGained = getExperienceFromAction(action);
      final newExperience = profile.experience + xpGained;
      final newLevel = UserProfile.getLevelFromExperience(newExperience);

      final shouldUpdateStats = action == UserAction.createPlant ||
          action == UserAction.completePlant;

      if (shouldUpdateStats) {
        // Vollständige Statistik-Aktualisierung
        await updateStatistics();
      } else {
        // Nur Experience aktualisieren
        final updatedProfile = profile.copyWith(
          experience: newExperience,
          level: newLevel,
          lastActivity: DateTime.now(),
        );

        final result = await _repository.updateProfile(updatedProfile);
        if (result != null) {
          state = AsyncValue.data(result);
        }
      }
    } catch (e) {
      debugPrint('Error awarding experience: $e');
    }
  }

  // Social Proof Methods
  Future<Map<String, String>> getSocialProofTexts() async {
    try {
      final profile = state.value;
      if (profile == null) return {};

      final ranking = await ref.read(userRankingProvider.future);
      final texts = <String, String>{};

      // Rank-basierte Texte
      if (ranking['topPercent'] == true) {
        texts['ranking'] =
            'Du gehörst zu den Top ${ranking['percentile']}% der Grower! 🏆';
      } else if (ranking['percentile'] != null && ranking['percentile'] > 50) {
        texts['ranking'] =
            'Du bist besser als ${ranking['percentile']}% aller Grower! 👍';
      }

      // Streak-basierte Texte
      if (profile.currentStreak >= 30) {
        texts['streak'] =
            '🔥 Unglaubliche ${profile.currentStreak}-Tage-Serie!';
      } else if (profile.currentStreak >= 7) {
        texts['streak'] = '🔥 ${profile.currentStreak} Tage am Stück aktiv!';
      }

      // Achievement-basierte Texte
      final rareAchievements = profile.achievements
          .map((id) => Achievement.getById(id))
          .where((a) => a != null && a.isRare)
          .length;

      if (rareAchievements > 0) {
        texts['achievements'] =
            '⭐ $rareAchievements seltene Erfolge freigeschaltet!';
      }

      // Erfahrung-basierte Texte
      if (profile.level >= 20) {
        texts['level'] = '🌟 Level ${profile.level} - ${profile.rankTitle}!';
      }

      return texts;
    } catch (e) {
      debugPrint('Error getting social proof texts: $e');
      return {};
    }
  }
}

// Provider für Controller
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return ProfileController(repository, ref);
});

// Enum für User Actions (für XP-System)
enum UserAction {
  createPlant,
  updatePlant,
  completePlant,
  addPhoto,
  addNote,
  addHarvest,
  dailyLogin,
}
