// lib/data/repositories/auth_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final _supabase = SupabaseService.client;

  /// Stellt sicher, dass ein Profil für den aktuellen Benutzer existiert
  Future<void> _ensureProfileExists({String? username}) async {
    final userId = _supabase.auth.currentUser?.id;
    final userEmail = _supabase.auth.currentUser?.email;

    if (userId == null) return;

    try {
      // Prüfe ob Profil bereits existiert
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        debugPrint('Erstelle Profil für User ID: $userId');

        // Fallback für Username-Generierung
        final finalUsername = username ??
            (userEmail != null
                ? userEmail.split('@')[0]
                : 'Benutzer${DateTime.now().millisecondsSinceEpoch}');

        await _supabase.from('profiles').insert({
          'id': userId,
          'username': finalUsername,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Profil erfolgreich erstellt: $finalUsername');
      } else {
        debugPrint('Profil existiert bereits für User ID: $userId');
      }
    } catch (e) {
      debugPrint('Fehler beim Erstellen des Profils: $e');
      // Nicht rethrow, da dies die Anmeldung nicht blockieren soll
    }
  }

  // Email-basierte Anmeldung
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Stelle sicher, dass ein Profil existiert
    if (response.user != null) {
      await _ensureProfileExists();
    }

    return response;
  }

  // Email-basierte Registrierung
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Stelle sicher, dass ein Profil existiert
    if (response.user != null) {
      await _ensureProfileExists(username: email.split('@')[0]);
    }

    return response;
  }

  // Google-Anmeldung - vereinfacht für Debug-Modus
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-Anmeldung
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kDebugMode
              ? 'http://localhost:3000/auth/callback'
              : '${Uri.base.origin}/auth/callback',
        );
      } else {
        // Mobile-Anmeldung (Debug und Release)
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kDebugMode
              ? 'http://localhost:3000/auth/callback' // Debug: Gleiche URL wie Web
              : 'io.supabase.growtracker://login-callback/', // Release: Deep-Link
        );
      }

      // Warte kurz, damit die Authentifizierung abgeschlossen wird
      await Future.delayed(const Duration(seconds: 2));

      // Stelle sicher, dass ein Profil existiert
      if (_supabase.auth.currentUser != null) {
        final userEmail = _supabase.auth.currentUser!.email;
        final displayName =
            _supabase.auth.currentUser!.userMetadata?['full_name'] as String?;

        await _ensureProfileExists(
            username: displayName ??
                (userEmail != null ? userEmail.split('@')[0] : null));
      }

      return true;
    } catch (e) {
      debugPrint('Google Sign-In Fehler: $e');
      return false;
    }
  }

  // Passwort-Wiederherstellung
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Abmeldung
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Profildaten aktualisieren
  Future<void> updateProfile({String? username}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Stelle zuerst sicher, dass ein Profil existiert
    await _ensureProfileExists(username: username);

    // Dann aktualisiere es
    try {
      await _supabase.from('profiles').update({
        'username': username,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Profils: $e');
    }
  }

  // Auth-Status-Stream für automatische Navigation
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
