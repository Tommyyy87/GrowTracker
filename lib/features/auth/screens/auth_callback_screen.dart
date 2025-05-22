// lib/features/auth/screens/auth_callback_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widgets/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    // Warte kurz, damit Supabase die Authentifizierung verarbeiten kann
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Überprüfe Auth-Status und navigiere entsprechend
      if (SupabaseService.isAuthenticated) {
        debugPrint('Auth erfolgreich - Navigate zum Dashboard');
        context.goNamed('dashboard');
      } else {
        debugPrint('Auth fehlgeschlagen - Navigate zum Welcome');
        context.goNamed('welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator(
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Authentifizierung wird verarbeitet...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
