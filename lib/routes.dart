// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/supabase_service.dart';
import 'features/auth/screens/auth_callback_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/plants/screens/add_plant/add_plant_wizard.dart';
import 'features/plants/screens/plant_detail_screen.dart';
import 'features/plants/screens/qr_scanner_screen.dart';
import 'features/profile/screens/account_management_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
        path: '/auth/callback',
        name: 'auth_callback',
        // KORREKTUR: Der Konstruktor erwartet keine Argumente.
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/add_plant',
        name: 'add_plant',
        builder: (context, state) => const AddPlantWizard(),
      ),
      GoRoute(
        path: '/plant/:plantId',
        name: 'plant_detail',
        builder: (context, state) {
          final plantId = state.pathParameters['plantId']!;
          return PlantDetailScreen(plantId: plantId);
        },
      ),
      GoRoute(
        path: '/qr_scanner',
        name: 'qr_scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'edit_profile',
              builder: (context, state) => const EditProfileScreen(),
            ),
            GoRoute(
              path: 'account',
              name: 'account_management',
              builder: (context, state) => const AccountManagementScreen(),
            ),
          ]),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = SupabaseService.isAuthenticated;

      final onAuthFlow = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/auth/callback';

      if (isLoggedIn && onAuthFlow) {
        return '/dashboard';
      }

      if (!isLoggedIn && !onAuthFlow) {
        return '/';
      }

      return null;
    },
  );
});
