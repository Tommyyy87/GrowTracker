// lib/data/services/supabase_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        authFlowType: AuthFlowType.pkce,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static User? get currentUser => client.auth.currentUser;
}
