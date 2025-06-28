import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';
import 'package:grow_tracker/data/models/plant.dart';
// KORREKTUR: Überflüssige Imports entfernt

/// The app bar for the plant detail screen, including the flexible background.
class PlantDetailSliverAppBar extends StatelessWidget {
  final Plant plant;
  final void Function(String) onMenuAction;
  final void Function() onShowQrOptions;

  const PlantDetailSliverAppBar({
    super.key,
    required this.plant,
    required this.onMenuAction,
    required this.onShowQrOptions,
  });

  Widget _buildAppBarBackground(Plant plant) {
    // KORREKTUR & FEHLERBEHEBUNG:
    // 1. Eindeutigen Zeitstempel an die URL anhängen, um Caching-Probleme zu umgehen.
    // 2. Nur NetworkImage prüfen, da lokale Pfade hier nicht mehr relevant sind.
    final imageUrl =
        plant.photoUrl != null && plant.photoUrl!.startsWith('http')
            ? '${plant.photoUrl!}?t=${DateTime.now().millisecondsSinceEpoch}'
            : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryColor, AppColors.gradientEnd],
        ),
      ),
      child: imageUrl != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.eco_rounded,
                        size: 80, color: Colors.white54),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Icon(Icons.eco_rounded, size: 80, color: Colors.white54),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2_rounded),
          tooltip: 'QR-Code Optionen',
          onPressed: onShowQrOptions,
        ),
        PopupMenuButton<String>(
          onSelected: onMenuAction,
          itemBuilder: (popupContext) => [
            const PopupMenuItem(
              value: 'harvest',
              child: Row(children: [
                Icon(Icons.agriculture, size: 20),
                SizedBox(width: 8),
                Text('Ernte dokumentieren')
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Löschen', style: TextStyle(color: Colors.red))
              ]),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 50, bottom: 16, right: 50),
        centerTitle: true,
        title: Text(
          plant.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        background: _buildAppBarBackground(plant),
      ),
    );
  }
}
