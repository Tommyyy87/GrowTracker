// lib/features/plants/widgets/status_timeline.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/plant.dart';
import '../controllers/plant_controller.dart';

class StatusTimeline extends ConsumerWidget {
  final Plant plant;

  const StatusTimeline({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Status-Verlauf',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: PlantStatus.values.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final isActive = plant.status == status;
                final isPassed = plant.status.index > status.index;
                final isNext = plant.status.index == status.index - 1;

                return _buildTimelineItem(
                  context,
                  ref,
                  status,
                  isActive: isActive,
                  isPassed: isPassed,
                  isNext: isNext,
                  isLast: index == PlantStatus.values.length - 1,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    WidgetRef ref,
    PlantStatus status, {
    required bool isActive,
    required bool isPassed,
    required bool isNext,
    required bool isLast,
  }) {
    Color circleColor;
    Color lineColor = Colors.grey.shade300;
    IconData? icon;

    if (isPassed) {
      circleColor = Colors.green.shade500;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = Colors.blue.shade500;
      icon = Icons.radio_button_checked;
    } else if (isNext) {
      circleColor = Colors.orange.shade300;
      icon = Icons.radio_button_unchecked;
    } else {
      circleColor = Colors.grey.shade300;
      icon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline Indicator
          Column(
            children: [
              GestureDetector(
                onTap: () => _showStatusDialog(context, ref, status),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? Colors.white : circleColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isPassed ? Colors.green.shade500 : lineColor,
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Status Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color:
                              isActive ? Colors.black87 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (isNext)
                      TextButton(
                        onPressed: () => _updateStatus(ref, status),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Fortschritt',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                Text(
                  status.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(
      BuildContext context, WidgetRef ref, PlantStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status.description),
            const SizedBox(height: 16),
            if (plant.status.index < status.index)
              const Text(
                'Dieser Status steht noch bevor.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            else if (plant.status == status)
              const Text(
                'Dies ist der aktuelle Status.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              )
            else
              const Text(
                'Dieser Status wurde bereits durchlaufen.',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          if (plant.status.index < status.index)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateStatus(ref, status);
              },
              child: const Text('Status setzen'),
            ),
        ],
      ),
    );
  }

  void _updateStatus(WidgetRef ref, PlantStatus newStatus) {
    final controller = ref.read(plantControllerProvider.notifier);
    controller.updatePlantStatus(plant.id, newStatus).then((success) {
      if (success) {
        ref.invalidate(plantDetailProvider(plant.id));
        ref.invalidate(plantsProvider);
      }
    });
  }
}
