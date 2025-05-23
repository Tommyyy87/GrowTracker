// lib/features/dashboard/widgets/dashboard_stats.dart
import 'package:flutter/material.dart';

class DashboardStats extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DashboardStats({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 0;
    final active = stats['active'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final averageAge = (stats['averageAge'] ?? 0.0).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Gesamt',
              value: total.toString(),
              icon: Icons.eco_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Aktiv',
              value: active.toString(),
              icon: Icons.local_florist_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Fertig',
              value: completed.toString(),
              icon: Icons.check_circle_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Ø Tage',
              value: averageAge.toString(),
              icon: Icons.schedule_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26), // 0.1 * 255 = 26
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(179), // 0.7 * 255 = 179
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
