// lib/features/settings/controllers/settings_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App Settings Model
class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool harvestReminders;
  final bool weeklyDigest;
  final bool achievementNotifications;
  final String language;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool biometricAuth;
  final int reminderTime; // Hour of day (0-23)

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.harvestReminders = true,
    this.weeklyDigest = true,
    this.achievementNotifications = true,
    this.language = 'de',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.biometricAuth = false,
    this.reminderTime = 18, // 6 PM default
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? harvestReminders,
    bool? weeklyDigest,
    bool? achievementNotifications,
    String? language,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? biometricAuth,
    int? reminderTime,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      harvestReminders: harvestReminders ?? this.harvestReminders,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      language: language ?? this.language,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'notificationsEnabled': notificationsEnabled,
      'harvestReminders': harvestReminders,
      'weeklyDigest': weeklyDigest,
      'achievementNotifications': achievementNotifications,
      'language': language,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'biometricAuth': biometricAuth,
      'reminderTime': reminderTime,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] ?? ThemeMode.system.index],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      harvestReminders: json['harvestReminders'] ?? true,
      weeklyDigest: json['weeklyDigest'] ?? true,
      achievementNotifications: json['achievementNotifications'] ?? true,
      language: json['language'] ?? 'de',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      biometricAuth: json['biometricAuth'] ?? false,
      reminderTime: json['reminderTime'] ?? 18,
    );
  }

  String get themeDisplayName {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }

  String get languageDisplayName {
    switch (language) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      default:
        return 'Deutsch';
    }
  }

  String get reminderTimeDisplayName {
    final hour = reminderTime;
    return '${hour.toString().padLeft(2, '0')}:00 Uhr';
  }
}

// Settings Controller
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json = {};
        // Vereinfachte JSON-Parsing (würde normalerweise dart:convert verwenden)
        // Hier implementieren wir eine manuelle Lösung für die wichtigsten Werte

        state = AppSettings(
          themeMode: ThemeMode
              .values[prefs.getInt('themeMode') ?? ThemeMode.system.index],
          notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
          harvestReminders: prefs.getBool('harvestReminders') ?? true,
          weeklyDigest: prefs.getBool('weeklyDigest') ?? true,
          achievementNotifications:
              prefs.getBool('achievementNotifications') ?? true,
          language: prefs.getString('language') ?? 'de',
          soundEnabled: prefs.getBool('soundEnabled') ?? true,
          vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
          biometricAuth: prefs.getBool('biometricAuth') ?? false,
          reminderTime: prefs.getInt('reminderTime') ?? 18,
        );
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Speichere jeden Wert einzeln für bessere Kompatibilität
      await prefs.setInt('themeMode', state.themeMode.index);
      await prefs.setBool('notificationsEnabled', state.notificationsEnabled);
      await prefs.setBool('harvestReminders', state.harvestReminders);
      await prefs.setBool('weeklyDigest', state.weeklyDigest);
      await prefs.setBool(
          'achievementNotifications', state.achievementNotifications);
      await prefs.setString('language', state.language);
      await prefs.setBool('soundEnabled', state.soundEnabled);
      await prefs.setBool('vibrationEnabled', state.vibrationEnabled);
      await prefs.setBool('biometricAuth', state.biometricAuth);
      await prefs.setInt('reminderTime', state.reminderTime);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Theme Settings
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  // Notification Settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    if (!enabled) {
      // Disable all notification types if main toggle is off
      state = state.copyWith(
        harvestReminders: false,
        weeklyDigest: false,
        achievementNotifications: false,
      );
    }
    await _saveSettings();
  }

  Future<void> setHarvestReminders(bool enabled) async {
    state = state.copyWith(harvestReminders: enabled);
    await _saveSettings();
  }

  Future<void> setWeeklyDigest(bool enabled) async {
    state = state.copyWith(weeklyDigest: enabled);
    await _saveSettings();
  }

  Future<void> setAchievementNotifications(bool enabled) async {
    state = state.copyWith(achievementNotifications: enabled);
    await _saveSettings();
  }

  Future<void> setReminderTime(int hour) async {
    state = state.copyWith(reminderTime: hour);
    await _saveSettings();
  }

  // Audio & Haptic Settings
  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _saveSettings();
  }

  // Security Settings
  Future<void> setBiometricAuth(bool enabled) async {
    state = state.copyWith(biometricAuth: enabled);
    await _saveSettings();
  }

  // Language Settings
  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  // Utility Methods
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  // Get app info
  Map<String, String> getAppInfo() {
    return {
      'appName': 'GrowTracker',
      'version': '1.0.0',
      'buildNumber': '1',
      'developer': 'GrowTracker Team',
      'email': 'support@growtracker.app',
      'website': 'https://growtracker.app',
      'privacyPolicy': 'https://growtracker.app/privacy',
      'termsOfService': 'https://growtracker.app/terms',
    };
  }

  // Permission checks (simplified - would use permission_handler package)
  Future<bool> hasNotificationPermission() async {
    // Würde normalerweise Permission.notification.isGranted verwenden
    return state.notificationsEnabled;
  }

  Future<bool> requestNotificationPermission() async {
    // Würde normalerweise Permission.notification.request() verwenden
    return true;
  }

  Future<bool> hasCameraPermission() async {
    // Würde normalerweise Permission.camera.isGranted verwenden
    return true;
  }

  Future<bool> hasStoragePermission() async {
    // Würde normalerweise Permission.storage.isGranted verwenden
    return true;
  }
}

// Providers
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

// Theme provider for the app
final themeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsControllerProvider).themeMode;
});

// Notification settings provider
final notificationSettingsProvider = Provider<Map<String, bool>>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return {
    'enabled': settings.notificationsEnabled,
    'harvest': settings.harvestReminders,
    'digest': settings.weeklyDigest,
    'achievements': settings.achievementNotifications,
    'sound': settings.soundEnabled,
    'vibration': settings.vibrationEnabled,
  };
});

// App info provider
final appInfoProvider = Provider<Map<String, String>>((ref) {
  final controller = ref.read(settingsControllerProvider.notifier);
  return controller.getAppInfo();
});
