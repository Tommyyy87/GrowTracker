// lib/features/dashboard/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final statsAsync = ref.watch(plantStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // AppBar spacing

          // Greeting Section
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51), // 0.2 * 255
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withAlpha(77), // 0.3 * 255
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${_getUserDisplayName()}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    plantsAsync.when(
                      data: (plants) {
                        final activePlants = plants
                            .where(
                                (p) => p.status.index < 5 // Nicht abgeschlossen
                                )
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
                          '$activePlants aktive${activePlants == 1 ? '' : ''} Grow${activePlants == 1 ? '' : 's'}',
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

              // Quick Alert Indicator
              statsAsync.when(
                data: (stats) {
                  final harvestReady = stats['harvestReady'] ?? 0;
                  final overdue = stats['overdue'] ?? 0;
                  final alertCount = harvestReady + overdue;

                  if (alertCount > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: alertCount > 2
                            ? Colors.red.shade400
                            : Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alertCount > 2
                                ? Icons.priority_high
                                : Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Insights Bar
          plantsAsync.when(
            data: (plants) {
              if (plants.isEmpty) return const SizedBox.shrink();

              final totalAge =
                  plants.fold<int>(0, (sum, plant) => sum + plant.ageInDays);
              final avgAge = totalAge / plants.length;
              final oldestPlant =
                  plants.reduce((a, b) => a.ageInDays > b.ageInDays ? a : b);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26), // 0.1 * 255
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withAlpha(51), // 0.2 * 255
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        'Ø Alter',
                        '${avgAge.round()} Tage',
                        Icons.schedule_outlined,
                      ),
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.white.withAlpha(77), // 0.3 * 255
                    ),
                    Expanded(
                      child: _buildQuickStat(
                        'Älteste',
                        oldestPlant.name.length > 8
                            ? '${oldestPlant.name.substring(0, 8)}...'
                            : oldestPlant.name,
                        Icons.eco_outlined,
                      ),
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

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
