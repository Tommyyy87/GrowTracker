import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/services/supabase_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/welcome_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      // Hier kannst du später die Auth-Weiterleitungslogik implementieren
      // z.B.: wenn der Benutzer bereits angemeldet ist, direkt zur Hauptseite weiterleiten
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Später weitere Routen hinzufügen
    ],
  );
}
