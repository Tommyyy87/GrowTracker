import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authFlowType: AuthFlowType.pkce,
      // Keine authOptions hier, da dieser Parameter in der aktuellen API nicht existiert
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static User? get currentUser => client.auth.currentUser;
}
