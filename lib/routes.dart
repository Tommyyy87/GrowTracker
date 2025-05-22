import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/services/supabase_service.dart';
import 'features/auth/screens/auth_callback_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      // Auth-Weiterleitungslogik
      final isLoggedIn = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/auth/callback';

      // Nach erfolgreicher Authentifizierung zum Dashboard
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      // Nicht authentifizierte Benutzer zu Welcome-Screen
      if (!isLoggedIn && !isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Web OAuth Callback Route
      GoRoute(
        path: '/auth/callback',
        name: 'auth_callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
    ],
  );
}
