import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/supabase_service.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final appInfo = ref.watch(appInfoProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Einstellungen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Theme Settings
            SettingsSection(
              title: 'DARSTELLUNG',
              children: [
                SettingsTile(
                  title: 'Theme',
                  subtitle: 'Wähle dein bevorzugtes Design',
                  icon: Icons.palette_outlined,
                  type: SettingsTileType.multiChoice,
                  trailing: settings.themeDisplayName,
                  onTap: () => _showThemeDialog(context, ref),
                ),
              ],
            ),

            // Notification Settings
            SettingsSection(
              title: 'BENACHRICHTIGUNGEN',
              children: [
                SettingsTile(
                  title: 'Benachrichtigungen',
                  subtitle: 'Push-Benachrichtigungen aktivieren',
                  icon: Icons.notifications_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.notificationsEnabled,
                  onSwitchChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setNotificationsEnabled(value),
                ),
                SettingsTile(
                  title: 'Ernte-Erinnerungen',
                  subtitle: 'Werde an bevorstehende Ernten erinnert',
                  icon: Icons.agriculture_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.harvestReminders,
                  onSwitchChanged: settings.notificationsEnabled
                      ? (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setHarvestReminders(value)
                      : null,
                  isDisabled: !settings.notificationsEnabled,
                ),
                SettingsTile(
                  title: 'Wöchentliche Zusammenfassung',
                  subtitle: 'Erhalte eine Übersicht deiner Grows',
                  icon: Icons.summarize_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.weeklyDigest,
                  onSwitchChanged: settings.notificationsEnabled
                      ? (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setWeeklyDigest(value)
                      : null,
                  isDisabled: !settings.notificationsEnabled,
                ),
                SettingsTile(
                  title: 'Erfolgs-Benachrichtigungen',
                  subtitle: 'Werde über neue Erfolge informiert',
                  icon: Icons.emoji_events_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.achievementNotifications,
                  onSwitchChanged: settings.notificationsEnabled
                      ? (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setAchievementNotifications(value)
                      : null,
                  isDisabled: !settings.notificationsEnabled,
                ),
                if (settings.notificationsEnabled)
                  SettingsTile(
                    title: 'Erinnerungszeit',
                    subtitle: 'Wann sollen Erinnerungen gesendet werden?',
                    icon: Icons.schedule_outlined,
                    type: SettingsTileType.multiChoice,
                    trailing: settings.reminderTimeDisplayName,
                    onTap: () => _showTimePickerDialog(context, ref),
                  ),
              ],
            ),

            // Audio & Haptic Settings
            SettingsSection(
              title: 'FEEDBACK',
              children: [
                SettingsTile(
                  title: 'Töne',
                  subtitle: 'Sound-Feedback für Aktionen',
                  icon: Icons.volume_up_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.soundEnabled,
                  onSwitchChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setSoundEnabled(value),
                ),
                SettingsTile(
                  title: 'Vibration',
                  subtitle: 'Haptisches Feedback',
                  icon: Icons.vibration_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.vibrationEnabled,
                  onSwitchChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setVibrationEnabled(value),
                ),
              ],
            ),

            // Account Settings
            SettingsSection(
              title: 'KONTO',
              children: [
                SettingsTile(
                  title: 'Profil bearbeiten',
                  subtitle: 'Benutzername, Bio und Avatar ändern',
                  icon: Icons.person_outline,
                  type: SettingsTileType.navigation,
                  // KORREKTUR 1: goNamed -> pushNamed
                  onTap: () => context.pushNamed('edit_profile'),
                ),
                SettingsTile(
                  title: 'Account verwalten',
                  subtitle: 'Passwort, E-Mail und Sicherheit',
                  icon: Icons.manage_accounts_outlined,
                  type: SettingsTileType.navigation,
                  // KORREKTUR 2: goNamed -> pushNamed
                  onTap: () => context.pushNamed('account_management'),
                ),
                SettingsTile(
                  title: 'Biometrische Anmeldung',
                  subtitle: 'Fingerabdruck oder Face ID nutzen',
                  icon: Icons.fingerprint_outlined,
                  type: SettingsTileType.switchTile,
                  switchValue: settings.biometricAuth,
                  onSwitchChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setBiometricAuth(value),
                ),
              ],
            ),

            // Data & Privacy
            SettingsSection(
              title: 'DATEN & DATENSCHUTZ',
              children: [
                SettingsTile(
                  title: 'Daten exportieren',
                  subtitle: 'Alle deine Daten herunterladen',
                  icon: Icons.download_outlined,
                  type: SettingsTileType.navigation,
                  onTap: () => _showExportDialog(context),
                ),
                SettingsTile(
                  title: 'Datenschutz',
                  subtitle: 'Unsere Datenschutzerklärung',
                  icon: Icons.privacy_tip_outlined,
                  type: SettingsTileType.navigation,
                  onTap: () => _showPrivacyInfo(context),
                ),
                SettingsTile(
                  title: 'Nutzungsbedingungen',
                  subtitle: 'Terms of Service',
                  icon: Icons.description_outlined,
                  type: SettingsTileType.navigation,
                  onTap: () => _showTermsInfo(context),
                ),
              ],
            ),

            // About
            SettingsSection(
              title: 'ÜBER DIE APP',
              children: [
                SettingsTile(
                  title: 'Version',
                  subtitle: 'Build ${appInfo['buildNumber']}',
                  icon: Icons.info_outline,
                  trailing: appInfo['version'],
                ),
                SettingsTile(
                  title: 'Feedback senden',
                  subtitle: 'Hilf uns die App zu verbessern',
                  icon: Icons.feedback_outlined,
                  type: SettingsTileType.navigation,
                  onTap: () => _showFeedbackDialog(context),
                ),
                SettingsTile(
                  title: 'Bewerte die App',
                  subtitle: 'Im App Store bewerten',
                  icon: Icons.star_outline,
                  type: SettingsTileType.navigation,
                  onTap: () => _showRatingDialog(context),
                ),
              ],
            ),

            // Danger Zone
            SettingsSection(
              title: 'ACCOUNT',
              children: [
                SettingsTile(
                  title: 'Abmelden',
                  subtitle: 'Von diesem Gerät abmelden',
                  icon: Icons.logout,
                  type: SettingsTileType.navigation,
                  onTap: () => _showLogoutDialog(context),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(settingsControllerProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme auswählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((theme) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeDisplayName(theme)),
              value: theme,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }

  void _showTimePickerDialog(BuildContext context, WidgetRef ref) {
    final currentTime = ref.read(settingsControllerProvider).reminderTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erinnerungszeit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(24, (hour) {
            return RadioListTile<int>(
              title: Text('${hour.toString().padLeft(2, '0')}:00 Uhr'),
              value: hour,
              groupValue: currentTime,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setReminderTime(value);
                  Navigator.pop(context);
                }
              },
            );
          }),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.client.auth.signOut();
              if (context.mounted) {
                context.goNamed('welcome');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Abmelden', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export-Feature wird bald verfügbar sein!')),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Datenschutz-Info wird bald verfügbar sein!')),
    );
  }

  void _showTermsInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Nutzungsbedingungen werden bald verfügbar sein!')),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Feedback-Feature wird bald verfügbar sein!')),
    );
  }

  void _showRatingDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('App-Store-Bewertung wird bald verfügbar sein!')),
    );
  }
}
