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

  // Google-Anmeldung
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.growtracker://login-callback/',
    );
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
}
