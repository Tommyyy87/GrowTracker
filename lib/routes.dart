import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/services/supabase_service.dart';
import 'features/auth/screens/auth_callback_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/plants/screens/add_plant/add_plant_wizard.dart';
import 'features/plants/screens/plant_detail_screen.dart';

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
      // Auth Routes
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
        path: '/auth/callback',
        name: 'auth_callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),

      // Main App Routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Plant Routes
      GoRoute(
        path: '/plants/add',
        name: 'add_plant',
        builder: (context, state) => const AddPlantWizard(),
      ),
      GoRoute(
        path: '/plants/:plantId',
        name: 'plant_detail',
        builder: (context, state) {
          final plantId = state.pathParameters['plantId']!;
          return PlantDetailScreen(plantId: plantId);
        },
      ),

      // Future Routes (commented out for now)
      // GoRoute(
      //   path: '/plants',
      //   name: 'plants_overview',
      //   builder: (context, state) => const PlantsOverviewScreen(),
      // ),
      // GoRoute(
      //   path: '/plants/:plantId/edit',
      //   name: 'edit_plant',
      //   builder: (context, state) {
      //     final plantId = state.pathParameters['plantId']!;
      //     return EditPlantScreen(plantId: plantId);
      //   },
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Fehler'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Seite nicht gefunden',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Die angeforderte Seite existiert nicht: ${state.matchedLocation}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.goNamed('dashboard'),
              child: const Text('Zum Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
