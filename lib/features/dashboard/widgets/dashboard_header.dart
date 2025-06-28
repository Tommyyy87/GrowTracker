import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart';
import 'package:grow_tracker/features/profile/controllers/profile_controller.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Guten Morgen';
    }
    if (hour < 18) {
      return 'Guten Tag';
    }
    return 'Guten Abend';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final plantsAsync = ref.watch(plantsProvider);
    final theme = Theme.of(context);

    // PlantStatus.problem entspricht dem Index 5 im Enum
    const int problemStatusIndex = 5;
    // PlantStatus.abgeschlossen entspricht dem Index 6 im Enum
    const int abgeschlossenStatusIndex = 6;

    // Ermitteln des Pflanzenstatus-Texts
    final plantStatusText = plantsAsync.when(
      data: (plants) {
        final activePlants = plants
            .where((p) => p.status.index != abgeschlossenStatusIndex)
            .toList();
        if (activePlants.isEmpty) {
          return 'Keine aktiven Pflanzen';
        }
        final unhealthyPlants = activePlants
            .where((p) => p.status.index == problemStatusIndex)
            .length;
        return unhealthyPlants > 0
            ? '$unhealthyPlants ${unhealthyPlants == 1 ? 'Pflanze' : 'Pflanzen'} benötigt Aufmerksamkeit'
            : 'Alle Pflanzen sind in Ordnung';
      },
      loading: () => 'Lade Pflanzenstatus...',
      error: (e, s) => 'Status konnte nicht geladen werden',
    );

    // Ermitteln der Status-Farbe und des Icons
    final statusColor = plantsAsync.maybeWhen(
      data: (plants) {
        final activePlants = plants
            .where((p) => p.status.index != abgeschlossenStatusIndex)
            .toList();
        if (activePlants.isEmpty) return Colors.grey;
        final unhealthyPlants = activePlants
            .where((p) => p.status.index == problemStatusIndex)
            .isNotEmpty;
        return unhealthyPlants ? Colors.amber.shade700 : Colors.green.shade400;
      },
      orElse: () => Colors.grey,
    );

    final statusIcon = plantsAsync.maybeWhen(
      data: (plants) {
        final activePlants = plants
            .where((p) => p.status.index != abgeschlossenStatusIndex)
            .toList();
        if (activePlants.isEmpty) return Icons.info_outline;
        final unhealthyPlants = activePlants
            .where((p) => p.status.index == problemStatusIndex)
            .isNotEmpty;
        return unhealthyPlants
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline;
      },
      orElse: () => Icons.info_outline,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryColor,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pushNamed('profile'),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: profileAsync.when(
                        data: (profile) {
                          if (profile == null || profile.username.isEmpty) {
                            return Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            );
                          }
                          return Text(
                            profile.username[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, s) => Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withAlpha(204),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        profileAsync.when(
                          data: (profile) => Text(
                            profile?.username ?? 'Grower',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          loading: () => Container(
                            height: 24,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          error: (e, s) => Text(
                            'Grower',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement Notifications
                    },
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Benachrichtigungen',
                  ),
                ],
              ),
              const Spacer(),
              // Status Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plantStatusText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
