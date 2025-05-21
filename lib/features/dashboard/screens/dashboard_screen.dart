import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.client.auth.signOut();
              if (context.mounted) {
                context.goNamed('welcome');
              }
            },
          ),
        ],
      ),
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
          child: Text(
            'Willkommen im Dashboard!\nHier werden bald deine Pflanzen angezeigt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Hier die Logik zum Hinzufügen einer neuen Pflanze
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Funktion zum Hinzufügen einer Pflanze kommt bald!'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
