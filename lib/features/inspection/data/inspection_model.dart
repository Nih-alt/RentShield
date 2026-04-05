enum InspectionType {
  moveIn,
  moveOut;

  String get label {
    switch (this) {
      case InspectionType.moveIn:
        return 'Move-in';
      case InspectionType.moveOut:
        return 'Move-out';
    }
  }
}

enum InspectionStatus {
  draft,
  completed;

  String get label {
    switch (this) {
      case InspectionStatus.draft:
        return 'Draft';
      case InspectionStatus.completed:
        return 'Completed';
    }
  }
}

enum ItemCondition {
  unchecked,
  ok,
  minorDamage,
  majorDamage,
  missing;

  String get label {
    switch (this) {
      case ItemCondition.unchecked:
        return 'Not checked';
      case ItemCondition.ok:
        return 'Good';
      case ItemCondition.minorDamage:
        return 'Minor Issue';
      case ItemCondition.majorDamage:
        return 'Major Issue';
      case ItemCondition.missing:
        return 'Missing';
    }
  }

  String get shortLabel {
    switch (this) {
      case ItemCondition.unchecked:
        return 'N/A';
      case ItemCondition.ok:
        return 'OK';
      case ItemCondition.minorDamage:
        return 'Minor';
      case ItemCondition.majorDamage:
        return 'Major';
      case ItemCondition.missing:
        return 'Missing';
    }
  }

  /// Severity index for comparison. Higher = worse.
  int get severity {
    switch (this) {
      case ItemCondition.unchecked:
        return 0;
      case ItemCondition.ok:
        return 1;
      case ItemCondition.minorDamage:
        return 2;
      case ItemCondition.majorDamage:
        return 3;
      case ItemCondition.missing:
        return 4;
    }
  }
}

class InspectionChecklistItem {
  final String id;
  final String templateId;
  final String name;
  final String category;
  final ItemCondition condition;
  final String? notes;
  final List<String> photos;

  InspectionChecklistItem({
    required this.id,
    required this.templateId,
    required this.name,
    required this.category,
    this.condition = ItemCondition.unchecked,
    this.notes,
    this.photos = const [],
  });

  bool get isChecked => condition != ItemCondition.unchecked;

  InspectionChecklistItem copyWith({
    ItemCondition? condition,
    String? notes,
    List<String>? photos,
  }) {
    return InspectionChecklistItem(
      id: id,
      templateId: templateId,
      name: name,
      category: category,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'category': category,
        'condition': condition.name,
        'notes': notes,
        'photos': photos,
      };

  factory InspectionChecklistItem.fromJson(Map<String, dynamic> json) {
    return InspectionChecklistItem(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      condition: ItemCondition.values.byName(json['condition'] as String),
      notes: json['notes'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
    );
  }
}

class InspectionRoom {
  final String id;
  final String templateId;
  final String name;
  final String icon;
  final String? notes;
  final List<String> photos;
  final List<InspectionChecklistItem> items;

  InspectionRoom({
    required this.id,
    required this.templateId,
    required this.name,
    required this.icon,
    this.notes,
    this.photos = const [],
    this.items = const [],
  });

  int get totalItems => items.length;
  int get checkedItems => items.where((i) => i.isChecked).length;
  bool get isComplete => totalItems > 0 && checkedItems == totalItems;
  double get progress => totalItems == 0 ? 0 : checkedItems / totalItems;

  int get okCount =>
      items.where((i) => i.condition == ItemCondition.ok).length;
  int get minorCount =>
      items.where((i) => i.condition == ItemCondition.minorDamage).length;
  int get majorCount =>
      items.where((i) => i.condition == ItemCondition.majorDamage).length;
  int get missingCount =>
      items.where((i) => i.condition == ItemCondition.missing).length;

  bool get hasIssues => minorCount > 0 || majorCount > 0 || missingCount > 0;

  InspectionRoom copyWith({
    String? notes,
    List<String>? photos,
    List<InspectionChecklistItem>? items,
  }) {
    return InspectionRoom(
      id: id,
      templateId: templateId,
      name: name,
      icon: icon,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'icon': icon,
        'notes': notes,
        'photos': photos,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory InspectionRoom.fromJson(Map<String, dynamic> json) {
    return InspectionRoom(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      notes: json['notes'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      items: (json['items'] as List?)
              ?.map((i) => InspectionChecklistItem.fromJson(
                  Map<String, dynamic>.from(i as Map)))
              .toList() ??
          [],
    );
  }
}

class Inspection {
  final String id;
  final String propertyId;
  final InspectionType type;
  final InspectionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<InspectionRoom> rooms;

  /// For move-out inspections, links to the base move-in inspection.
  final String? linkedMoveInInspectionId;

  /// Sync-ready metadata (local-only for now).
  final String syncStatus;

  Inspection({
    required this.id,
    required this.propertyId,
    required this.type,
    this.status = InspectionStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    required this.startedAt,
    this.completedAt,
    this.rooms = const [],
    this.linkedMoveInInspectionId,
    this.syncStatus = 'pending',
  });

  int get totalRooms => rooms.length;
  int get completedRooms => rooms.where((r) => r.isComplete).length;
  bool get allRoomsComplete =>
      totalRooms > 0 && completedRooms == totalRooms;

  int get totalItems => rooms.fold(0, (sum, r) => sum + r.totalItems);
  int get checkedItems => rooms.fold(0, (sum, r) => sum + r.checkedItems);
  double get overallProgress =>
      totalItems == 0 ? 0 : checkedItems / totalItems;

  int get totalIssues => rooms.fold(
      0, (sum, r) => sum + r.minorCount + r.majorCount + r.missingCount);
  int get totalPhotos => rooms.fold(
      0,
      (sum, r) =>
          sum +
          r.photos.length +
          r.items.fold(0, (s, i) => s + i.photos.length));

  Inspection copyWith({
    InspectionStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<InspectionRoom>? rooms,
    String? linkedMoveInInspectionId,
    String? syncStatus,
  }) {
    return Inspection(
      id: id,
      propertyId: propertyId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      rooms: rooms ?? this.rooms,
      linkedMoveInInspectionId:
          linkedMoveInInspectionId ?? this.linkedMoveInInspectionId,
      syncStatus: syncStatus ?? 'modified',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'linkedMoveInInspectionId': linkedMoveInInspectionId,
        'syncStatus': syncStatus,
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      type: InspectionType.values.byName(json['type'] as String),
      status: InspectionStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      linkedMoveInInspectionId:
          json['linkedMoveInInspectionId'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      rooms: (json['rooms'] as List?)
              ?.map((r) =>
                  InspectionRoom.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList() ??
          [],
    );
  }
}
