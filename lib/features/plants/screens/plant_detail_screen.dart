import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_tracker/data/models/plant.dart';
import 'package:grow_tracker/features/plants/controllers/plant_controller.dart';
import 'package:grow_tracker/features/plants/widgets/dialogs/delete_plant_dialog.dart';
import 'package:grow_tracker/features/plants/widgets/dialogs/harvest_dialog.dart';
import 'package:grow_tracker/features/plants/widgets/dialogs/qr_code_options_dialog.dart';
import 'package:grow_tracker/features/plants/widgets/plant_detail/plant_detail_body.dart';
import 'package:grow_tracker/features/plants/widgets/plant_detail/plant_detail_sliver_app_bar.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });

  void _handleMenuAction(BuildContext context, Plant plant, String action) {
    switch (action) {
      case 'harvest':
        showDialog(
          context: context,
          builder: (_) => HarvestDialog(plantId: plant.id),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (_) => DeletePlantDialog(plant: plant),
        );
        break;
    }
  }

  void _showQrOptions(BuildContext context, WidgetRef ref, Plant plant) {
    showQrOptionsDialog(context, ref, plant);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    final harvestsAsync = ref.watch(plantHarvestsProvider(plantId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: plantAsync.when(
        data: (plant) {
          if (plant == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pflanze nicht gefunden.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.goNamed('dashboard'),
                    child: const Text('Zum Dashboard'),
                  )
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              PlantDetailSliverAppBar(
                plant: plant,
                onMenuAction: (action) =>
                    _handleMenuAction(context, plant, action),
                onShowQrOptions: () => _showQrOptions(context, ref, plant),
              ),
              SliverToBoxAdapter(
                child:
                    PlantDetailBody(plant: plant, harvestsAsync: harvestsAsync),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Fehler: ${error.toString()}'),
        ),
      ),
    );
  }
}
