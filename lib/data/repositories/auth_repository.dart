import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final _supabase = SupabaseService.client;

  // Email-basierte Anmeldung
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Email-basierte Registrierung
  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
    );
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

    await _supabase
        .from('profiles')
        .upsert({'id': userId, 'username': username});
  }

  // Auth-Status-Stream für automatische Navigation
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
