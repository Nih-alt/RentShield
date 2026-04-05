enum ReportType {
  moveIn,
  moveOut,
  comparison;

  String get label {
    switch (this) {
      case ReportType.moveIn:
        return 'Move-in Report';
      case ReportType.moveOut:
        return 'Move-out Report';
      case ReportType.comparison:
        return 'Comparison Report';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReportType.moveIn:
        return 'Move-in';
      case ReportType.moveOut:
        return 'Move-out';
      case ReportType.comparison:
        return 'Comparison';
    }
  }
}

class ReportRecord {
  final String id;
  final String propertyId;
  final ReportType reportType;
  final String filePath;
  final String fileName;
  final DateTime createdAt;

  /// The primary inspection used for report generation.
  final String inspectionId;

  /// For comparison reports, the linked move-in inspection id.
  final String? linkedInspectionId;

  /// File size in bytes (for display purposes).
  final int fileSizeBytes;

  const ReportRecord({
    required this.id,
    required this.propertyId,
    required this.reportType,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.inspectionId,
    this.linkedInspectionId,
    this.fileSizeBytes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'reportType': reportType.name,
        'filePath': filePath,
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
        'inspectionId': inspectionId,
        'linkedInspectionId': linkedInspectionId,
        'fileSizeBytes': fileSizeBytes,
      };

  factory ReportRecord.fromJson(Map<String, dynamic> json) => ReportRecord(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String,
        reportType: ReportType.values.byName(json['reportType'] as String),
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        inspectionId: json['inspectionId'] as String,
        linkedInspectionId: json['linkedInspectionId'] as String?,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      );
}
