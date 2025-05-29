// lib/features/dashboard/widgets/dashboard_stats.dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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
    final harvestReady = stats['harvestReady'] ?? 0;
    final overdue = stats['overdue'] ?? 0;
    final averageAge = (stats['averageAge'] ?? 0.0).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMainStatCard(
                  title: 'Gesamt',
                  value: total.toString(),
                  subtitle: 'Pflanzen',
                  icon: Icons.eco_rounded,
                  color: AppColors.primaryColor,
                  trend: _calculateTrend(total),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMainStatCard(
                  title: 'Aktiv',
                  value: active.toString(),
                  subtitle: 'in Arbeit',
                  icon: Icons.local_florist_rounded,
                  color: Colors.green,
                  progress: total > 0 ? active / total : 0.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Secondary Stats Row
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStatCard(
                  title: 'Abgeschlossen',
                  value: completed.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.blue,
                  progress: total > 0 ? completed / total : 0.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryStatCard(
                  title: 'Ø Alter',
                  value: averageAge > 0 ? '${averageAge}d' : '0d',
                  icon: Icons.schedule_rounded,
                  color: Colors.orange,
                  showProgress: false,
                ),
              ),
            ],
          ),

          // Alert Stats (wenn vorhanden)
          if (harvestReady > 0 || overdue > 0) ...[
            const SizedBox(height: 12),
            _buildAlertStatsCard(harvestReady, overdue),
          ],
        ],
      ),
    );
  }

  Widget _buildMainStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(51), // 0.2 * 255
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? progress,
    bool showProgress = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showProgress && progress != null) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertStatsCard(int harvestReady, int overdue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue > 0 ? Colors.red.shade200 : Colors.orange.shade200,
        ),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: overdue > 0 ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              overdue > 0 ? Icons.error_outline : Icons.schedule,
              color: overdue > 0 ? Colors.red.shade600 : Colors.orange.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overdue > 0
                      ? 'Aufmerksamkeit erforderlich!'
                      : 'Bald erntereif',
                  style: TextStyle(
                    color: overdue > 0
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (overdue > 0) ...[
                      Text(
                        '$overdue überfällig',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 11,
                        ),
                      ),
                      if (harvestReady > 0) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                    if (harvestReady > 0)
                      Text(
                        '$harvestReady erntereif',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  String? _calculateTrend(int total) {
    // Placeholder für Trend-Berechnung
    if (total > 0) {
      return '+$total';
    }
    return null;
  }
}
