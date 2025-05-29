// lib/features/dashboard/widgets/current_grows_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/plant.dart';

class CurrentGrowsSection extends StatelessWidget {
  final List<Plant> plants;
  final bool isGridView;
  final VoidCallback onViewToggle;

  const CurrentGrowsSection({
    super.key,
    required this.plants,
    required this.isGridView,
    required this.onViewToggle,
  });

  List<Plant> get _activePlants {
    return plants
        .where((plant) => plant.status != PlantStatus.completed)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final activePlants = _activePlants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMPROVED: Cleaner Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Icon und Text
              Icon(
                Icons.eco_rounded,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktuelle Grows',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    Text(
                      '${activePlants.length} aktive${activePlants.length == 1 ? '' : ''} Pflanze${activePlants.length == 1 ? '' : 'n'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),

              // IMPROVED: Better View Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      icon: Icons.grid_view_rounded,
                      isSelected: isGridView,
                      onTap: isGridView ? null : onViewToggle,
                    ),
                    _buildToggleButton(
                      icon: Icons.view_list_rounded,
                      isSelected: !isGridView,
                      onTap: !isGridView ? null : onViewToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Plants Content
        if (activePlants.isEmpty)
          _buildEmptyState(context)
        else
          _buildPlantsView(activePlants),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine aktiven Grows',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Starte deinen ersten Grow und dokumentiere das Wachstum deiner Pflanzen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('add_plant'),
              icon: const Icon(Icons.add),
              label: const Text('Ersten Grow starten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantsView(List<Plant> plants) {
    if (isGridView) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9, // Slightly taller for better proportions
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) {
            return _PlantGridCard(plant: plants[index]);
          },
        ),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _PlantListCard(plant: plants[index]);
        },
      );
    }
  }
}

class _PlantGridCard extends StatelessWidget {
  final Plant plant;

  const _PlantGridCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context
          .goNamed('plant_detail', pathParameters: {'plantId': plant.id}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMPROVED: Plant Image with better aspect ratio
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildPlantImage(),
                  ),
                  // Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plant.status.displayName,
                        style: TextStyle(
                          color: Color(int.parse(plant.statusColor.substring(1),
                                  radix: 16) +
                              0xFF000000),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // IMPROVED: Plant Info with better spacing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Name
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Plant Details
                    Text(
                      '${plant.strain} • ${plant.ageInDays}d',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Health Status Row
                    Row(
                      children: [
                        _buildHealthIndicator(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getHealthText(),
                            style: TextStyle(
                              color: _getHealthColor(),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    if (plant.photoUrl != null && plant.photoUrl!.startsWith('http')) {
      return Image.network(
        plant.photoUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    } else if (plant.photoUrl != null && File(plant.photoUrl!).existsSync()) {
      return Image.file(
        File(plant.photoUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: Colors.grey.shade400,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildHealthIndicator() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _getHealthColor().withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getHealthIcon(),
        color: _getHealthColor(),
        size: 12,
      ),
    );
  }

  Color _getHealthColor() {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return Colors.red.shade600;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  IconData _getHealthIcon() {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return Icons.error;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return Icons.schedule;
    } else {
      return Icons.check_circle;
    }
  }

  String _getHealthText() {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return 'Überfällig';
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return 'Bald erntereif';
    } else {
      return 'Gesund';
    }
  }
}

class _PlantListCard extends StatelessWidget {
  final Plant plant;

  const _PlantListCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context
          .goNamed('plant_detail', pathParameters: {'plantId': plant.id}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Plant Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPlantImage(),
              ),
            ),

            const SizedBox(width: 12),

            // Plant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plant.strain} • ${plant.ageInDays} Tage alt',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(int.parse(plant.statusColor.substring(1),
                                      radix: 16) +
                                  0xFF000000)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plant.status.displayName,
                          style: TextStyle(
                            color: Color(int.parse(
                                    plant.statusColor.substring(1),
                                    radix: 16) +
                                0xFF000000),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (plant.daysUntilHarvest != null) ...[
                        Icon(
                          Icons.schedule,
                          color: Colors.grey.shade500,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plant.harvestEstimateText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Health Indicator & Arrow
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getHealthColor().withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getHealthIcon(),
                    color: _getHealthColor(),
                    size: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    if (plant.photoUrl != null && plant.photoUrl!.startsWith('http')) {
      return Image.network(
        plant.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    } else if (plant.photoUrl != null && File(plant.photoUrl!).existsSync()) {
      return Image.file(
        File(plant.photoUrl!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }

  Color _getHealthColor() {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return Colors.red.shade600;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  IconData _getHealthIcon() {
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      return Icons.error;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      return Icons.schedule;
    } else {
      return Icons.check_circle;
    }
  }
}
