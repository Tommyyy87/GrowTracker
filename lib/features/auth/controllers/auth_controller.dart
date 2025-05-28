// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:grow_tracker/data/repositories/auth_repository.dart';
import 'package:grow_tracker/data/services/supabase_service.dart';

class AuthController {
  final AuthRepository _authRepository = AuthRepository();

  /// Validiert und repariert das Benutzerprofil nach der Anmeldung
  Future<bool> _validateAndRepairProfile() async {
    try {
      final userId = SupabaseService.currentUserId;
      final userEmail = SupabaseService.currentUserEmail;

      if (userId == null) return false;

      // Prüfe ob Profil existiert
      final profile = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        debugPrint('Profil fehlt für User $userId - erstelle automatisch...');

        // Erstelle fehlendes Profil
        final username = userEmail != null
            ? userEmail.split('@')[0]
            : 'Benutzer${DateTime.now().millisecondsSinceEpoch}';

        await SupabaseService.client.from('profiles').insert({
          'id': userId,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Profil erfolgreich erstellt für: $username');
      }

      return true;
    } catch (e) {
      debugPrint('Fehler bei Profil-Validierung: $e');
      return false;
    }
  }

  // Login
  Future<bool> login(String emailOrUsername, String password) async {
    try {
      // Bestimme, ob es eine E-Mail ist
      final isEmail = emailOrUsername.contains('@');

      String email =
          isEmail ? emailOrUsername : '$emailOrUsername@growtracker.app';

      await _authRepository.signInWithEmail(email, password);

      // Validiere und repariere Profil nach erfolgreicher Anmeldung
      await _validateAndRepairProfile();

      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Registrierung
  Future<bool> register(String username, String email, String password) async {
    try {
      // Verwende die bereitgestellte E-Mail oder generiere eine basierend auf dem Benutzernamen
      final emailToUse = email.isNotEmpty ? email : '$username@growtracker.app';

      // Registriere den Benutzer
      final response =
          await _authRepository.signUpWithEmail(emailToUse, password);

      // Aktualisiere das Benutzerprofil mit dem Benutzernamen und validiere
      if (response.user != null) {
        await _authRepository.updateProfile(username: username);
        await _validateAndRepairProfile();
      }

      return response.user != null;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Google-Anmeldung - mit verbesserter Fehlerbehandlung und Profil-Validierung
  Future<bool> signInWithGoogle() async {
    try {
      final success = await _authRepository.signInWithGoogle();

      if (success) {
        debugPrint('Google-Anmeldung erfolgreich');

        // Warte kurz auf die Authentifizierung
        await Future.delayed(const Duration(seconds: 1));

        // Validiere und repariere Profil
        final profileValid = await _validateAndRepairProfile();

        if (!profileValid) {
          debugPrint('Warnung: Profil-Validierung fehlgeschlagen');
          // Dennoch erfolgreich, da die Anmeldung funktioniert hat
        }

        return true;
      } else {
        debugPrint('Google-Anmeldung fehlgeschlagen');
        return false;
      }
    } catch (e) {
      debugPrint('Google Sign-In Controller Fehler: $e');
      return false;
    }
  }

  // Abmeldung
  Future<void> logout() async {
    await _authRepository.signOut();
  }

  // Passwort zurücksetzen
  Future<bool> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  // Profil-Status prüfen (für Debugging)
  Future<Map<String, dynamic>> getProfileStatus() async {
    try {
      final userId = SupabaseService.currentUserId;
      final userEmail = SupabaseService.currentUserEmail;

      if (userId == null) {
        return {
          'authenticated': false,
          'profileExists': false,
          'error': 'Nicht authentifiziert'
        };
      }

      final profile = await SupabaseService.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      return {
        'authenticated': true,
        'userId': userId,
        'userEmail': userEmail,
        'profileExists': profile != null,
        'profileData': profile,
      };
    } catch (e) {
      return {
        'authenticated': false,
        'profileExists': false,
        'error': e.toString()
      };
    }
  }
}
