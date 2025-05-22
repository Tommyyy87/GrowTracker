import 'package:flutter/material.dart';
import 'package:grow_tracker/data/repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _authRepository = AuthRepository();

  // Login
  Future<bool> login(String emailOrUsername, String password) async {
    try {
      // Bestimme, ob es eine E-Mail ist
      final isEmail = emailOrUsername.contains('@');

      String email =
          isEmail ? emailOrUsername : '$emailOrUsername@growtracker.app';

      await _authRepository.signInWithEmail(email, password);
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

      // Aktualisiere das Benutzerprofil mit dem Benutzernamen
      if (response.user != null) {
        await _authRepository.updateProfile(username: username);
      }

      return response.user != null;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Google-Anmeldung - mit verbesserter Fehlerbehandlung
  Future<bool> signInWithGoogle() async {
    try {
      final success = await _authRepository.signInWithGoogle();
      if (success) {
        debugPrint('Google-Anmeldung erfolgreich');
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
}
