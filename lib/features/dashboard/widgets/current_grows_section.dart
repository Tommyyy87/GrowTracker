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
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(51), // 0.2 * 255
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktuelle Grows',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${activePlants.length} aktive Pflanze${activePlants.length == 1 ? '' : 'n'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),

              // View Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 18,
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
            childAspectRatio: 0.85,
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
              color: Colors.black.withAlpha(13), // 0.05 * 255
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildPlantImage(),
              ),
            ),

            // Plant Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Name
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

                    // Status and Health Indicator
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                          plant.statusColor.substring(1),
                                          radix: 16) +
                                      0xFF000000)
                                  .withAlpha(51), // 0.2 * 255
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plant.status.displayName,
                              style: TextStyle(
                                color: Color(int.parse(
                                        plant.statusColor.substring(1),
                                        radix: 16) +
                                    0xFF000000),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Health Indicator
                        _buildHealthIndicator(),
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
          size: 32,
        ),
      ),
    );
  }

  Widget _buildHealthIndicator() {
    Color healthColor;
    IconData healthIcon;

    // Simple health logic based on status and age
    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      healthColor = Colors.red;
      healthIcon = Icons.error;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      healthColor = Colors.orange;
      healthIcon = Icons.schedule;
    } else {
      healthColor = Colors.green;
      healthIcon = Icons.check_circle;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: healthColor.withAlpha(51), // 0.2 * 255
        shape: BoxShape.circle,
      ),
      child: Icon(
        healthIcon,
        color: healthColor,
        size: 12,
      ),
    );
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
              color: Colors.black.withAlpha(13), // 0.05 * 255
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
                              .withAlpha(51), // 0.2 * 255
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
                _buildHealthIndicator(),
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

  Widget _buildHealthIndicator() {
    Color healthColor;
    IconData healthIcon;

    if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! < 0) {
      healthColor = Colors.red;
      healthIcon = Icons.error;
    } else if (plant.daysUntilHarvest != null && plant.daysUntilHarvest! <= 7) {
      healthColor = Colors.orange;
      healthIcon = Icons.schedule;
    } else {
      healthColor = Colors.green;
      healthIcon = Icons.check_circle;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: healthColor.withAlpha(51), // 0.2 * 255
        shape: BoxShape.circle,
      ),
      child: Icon(
        healthIcon,
        color: healthColor,
        size: 14,
      ),
    );
  }
}
