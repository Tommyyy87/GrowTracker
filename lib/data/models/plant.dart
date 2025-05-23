// lib/data/models/plant.dart
import 'package:uuid/uuid.dart';

enum PlantType {
  cannabis('Cannabis'),
  tomato('Tomaten'),
  chili('Chilis'),
  herbs('Kräuter'),
  other('Andere');

  const PlantType(this.displayName);
  final String displayName;
}

enum PlantMedium {
  soil('Erde'),
  coco('Coco'),
  hydro('Hydro'),
  rockwool('Steinwolle');

  const PlantMedium(this.displayName);
  final String displayName;
}

enum PlantLocation {
  indoor('Indoor'),
  outdoor('Outdoor'),
  greenhouse('Gewächshaus');

  const PlantLocation(this.displayName);
  final String displayName;
}

enum PlantStatus {
  seeded('Aussaat', 'Samen wurde eingepflanzt, wartet auf Keimung'),
  germinated('Keimung', 'Erste Blätter sind sichtbar, Pflanze ist aufgegangen'),
  vegetative(
      'Wachstum', 'Vegetative Phase, Pflanze entwickelt Blätter und Höhe'),
  flowering(
      'Blüte', 'Blüten (Cannabis) oder Früchte (Tomaten) entwickeln sich'),
  harvest('Ernte', 'Reif und bereit zur Ernte'),
  drying('Trocknung', 'Nach der Ernte, wird getrocknet'),
  curing('Curing/Fermentierung', 'Nachreifung für optimale Qualität'),
  completed('Abgeschlossen', 'Vollständig fertig und dokumentiert');

  const PlantStatus(this.displayName, this.description);
  final String displayName;
  final String description;
}

class Plant {
  final String id;
  final String displayId;
  final String name;
  final PlantType plantType;
  final String strain;
  final String? breeder;
  final DateTime? seedDate; // Aussaatdatum (kann unbekannt sein)
  final DateTime? germinationDate; // Keimungsdatum (kann unbekannt sein)
  final DateTime
      documentationStartDate; // Start der Dokumentation (immer gesetzt)
  final PlantMedium medium;
  final PlantLocation location;
  final PlantStatus status;
  final int? estimatedHarvestDays; // Geschätzte Tage bis Ernte
  final String? notes;
  final String? photoUrl;
  final String qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Plant({
    required this.id,
    required this.displayId,
    required this.name,
    required this.plantType,
    required this.strain,
    this.breeder,
    this.seedDate,
    this.germinationDate,
    required this.documentationStartDate,
    required this.medium,
    required this.location,
    this.status = PlantStatus.seeded,
    this.estimatedHarvestDays,
    this.notes,
    this.photoUrl,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Factory constructor für neue Pflanzen
  factory Plant.create({
    required String name,
    required PlantType plantType,
    required String strain,
    String? breeder,
    DateTime? seedDate,
    DateTime? germinationDate,
    required DateTime documentationStartDate,
    required PlantMedium medium,
    required PlantLocation location,
    PlantStatus status = PlantStatus.seeded,
    int? estimatedHarvestDays,
    String? notes,
    String? photoUrl,
    required String userId,
  }) {
    final uuid = const Uuid();
    final id = uuid.v4();
    final now = DateTime.now();
    final year = now.year;

    // Generate display ID (GT-2025-001 format)
    final displayId = 'GT-$year-${id.substring(0, 3).toUpperCase()}';

    return Plant(
      id: id,
      displayId: displayId,
      name: name,
      plantType: plantType,
      strain: strain,
      breeder: breeder,
      seedDate: seedDate,
      germinationDate: germinationDate,
      documentationStartDate: documentationStartDate,
      medium: medium,
      location: location,
      status: status,
      estimatedHarvestDays: estimatedHarvestDays,
      notes: notes,
      photoUrl: photoUrl,
      qrCode: displayId, // QR Code enthält die Display-ID
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  // Copy with method für Updates
  Plant copyWith({
    String? name,
    PlantType? plantType,
    String? strain,
    String? breeder,
    DateTime? seedDate,
    DateTime? germinationDate,
    DateTime? documentationStartDate,
    PlantMedium? medium,
    PlantLocation? location,
    PlantStatus? status,
    int? estimatedHarvestDays,
    String? notes,
    String? photoUrl,
  }) {
    return Plant(
      id: id,
      displayId: displayId,
      name: name ?? this.name,
      plantType: plantType ?? this.plantType,
      strain: strain ?? this.strain,
      breeder: breeder ?? this.breeder,
      seedDate: seedDate ?? this.seedDate,
      germinationDate: germinationDate ?? this.germinationDate,
      documentationStartDate:
          documentationStartDate ?? this.documentationStartDate,
      medium: medium ?? this.medium,
      location: location ?? this.location,
      status: status ?? this.status,
      estimatedHarvestDays: estimatedHarvestDays ?? this.estimatedHarvestDays,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId,
    );
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_id': displayId,
      'name': name,
      'plant_type': plantType.name,
      'strain': strain,
      'breeder': breeder,
      'seed_date': seedDate?.toIso8601String(),
      'germination_date': germinationDate?.toIso8601String(),
      'documentation_start_date': documentationStartDate.toIso8601String(),
      'medium': medium.name,
      'location': location.name,
      'status': status.name,
      'estimated_harvest_days': estimatedHarvestDays,
      'notes': notes,
      'photo_url': photoUrl,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  // JSON Deserialization
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      displayId: json['display_id'] as String,
      name: json['name'] as String,
      plantType: PlantType.values.firstWhere(
        (e) => e.name == json['plant_type'],
        orElse: () => PlantType.other,
      ),
      strain: json['strain'] as String,
      breeder: json['breeder'] as String?,
      seedDate: json['seed_date'] != null
          ? DateTime.parse(json['seed_date'] as String)
          : null,
      germinationDate: json['germination_date'] != null
          ? DateTime.parse(json['germination_date'] as String)
          : null,
      documentationStartDate:
          DateTime.parse(json['documentation_start_date'] as String),
      medium: PlantMedium.values.firstWhere(
        (e) => e.name == json['medium'],
        orElse: () => PlantMedium.soil,
      ),
      location: PlantLocation.values.firstWhere(
        (e) => e.name == json['location'],
        orElse: () => PlantLocation.indoor,
      ),
      status: PlantStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PlantStatus.seeded,
      ),
      estimatedHarvestDays: json['estimated_harvest_days'] as int?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      qrCode: json['qr_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String,
    );
  }

  // Getter für Alter der Pflanze (basierend auf dem ersten bekannten Datum)
  int get ageInDays {
    final referenceDate = seedDate ?? germinationDate ?? documentationStartDate;
    return DateTime.now().difference(referenceDate).inDays;
  }

  // Getter für geschätztes Erntedatum
  DateTime? get estimatedHarvestDate {
    if (estimatedHarvestDays == null) return null;

    // Basis für Berechnung: Das erste bekannte Datum
    final baseDate = seedDate ?? germinationDate ?? documentationStartDate;
    return baseDate.add(Duration(days: estimatedHarvestDays!));
  }

  // Getter für verbleibende Tage bis zur geschätzten Ernte
  int? get daysUntilHarvest {
    final harvestDate = estimatedHarvestDate;
    if (harvestDate == null) return null;

    final now = DateTime.now();
    final difference = harvestDate.difference(now).inDays;
    return difference > 0 ? difference : 0; // Negative Werte auf 0 setzen
  }

  // Getter für formatierte Ernteschätzung
  String get harvestEstimateText {
    final harvestDate = estimatedHarvestDate;
    final daysLeft = daysUntilHarvest;

    if (harvestDate == null || daysLeft == null) {
      return 'Keine Schätzung verfügbar';
    }

    if (daysLeft == 0) {
      return 'Erntereif!';
    } else if (daysLeft <= 7) {
      return 'Ernte in $daysLeft Tagen';
    } else {
      final weeks = (daysLeft / 7).round();
      return 'Ernte in ca. $weeks Wochen';
    }
  }

  // Getter für Status-Farbe
  String get statusColor {
    switch (status) {
      case PlantStatus.seeded:
        return '#8D6E63'; // Braun
      case PlantStatus.germinated:
        return '#4CAF50'; // Grün
      case PlantStatus.vegetative:
        return '#2E7D32'; // Dunkelgrün
      case PlantStatus.flowering:
        return '#FF9800'; // Orange
      case PlantStatus.harvest:
        return '#F44336'; // Rot
      case PlantStatus.drying:
        return '#795548'; // Braun
      case PlantStatus.curing:
        return '#9C27B0'; // Lila
      case PlantStatus.completed:
        return '#607D8B'; // Grau
    }
  }

  // Getter für das relevante Alter-Datum (für Anzeige)
  DateTime get primaryDate {
    return seedDate ?? germinationDate ?? documentationStartDate;
  }

  // Getter für formatierten Datums-Text
  String get primaryDateLabel {
    if (seedDate != null) return 'Aussaat';
    if (germinationDate != null) return 'Keimung';
    return 'Dokumentation';
  }
}
