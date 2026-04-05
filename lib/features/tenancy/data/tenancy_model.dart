class TenancyRecord {
  final String id;
  final String propertyId;
  final double monthlyRent;
  final double securityDeposit;
  final DateTime tenancyStartDate;
  final DateTime? tenancyEndDate;
  final String landlordName;
  final String landlordPhone;
  final String? brokerName;
  final String? brokerPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TenancyRecord({
    required this.id,
    required this.propertyId,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.tenancyStartDate,
    this.tenancyEndDate,
    required this.landlordName,
    required this.landlordPhone,
    this.brokerName,
    this.brokerPhone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      tenancyEndDate == null || tenancyEndDate!.isAfter(DateTime.now());

  TenancyRecord copyWith({
    double? monthlyRent,
    double? securityDeposit,
    DateTime? tenancyStartDate,
    DateTime? tenancyEndDate,
    String? landlordName,
    String? landlordPhone,
    String? brokerName,
    String? brokerPhone,
    String? notes,
  }) {
    return TenancyRecord(
      id: id,
      propertyId: propertyId,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      tenancyStartDate: tenancyStartDate ?? this.tenancyStartDate,
      tenancyEndDate: tenancyEndDate ?? this.tenancyEndDate,
      landlordName: landlordName ?? this.landlordName,
      landlordPhone: landlordPhone ?? this.landlordPhone,
      brokerName: brokerName ?? this.brokerName,
      brokerPhone: brokerPhone ?? this.brokerPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'monthlyRent': monthlyRent,
        'securityDeposit': securityDeposit,
        'tenancyStartDate': tenancyStartDate.toIso8601String(),
        'tenancyEndDate': tenancyEndDate?.toIso8601String(),
        'landlordName': landlordName,
        'landlordPhone': landlordPhone,
        'brokerName': brokerName,
        'brokerPhone': brokerPhone,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TenancyRecord.fromJson(Map<String, dynamic> json) => TenancyRecord(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String,
        monthlyRent: (json['monthlyRent'] as num).toDouble(),
        securityDeposit: (json['securityDeposit'] as num).toDouble(),
        tenancyStartDate: DateTime.parse(json['tenancyStartDate'] as String),
        tenancyEndDate: json['tenancyEndDate'] != null
            ? DateTime.parse(json['tenancyEndDate'] as String)
            : null,
        landlordName: json['landlordName'] as String,
        landlordPhone: json['landlordPhone'] as String,
        brokerName: json['brokerName'] as String?,
        brokerPhone: json['brokerPhone'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
