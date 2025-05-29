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
        // FIXED: Backdrop mit korrekter Transparenz
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            if (!_isExpanded && _expandAnimation.value == 0) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  // FIXED: Korrekte Transparenz ohne .withAlpha Probleme
                  color: Color.fromRGBO(0, 0, 0, _expandAnimation.value * 0.5),
                ),
              ),
            );
          },
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
                  label: 'Foto aufnehmen',
                  color: Colors.blue.shade600,
                  delay: 0,
                ),

                // Add Note Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickNote(context)),
                  icon: Icons.note_add,
                  label: 'Notiz hinzufügen',
                  color: Colors.orange.shade600,
                  delay: 50,
                ),

                // Update Status Action
                _buildActionButton(
                  onTap: () => _onActionTap(() => _quickStatusUpdate(context)),
                  icon: Icons.update,
                  label: 'Status ändern',
                  color: Colors.green.shade600,
                  delay: 100,
                ),

                // New Plant Action - Wichtigste Aktion
                _buildActionButton(
                  onTap: () => _onActionTap(() => context.goNamed('add_plant')),
                  icon: Icons.add_circle,
                  label: 'Neue Pflanze',
                  color: AppColors.primaryColor,
                  delay: 150,
                ),

                const SizedBox(height: 16),

                // Main FAB - Verbessertes Design
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _toggle,
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0, // Shadow kommt vom Container
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
                  // IMPROVED: Besseres Label-Design
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // IMPROVED: Besseres Action Button Design
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
                            color: color.withValues(alpha: 0.4),
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

  // Quick Actions Implementation - Vereinfacht
  void _quickPhoto(BuildContext context) {
    final plantsAsync = ref.read(plantsProvider);

    // FIXED: Removed incorrect await - plantsAsync.when() returns void
    plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            _showMessage(context, 'Erstelle zuerst eine Pflanze!',
                isError: true);
          }
          return;
        }

        // Zeige Plant-Auswahl für Schnellfoto
        final selectedPlant = await _showPlantSelection(
            context, plants, 'Foto für welche Pflanze?');

        if (selectedPlant != null && context.mounted) {
          final controller = ref.read(plantControllerProvider.notifier);
          final photoPath = await controller.takePlantPhoto();

          if (photoPath != null && context.mounted) {
            context.goNamed(
              'plant_detail',
              pathParameters: {'plantId': selectedPlant.id},
            );
            _showMessage(context, 'Foto aufgenommen! Lade hoch...');
          }
        }
      },
      loading: () => _showMessage(context, 'Pflanzen werden geladen...'),
      error: (_, __) => _showMessage(context, 'Fehler beim Laden der Pflanzen',
          isError: true),
    );
  }

  void _quickNote(BuildContext context) {
    final plantsAsync = ref.read(plantsProvider);

    plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            _showMessage(context, 'Erstelle zuerst eine Pflanze!',
                isError: true);
          }
          return;
        }

        final selectedPlant = await _showPlantSelection(
            context, plants, 'Notiz für welche Pflanze?');

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

  void _quickStatusUpdate(BuildContext context) {
    final plantsAsync = ref.read(plantsProvider);

    plantsAsync.when(
      data: (plants) async {
        if (plants.isEmpty) {
          if (context.mounted) {
            _showMessage(context, 'Erstelle zuerst eine Pflanze!',
                isError: true);
          }
          return;
        }

        final selectedPlant = await _showPlantSelection(
            context, plants, 'Status für welche Pflanze ändern?');

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

  // Helper Methods
  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.errorColor : null,
        ),
      );
    }
  }

  Future<Plant?> _showPlantSelection(
      BuildContext context, List<Plant> plants, String title) async {
    return await showModalBottomSheet<Plant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlantSelectionSheet(
        plants: plants,
        title: title,
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          const SizedBox(height: 16),

          // Plants List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plants.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final plant = plants[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(plant.statusColor.substring(1),
                                  radix: 16) +
                              0xFF000000)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: Color(
                          int.parse(plant.statusColor.substring(1), radix: 16) +
                              0xFF000000),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    plant.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${plant.strain} • ${plant.status.displayName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.of(context).pop(plant),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Add Plant Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
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
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
