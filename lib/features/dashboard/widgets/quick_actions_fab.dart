import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant.dart';
import '../../plants/controllers/plant_controller.dart';
import '../../../data/services/supabase_service.dart';

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
      end: 0.75,
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
    if (_isExpanded) {
      _toggle();
      Future.delayed(const Duration(milliseconds: 260), action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(color: Colors.black.withAlpha(128)),
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Positioned(
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isExpanded)
                    _buildActionButton(
                      onTap: () =>
                          _onActionTap(() => context.pushNamed('qr_scanner')),
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'QR-Code scannen',
                      color: Colors.purple.shade500,
                      animationValue: _expandAnimation.value,
                      index: 0,
                    ),
                  if (_isExpanded)
                    _buildActionButton(
                      onTap: () => _onActionTap(() => _quickPhoto()),
                      icon: Icons.camera_alt,
                      label: 'Foto aufnehmen',
                      color: Colors.blue.shade600,
                      animationValue: _expandAnimation.value,
                      index: 1,
                    ),
                  if (_isExpanded)
                    _buildActionButton(
                      onTap: () => _onActionTap(() => _quickNote()),
                      icon: Icons.note_add,
                      label: 'Notiz hinzufügen',
                      color: Colors.orange.shade600,
                      animationValue: _expandAnimation.value,
                      index: 2,
                    ),
                  if (_isExpanded)
                    _buildActionButton(
                      onTap: () => _onActionTap(() => _quickStatusUpdate()),
                      icon: Icons.update,
                      label: 'Status ändern',
                      color: Colors.green.shade600,
                      animationValue: _expandAnimation.value,
                      index: 3,
                    ),
                  if (_isExpanded)
                    _buildActionButton(
                      onTap: () =>
                          _onActionTap(() => context.pushNamed('add_plant')),
                      icon: Icons.add_circle,
                      label: 'Neue Pflanze',
                      color: AppColors.primaryColor,
                      animationValue: _expandAnimation.value,
                      index: 4,
                    ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: _toggle,
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      heroTag: 'dashboard_fab',
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.add,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    required double animationValue,
    required int index,
  }) {
    final double scale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval((index * 0.1), 1.0, curve: Curves.easeOut)))
        .value;
    final double opacity = scale;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (animationValue > 0.7)
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.7 + (index * 0.05), 1.0,
                              curve: Curves.easeIn))),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: onTap,
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 4,
                child: Icon(icon, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickPhoto() {
    final plantsAsync = ref.read(plantsProvider);
    plantsAsync.when(
      data: (plants) async {
        if (!mounted) return;
        if (plants.isEmpty) {
          _showMessage('Erstelle zuerst eine Pflanze!', isError: true);
          return;
        }
        final selectedPlant =
            await _showPlantSelection(plants, 'Foto für welche Pflanze?');
        if (!mounted || selectedPlant == null) return;

        final controller = ref.read(plantControllerProvider.notifier);
        final photoPath = await controller.takePlantPhoto();

        if (!mounted) return;
        if (photoPath == null) {
          _showMessage('Kein Foto aufgenommen/ausgewählt.');
          return;
        }

        _showMessage('Foto für ${selectedPlant.name} wird verarbeitet...');
        final userId = SupabaseService.currentUserId;
        if (userId == null) {
          if (!mounted) return;
          _showMessage('Benutzer nicht angemeldet.', isError: true);
          return;
        }
        try {
          final uploadedPhotoUrl = await ref
              .read(plantRepositoryProvider)
              .uploadPlantPhoto(userId, selectedPlant.id, photoPath);
          final updatedPlant =
              selectedPlant.copyWith(photoUrl: () => uploadedPhotoUrl);
          await controller.updatePlant(updatedPlant);
          if (mounted) {
            _showMessage('Foto erfolgreich hinzugefügt!');
            context.pushNamed('plant_detail',
                pathParameters: {'plantId': selectedPlant.id});
          }
        } catch (e) {
          if (mounted) {
            _showMessage('Fehler beim Hochladen des Fotos: $e', isError: true);
          }
        }
      },
      loading: () {
        if (mounted) {
          _showMessage('Pflanzen werden geladen...');
        }
      },
      error: (_, __) {
        if (mounted) {
          _showMessage('Fehler beim Laden der Pflanzen', isError: true);
        }
      },
    );
  }

  void _quickNote() {
    final plantsAsync = ref.read(plantsProvider);
    plantsAsync.when(
      data: (plants) async {
        if (!mounted) return;
        if (plants.isEmpty) {
          _showMessage('Erstelle zuerst eine Pflanze!', isError: true);
          return;
        }
        final selectedPlant =
            await _showPlantSelection(plants, 'Notiz für welche Pflanze?');
        if (!mounted || selectedPlant == null) return;

        _showMessage('Öffne Details für ${selectedPlant.name} zum Notieren.');
        context.pushNamed('plant_detail',
            pathParameters: {'plantId': selectedPlant.id});
      },
      loading: () {
        if (mounted) {
          _showMessage('Pflanzen werden geladen...');
        }
      },
      error: (_, __) {
        if (mounted) {
          _showMessage('Fehler beim Laden der Pflanzen', isError: true);
        }
      },
    );
  }

  void _quickStatusUpdate() {
    final plantsAsync = ref.read(plantsProvider);
    plantsAsync.when(
      data: (plants) async {
        if (!mounted) return;
        if (plants.isEmpty) {
          _showMessage('Erstelle zuerst eine Pflanze!', isError: true);
          return;
        }
        final selectedPlant = await _showPlantSelection(
            plants, 'Status für welche Pflanze ändern?');
        if (!mounted || selectedPlant == null) return;

        _showMessage(
            'Öffne Details für ${selectedPlant.name} zur Statusänderung.');
        context.pushNamed('plant_detail',
            pathParameters: {'plantId': selectedPlant.id});
      },
      loading: () {
        if (mounted) {
          _showMessage('Pflanzen werden geladen...');
        }
      },
      error: (_, __) {
        if (mounted) {
          _showMessage('Fehler beim Laden der Pflanzen', isError: true);
        }
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.errorColor : null,
        ),
      );
    }
  }

  Future<Plant?> _showPlantSelection(List<Plant> plants, String title) async {
    final sortedPlants = List<Plant>.from(plants);
    sortedPlants.sort((a, b) {
      final aIsActive = a.status != PlantStatus.completed;
      final bIsActive = b.status != PlantStatus.completed;
      if (aIsActive && !bIsActive) return -1;
      if (!aIsActive && bIsActive) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    if (!mounted) return null;
    return await showModalBottomSheet<Plant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (plants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text("Keine Pflanzen vorhanden.",
                    style: TextStyle(color: Colors.grey.shade600)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedPlants.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final plant = sortedPlants[index];
                    final isActive = plant.status != PlantStatus.completed;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(int.parse(plant.statusColor.substring(1),
                                      radix: 16) +
                                  0xFF000000)
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.eco_rounded,
                          color: Color(int.parse(plant.statusColor.substring(1),
                                  radix: 16) +
                              0xFF000000),
                          size: 24,
                        ),
                      ),
                      title: Text(plant.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.black87
                                  : Colors.grey.shade600)),
                      subtitle: Text(
                        '${plant.strain} • ${plant.status.displayName}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(ctx).pop(plant),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (mounted) {
                      context.pushNamed('add_plant');
                    }
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
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
