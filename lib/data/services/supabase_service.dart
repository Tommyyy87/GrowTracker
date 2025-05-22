// lib/data/services/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase URL oder Anon Key fehlt in .env Datei');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authFlowType: AuthFlowType.pkce,
        debug: kDebugMode,
      );

      debugPrint('Supabase initialized successfully');
      debugPrint(
          'Auth Flow: ${kIsWeb ? 'Web' : kDebugMode ? 'Debug Mobile' : 'Release Mobile'}');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => client.auth.currentUser?.id;

  static String? get currentUserEmail => client.auth.currentUser?.email;
}
