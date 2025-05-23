// lib/data/models/harvest.dart
import 'package:uuid/uuid.dart';

enum WeightUnit {
  grams('Gramm', 'g'),
  kilograms('Kilogramm', 'kg'),
  pieces('Stück', 'St.');

  const WeightUnit(this.displayName, this.abbreviation);
  final String displayName;
  final String abbreviation;
}

class Harvest {
  final String id;
  final String plantId;
  final double? freshWeight;
  final double? dryWeight;
  final WeightUnit unit;
  final DateTime harvestDate;
  final DateTime? dryingCompletedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Harvest({
    required this.id,
    required this.plantId,
    this.freshWeight,
    this.dryWeight,
    this.unit = WeightUnit.grams,
    required this.harvestDate,
    this.dryingCompletedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor für neue Ernte
  factory Harvest.create({
    required String plantId,
    double? freshWeight,
    double? dryWeight,
    WeightUnit unit = WeightUnit.grams,
    required DateTime harvestDate,
    DateTime? dryingCompletedDate,
    String? notes,
  }) {
    final uuid = const Uuid();
    final now = DateTime.now();

    return Harvest(
      id: uuid.v4(),
      plantId: plantId,
      freshWeight: freshWeight,
      dryWeight: dryWeight,
      unit: unit,
      harvestDate: harvestDate,
      dryingCompletedDate: dryingCompletedDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with method für Updates
  Harvest copyWith({
    double? freshWeight,
    double? dryWeight,
    WeightUnit? unit,
    DateTime? harvestDate,
    DateTime? dryingCompletedDate,
    String? notes,
  }) {
    return Harvest(
      id: id,
      plantId: plantId,
      freshWeight: freshWeight ?? this.freshWeight,
      dryWeight: dryWeight ?? this.dryWeight,
      unit: unit ?? this.unit,
      harvestDate: harvestDate ?? this.harvestDate,
      dryingCompletedDate: dryingCompletedDate ?? this.dryingCompletedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'fresh_weight': freshWeight,
      'dry_weight': dryWeight,
      'unit': unit.name,
      'harvest_date': harvestDate.toIso8601String(),
      'drying_completed_date': dryingCompletedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // JSON Deserialization
  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'] as String,
      plantId: json['plant_id'] as String,
      freshWeight: json['fresh_weight'] as double?,
      dryWeight: json['dry_weight'] as double?,
      unit: WeightUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => WeightUnit.grams,
      ),
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      dryingCompletedDate: json['drying_completed_date'] != null
          ? DateTime.parse(json['drying_completed_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Getter für Trocknungsverlust in Prozent
  double? get dryingLossPercentage {
    if (freshWeight == null || dryWeight == null || freshWeight == 0) {
      return null;
    }
    return ((freshWeight! - dryWeight!) / freshWeight!) * 100;
  }

  // Getter für formatierten Gewichtsverlust
  String get formattedDryingLoss {
    final loss = dryingLossPercentage;
    if (loss == null) return '--';
    return '${loss.toStringAsFixed(1)}%';
  }

  // Getter für Trocknungsdauer in Tagen
  int? get dryingDurationDays {
    if (dryingCompletedDate == null) return null;
    return dryingCompletedDate!.difference(harvestDate).inDays;
  }

  // Getter für Status der Trocknung
  String get dryingStatus {
    if (dryWeight != null && dryingCompletedDate != null) {
      return 'Abgeschlossen';
    } else if (freshWeight != null) {
      return 'In Trocknung';
    } else {
      return 'Noch nicht geerntet';
    }
  }
}
