// lib/features/dashboard/widgets/quick_actions_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant.dart';
import '../../plants/controllers/plant_controller.dart';

class QuickActionsFab extends ConsumerStatefulWidget {
  const QuickActionsFab({super.key});

  @override
  ConsumerState<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends ConsumerState<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 3/4 Rotation
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onActionTap(VoidCallback action) {
    // Schließe erst das Menü, dann führe Aktion aus
    if (_isExpanded) {
      _toggle();
      Future.delayed(const Duration(milliseconds: 150), action);
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withAlpha(
                      (_expandAnimation.value * 128)
                          .round(), // 0.5 * 255 * animation
                    ),
                  );
                },
              ),
            ),
          ),

        // Action Buttons
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Photo Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickPhoto(context)),
                  icon: Icons.camera_alt,
                  label: 'Schnellfoto',
                  color: Colors.blue,
                  delay: 0,
                ),

                // Add Note Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickNote(context)),
                  icon: Icons.note_add,
                  label: 'Notiz hinzufügen',
                  color: Colors.orange,
                  delay: 50,
                ),

                // Update Status Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickStatusUpdate(context)),
                  icon: Icons.update,
                  label: 'Status ändern',
                  color: Colors.green,
                  delay: 100,
                ),

                // Document Care Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickCareAction(context)),
                  icon: Icons.water_drop,
                  label: 'Maßnahme',
                  color: Colors.purple,
                  delay: 150,
                ),

                const SizedBox(height: 16),

                // Main FAB
                FloatingActionButton(
                  onPressed: _toggle,
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: _isExpanded ? 8 : 6,
                  child: AnimatedBuilder(
                    animation: _rotateAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * 2 * 3.14159,
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.add,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final delayedAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay / 200.0, // Delay als Prozentsatz
            1.0,
            curve: Curves.easeOut,
          ),
        ));

        return Transform.scale(
          scale: delayedAnimation.value,
          child: Opacity(
            opacity: delayedAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26), // 0.1 * 255
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action Button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(77), // 0.3 * 255
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Quick Actions Implementation
  void _quickPhoto(BuildContext context) async {
    final plantsAsync = ref.read(plantsProvider);

    await plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erstelle zuerst eine Pflanze!'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
          return;
        }

        // Zeige Plant-Auswahl für Schnellfoto
        final selectedPlant = await showModalBottomSheet<Plant>(
          context: context,
          builder: (context) => _PlantSelectionSheet(
            plants: plants,
            title: 'Foto für welche Pflanze?',
          ),
        );

        if (selectedPlant != null && context.mounted) {
          final controller = ref.read(plantControllerProvider.notifier);
          final photoPath = await controller.takePlantPhoto();

          if (photoPath != null && context.mounted) {
            // Navigate zu Plant Detail mit Foto-Upload
            context.goNamed(
              'plant_detail',
              pathParameters: {'plantId': selectedPlant.id},
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto aufgenommen! Lade hoch...')),
            );
          }
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pflanzen werden geladen...')),
        );
      },
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Laden der Pflanzen'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      },
    );
  }

  void _quickNote(BuildContext context) async {
    final plantsAsync = ref.read(plantsProvider);

    await plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erstelle zuerst eine Pflanze!'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
          return;
        }

        final selectedPlant = await showModalBottomSheet<Plant>(
          context: context,
          builder: (context) => _PlantSelectionSheet(
            plants: plants,
            title: 'Notiz für welche Pflanze?',
          ),
        );

        if (selectedPlant != null && context.mounted) {
          context.goNamed(
            'plant_detail',
            pathParameters: {'plantId': selectedPlant.id},
          );
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  void _quickStatusUpdate(BuildContext context) async {
    final plantsAsync = ref.read(plantsProvider);

    await plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erstelle zuerst eine Pflanze!'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
          return;
        }

        final selectedPlant = await showModalBottomSheet<Plant>(
          context: context,
          builder: (context) => _PlantSelectionSheet(
            plants: plants,
            title: 'Status für welche Pflanze ändern?',
          ),
        );

        if (selectedPlant != null && context.mounted) {
          context.goNamed(
            'plant_detail',
            pathParameters: {'plantId': selectedPlant.id},
          );
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  void _quickCareAction(BuildContext context) {
    // Placeholder für zukünftige Pflegemaßnahmen-Feature
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pflegemaßnahmen-Feature kommt bald!'),
      ),
    );
  }
}

class _PlantSelectionSheet extends StatelessWidget {
  final List<Plant> plants;
  final String title;

  const _PlantSelectionSheet({
    required this.plants,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: plants.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final plant = plants[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(plant.statusColor.substring(1),
                                  radix: 16) +
                              0xFF000000)
                          .withAlpha(51), // 0.2 * 255
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: Color(
                          int.parse(plant.statusColor.substring(1), radix: 16) +
                              0xFF000000),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    plant.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${plant.strain} • ${plant.status.displayName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.of(context).pop(plant),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Add Plant Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed('add_plant');
              },
              icon: const Icon(Icons.add),
              label: const Text('Neue Pflanze hinzufügen'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
