enum PropertyType {
  flat,
  apartment,
  house,
  room;

  String get label {
    switch (this) {
      case PropertyType.flat:
        return 'Flat';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.room:
        return 'Room';
    }
  }

  String get icon {
    switch (this) {
      case PropertyType.flat:
        return '🏢';
      case PropertyType.apartment:
        return '🏬';
      case PropertyType.house:
        return '🏠';
      case PropertyType.room:
        return '🚪';
    }
  }
}

/// Sync status for future cloud sync support.
enum SyncStatus { pending, synced, modified }

class Property {
  final String id;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final PropertyType propertyType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Sync-ready metadata (local-only for now).
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;

  Property({
    required this.id,
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.propertyType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
  });

  String get fullAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, state, pincode]);
    return parts.join(', ');
  }

  String get shortAddress => '$city, $state';

  Property copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    PropertyType? propertyType,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
  }) {
    return Property(
      id: id,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      propertyType: propertyType ?? this.propertyType,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      syncStatus: syncStatus ?? SyncStatus.modified,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'propertyType': propertyType.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.name,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as String,
        name: json['name'] as String,
        addressLine1: json['addressLine1'] as String,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
        propertyType: PropertyType.values.byName(json['propertyType'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        syncStatus: json['syncStatus'] != null
            ? SyncStatus.values.byName(json['syncStatus'] as String)
            : SyncStatus.pending,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.parse(json['lastSyncedAt'] as String)
            : null,
      );
}
