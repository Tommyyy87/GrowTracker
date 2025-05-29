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
          // Titel
          Text(
            'Übersicht',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
          ),
          const SizedBox(height: 12),

          // Hauptstatistiken - Viel klarer beschriftet
          Row(
            children: [
              Expanded(
                child: _buildMainStatCard(
                  context: context,
                  title: 'Gesamt',
                  value: total.toString(),
                  // FIXED: Removed unnecessary braces in string interpolation
                  subtitle: total == 1 ? 'Pflanze' : 'Pflanzen',
                  icon: Icons.eco_rounded,
                  color: AppColors.primaryColor,
                  isEmpty: total == 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMainStatCard(
                  context: context,
                  title: 'Aktiv',
                  value: active.toString(),
                  subtitle: 'laufende Grows',
                  icon: Icons.local_florist_rounded,
                  color: Colors.green.shade600,
                  isEmpty: active == 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sekundäre Stats
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStatCard(
                  context: context,
                  title: 'Abgeschlossen',
                  value: completed.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryStatCard(
                  context: context,
                  title: 'Durchschnittsalter',
                  value: averageAge > 0 ? '$averageAge Tage' : 'Keine Daten',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),

          // Aufmerksamkeits-Card nur wenn nötig
          if (harvestReady > 0 || overdue > 0) ...[
            const SizedBox(height: 12),
            _buildAttentionCard(context, harvestReady, overdue),
          ],
        ],
      ),
    );
  }

  Widget _buildMainStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isEmpty = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon und Titel
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (!isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Aktiv',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Hauptzahl
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isEmpty ? Colors.grey.shade400 : Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 4),

          // Beschreibung
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(
      BuildContext context, int harvestReady, int overdue) {
    final isUrgent = overdue > 0;
    final alertColor = isUrgent ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alertColor.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUrgent ? Icons.priority_high : Icons.schedule,
              color: alertColor.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? '⚠️ Dringend!' : '⏰ Bald erntereif',
                  style: TextStyle(
                    color: alertColor.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildAttentionMessage(harvestReady, overdue),
                  style: TextStyle(
                    color: alertColor.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: alertColor.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _buildAttentionMessage(int harvestReady, int overdue) {
    if (overdue > 0 && harvestReady > 0) {
      return '$overdue überfällig, $harvestReady erntereif';
    } else if (overdue > 0) {
      return '$overdue Pflanze${overdue == 1 ? '' : 'n'} überfällig';
    } else {
      return '$harvestReady Pflanze${harvestReady == 1 ? '' : 'n'} erntereif';
    }
  }
}
