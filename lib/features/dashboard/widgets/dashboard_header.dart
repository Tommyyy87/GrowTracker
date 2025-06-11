import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/supabase_service.dart';
import '../../plants/controllers/plant_controller.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Guten Morgen';
    } else if (hour < 18) {
      return 'Hallo';
    } else {
      return 'Guten Abend';
    }
  }

  String _getUserDisplayName() {
    final email = SupabaseService.currentUserEmail;
    if (email != null) {
      final name = email.split('@')[0];
      return name.length > 15 ? '${name.substring(0, 12)}...' : name;
    }
    return 'Grower';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);

    return Container(
      // Fix: Explizite Höhe setzen um Overflow zu vermeiden
      height: 140,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Vereinfachter Header ohne komplexe Statistiken
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => context.pushNamed('profile'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Greeting und Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${_getUserDisplayName()}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    plantsAsync.when(
                      data: (plants) {
                        final activePlants = plants
                            .where((p) =>
                                p.status.index < 6) // Nicht abgeschlossen
                            .length;

                        if (plants.isEmpty) {
                          return const Text(
                            'Starte deinen ersten Grow!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        }

                        return Text(
                          '$activePlants aktive Pflanze${activePlants == 1 ? '' : 'n'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                      loading: () => const Text(
                        'Lade deine Grows...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Willkommen zurück!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Vereinfachte Quick-Info Bar
          plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) return const SizedBox.shrink();

              final needsAttention = plants.where((plant) {
                return (plant.daysUntilHarvest != null &&
                        plant.daysUntilHarvest! <= 7) ||
                    (plant.daysUntilHarvest != null &&
                        plant.daysUntilHarvest! < 0);
              }).length;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      needsAttention > 0
                          ? Icons.priority_high
                          : Icons.check_circle,
                      color: needsAttention > 0
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        needsAttention > 0
                            ? '$needsAttention Pflanze${needsAttention == 1 ? '' : 'n'} braucht${needsAttention == 1 ? '' : 'en'} Aufmerksamkeit'
                            : 'Alle Pflanzen sind in Ordnung',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (needsAttention > 0)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withAlpha(179),
                        size: 14,
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
