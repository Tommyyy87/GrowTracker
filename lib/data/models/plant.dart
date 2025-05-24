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
  final DateTime? seedDate;
  final DateTime? germinationDate;
  final DateTime documentationStartDate;
  final PlantMedium medium;
  final PlantLocation location;
  final PlantStatus status;
  final int? estimatedHarvestDays;
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
    final newId = uuid.v4();
    final now = DateTime.now();
    final year = now.year;
    final displayIdSuffix = newId.substring(0, 6).toUpperCase();
    final displayId = 'GT-$year-$displayIdSuffix';

    return Plant(
      id: newId,
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
      qrCode: displayId,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  Plant copyWith({
    String? name,
    PlantType? plantType,
    String? strain,
    String? Function()?
        breeder, // Akzeptiert eine Funktion, die String? zurückgibt
    DateTime? seedDate,
    DateTime? germinationDate,
    DateTime? documentationStartDate,
    PlantMedium? medium,
    PlantLocation? location,
    PlantStatus? status,
    int? Function()?
        estimatedHarvestDays, // Akzeptiert eine Funktion, die int? zurückgibt
    String? Function()?
        notes, // Akzeptiert eine Funktion, die String? zurückgibt
    String? Function()?
        photoUrl, // Akzeptiert eine Funktion, die String? zurückgibt
  }) {
    return Plant(
      id: id,
      displayId: displayId,
      name: name ?? this.name,
      plantType: plantType ?? this.plantType,
      strain: strain ?? this.strain,
      breeder: breeder != null ? breeder() : this.breeder,
      seedDate: seedDate ?? this.seedDate,
      germinationDate: germinationDate ?? this.germinationDate,
      documentationStartDate:
          documentationStartDate ?? this.documentationStartDate,
      medium: medium ?? this.medium,
      location: location ?? this.location,
      status: status ?? this.status,
      estimatedHarvestDays: estimatedHarvestDays != null
          ? estimatedHarvestDays()
          : this.estimatedHarvestDays,
      notes: notes != null ? notes() : this.notes,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      qrCode: qrCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
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
    };
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
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
    );
  }

  int get ageInDays {
    final referenceDate = documentationStartDate;
    final diff = DateTime.now().difference(referenceDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  DateTime? get estimatedHarvestDate {
    if (estimatedHarvestDays == null) {
      return null;
    }
    return documentationStartDate.add(Duration(days: estimatedHarvestDays!));
  }

  int? get daysUntilHarvest {
    final harvestDate = estimatedHarvestDate;
    if (harvestDate == null) {
      return null;
    }
    final now =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final harvestDayOnly =
        DateTime(harvestDate.year, harvestDate.month, harvestDate.day);
    final difference = harvestDayOnly.difference(now).inDays;
    return difference;
  }

  String get harvestEstimateText {
    final daysLeft = daysUntilHarvest;
    if (daysLeft == null) {
      return 'Keine Schätzung verfügbar';
    }
    if (daysLeft < 0) {
      return 'Überfällig um ${daysLeft.abs()} Tag(e)';
    }
    if (daysLeft == 0) {
      return 'Heute erntereif!';
    }
    if (daysLeft == 1) {
      return 'Ernte in 1 Tag';
    }
    if (daysLeft <= 7) {
      return 'Ernte in $daysLeft Tagen';
    }
    final weeks = (daysLeft / 7).ceil();
    return 'Ernte in ca. $weeks Woche(n)';
  }

  String get statusColor {
    switch (status) {
      case PlantStatus.seeded:
        return '#8D6E63';
      case PlantStatus.germinated:
        return '#AED581';
      case PlantStatus.vegetative:
        return '#66BB6A';
      case PlantStatus.flowering:
        return '#FFEE58';
      case PlantStatus.harvest:
        return '#FFA726';
      case PlantStatus.drying:
        return '#A1887F';
      case PlantStatus.curing:
        return '#7E57C2';
      case PlantStatus.completed:
        return '#BDBDBD';
    }
  }

  DateTime get primaryDate {
    // Priorität: Aussaat, dann Keimung, dann Doku-Start
    if (seedDate != null) {
      return seedDate!;
    }
    if (germinationDate != null) {
      return germinationDate!;
    }
    return documentationStartDate;
  }

  String get primaryDateLabel {
    if (seedDate != null) {
      if (germinationDate != null && germinationDate!.isBefore(seedDate!)) {
        if (documentationStartDate.isBefore(germinationDate!)) {
          return 'Doku-Start';
        }
        return 'Keimung';
      }
      if (documentationStartDate.isBefore(seedDate!)) return 'Doku-Start';
      return 'Aussaat';
    }
    if (germinationDate != null) {
      if (documentationStartDate.isBefore(germinationDate!)) {
        return 'Doku-Start';
      }
      return 'Keimung';
    }
    return 'Doku-Start';
  }
}
