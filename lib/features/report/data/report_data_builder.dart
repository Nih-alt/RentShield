import '../../property/data/property_model.dart';
import '../../tenancy/data/tenancy_model.dart';
import '../../inspection/data/inspection_model.dart';
import '../../inspection/data/comparison_model.dart';
import 'report_model.dart';

/// Structured data for a room in the report.
class ReportRoomData {
  final String name;
  final String icon;
  final int totalItems;
  final int okCount;
  final int minorCount;
  final int majorCount;
  final int missingCount;
  final String? notes;
  final List<String> roomPhotos;
  final List<ReportItemData> items;

  const ReportRoomData({
    required this.name,
    required this.icon,
    required this.totalItems,
    required this.okCount,
    required this.minorCount,
    required this.majorCount,
    required this.missingCount,
    this.notes,
    this.roomPhotos = const [],
    this.items = const [],
  });

  bool get hasIssues => minorCount > 0 || majorCount > 0 || missingCount > 0;
}

/// Structured data for a checklist item in the report.
class ReportItemData {
  final String name;
  final String category;
  final String conditionLabel;
  final String? notes;
  final List<String> photos;
  final bool hasIssue;

  const ReportItemData({
    required this.name,
    required this.category,
    required this.conditionLabel,
    this.notes,
    this.photos = const [],
    this.hasIssue = false,
  });
}

/// Structured data for a comparison item in the report.
class ReportComparisonItemData {
  final String name;
  final String category;
  final String roomName;
  final String moveInCondition;
  final String moveOutCondition;
  final String changeLabel;
  final ChangeType changeType;
  final List<String> moveInPhotos;
  final List<String> moveOutPhotos;
  final String? moveInNotes;
  final String? moveOutNotes;

  const ReportComparisonItemData({
    required this.name,
    required this.category,
    required this.roomName,
    required this.moveInCondition,
    required this.moveOutCondition,
    required this.changeLabel,
    required this.changeType,
    this.moveInPhotos = const [],
    this.moveOutPhotos = const [],
    this.moveInNotes,
    this.moveOutNotes,
  });

  bool get isWorsened =>
      changeType == ChangeType.worsened || changeType == ChangeType.newIssue;
}

/// Structured data for a comparison room.
class ReportComparisonRoomData {
  final String name;
  final String icon;
  final int totalItems;
  final int unchangedCount;
  final int worsenedCount;
  final int improvedCount;
  final List<ReportComparisonItemData> items;

  const ReportComparisonRoomData({
    required this.name,
    required this.icon,
    required this.totalItems,
    required this.unchangedCount,
    required this.worsenedCount,
    required this.improvedCount,
    this.items = const [],
  });
}

/// Full structured report data, ready for PDF rendering.
class ReportData {
  final ReportType reportType;
  final String propertyName;
  final String propertyAddress;
  final String propertyType;

  // Tenancy
  final bool hasTenancy;
  final String? landlordName;
  final String? landlordPhone;
  final String? tenancyRent;
  final String? tenancyDeposit;
  final String? tenancyStart;
  final String? tenancyEnd;

  // Single inspection data (move-in or move-out)
  final String? inspectionDate;
  final String? inspectionType;
  final int totalRooms;
  final int totalItems;
  final int totalIssues;
  final int totalPhotos;
  final int okCount;
  final int minorCount;
  final int majorCount;
  final int missingCount;
  final List<ReportRoomData> rooms;

  // Comparison-specific data
  final String? moveInDate;
  final String? moveOutDate;
  final int unchangedCount;
  final int worsenedCount;
  final int improvedCount;
  final int roomsWithChanges;
  final List<ReportComparisonRoomData> comparisonRooms;
  final List<ReportComparisonItemData> flaggedItems;

  // Photo paths for embedding (curated selection)
  final List<String> selectedPhotoPaths;

  final DateTime generatedAt;

  const ReportData({
    required this.reportType,
    required this.propertyName,
    required this.propertyAddress,
    required this.propertyType,
    this.hasTenancy = false,
    this.landlordName,
    this.landlordPhone,
    this.tenancyRent,
    this.tenancyDeposit,
    this.tenancyStart,
    this.tenancyEnd,
    this.inspectionDate,
    this.inspectionType,
    this.totalRooms = 0,
    this.totalItems = 0,
    this.totalIssues = 0,
    this.totalPhotos = 0,
    this.okCount = 0,
    this.minorCount = 0,
    this.majorCount = 0,
    this.missingCount = 0,
    this.rooms = const [],
    this.moveInDate,
    this.moveOutDate,
    this.unchangedCount = 0,
    this.worsenedCount = 0,
    this.improvedCount = 0,
    this.roomsWithChanges = 0,
    this.comparisonRooms = const [],
    this.flaggedItems = const [],
    this.selectedPhotoPaths = const [],
    required this.generatedAt,
  });
}

/// Builds ReportData from existing domain objects.
class ReportDataBuilder {
  static const int _maxPhotosPerRoom = 3;
  static const int _maxPhotosPerItem = 2;
  static const int _maxTotalPhotos = 30;

  /// Build report data for a single inspection (move-in or move-out).
  static ReportData buildSingleInspection({
    required Inspection inspection,
    required Property property,
    TenancyRecord? tenancy,
  }) {
    final rooms = <ReportRoomData>[];
    final allPhotos = <String>[];

    for (final room in inspection.rooms) {
      final itemData = <ReportItemData>[];

      for (final item in room.items) {
        if (!item.isChecked) continue;

        final hasIssue = item.condition != ItemCondition.ok;

        // Prioritize issue item photos
        final itemPhotos = _selectPhotos(
          item.photos,
          hasIssue ? _maxPhotosPerItem : 1,
          allPhotos.length,
        );
        allPhotos.addAll(itemPhotos);

        itemData.add(ReportItemData(
          name: item.name,
          category: item.category,
          conditionLabel: item.condition.label,
          notes: item.notes,
          photos: itemPhotos,
          hasIssue: hasIssue,
        ));
      }

      // Room-level photos
      final roomPhotos = _selectPhotos(
        room.photos,
        _maxPhotosPerRoom,
        allPhotos.length,
      );
      allPhotos.addAll(roomPhotos);

      rooms.add(ReportRoomData(
        name: room.name,
        icon: room.icon,
        totalItems: room.totalItems,
        okCount: room.okCount,
        minorCount: room.minorCount,
        majorCount: room.majorCount,
        missingCount: room.missingCount,
        notes: room.notes,
        roomPhotos: roomPhotos,
        items: itemData,
      ));
    }

    return ReportData(
      reportType: inspection.type == InspectionType.moveIn
          ? ReportType.moveIn
          : ReportType.moveOut,
      propertyName: property.name,
      propertyAddress: property.fullAddress,
      propertyType: property.propertyType.label,
      hasTenancy: tenancy != null,
      landlordName: tenancy?.landlordName,
      landlordPhone: tenancy?.landlordPhone,
      tenancyRent: tenancy?.monthlyRent.toStringAsFixed(0),
      tenancyDeposit: tenancy?.securityDeposit.toStringAsFixed(0),
      tenancyStart: tenancy?.tenancyStartDate.toIso8601String(),
      tenancyEnd: tenancy?.tenancyEndDate?.toIso8601String(),
      inspectionDate: (inspection.completedAt ?? inspection.startedAt)
          .toIso8601String(),
      inspectionType: inspection.type.label,
      totalRooms: inspection.totalRooms,
      totalItems: inspection.totalItems,
      totalIssues: inspection.totalIssues,
      totalPhotos: inspection.totalPhotos,
      okCount: inspection.rooms.fold(0, (s, r) => s + r.okCount),
      minorCount: inspection.rooms.fold(0, (s, r) => s + r.minorCount),
      majorCount: inspection.rooms.fold(0, (s, r) => s + r.majorCount),
      missingCount: inspection.rooms.fold(0, (s, r) => s + r.missingCount),
      rooms: rooms,
      selectedPhotoPaths: allPhotos,
      generatedAt: DateTime.now(),
    );
  }

  /// Build report data for a comparison report.
  static ReportData buildComparison({
    required InspectionComparison comparison,
    required Property property,
    TenancyRecord? tenancy,
  }) {
    final compRooms = <ReportComparisonRoomData>[];
    final flagged = <ReportComparisonItemData>[];
    final allPhotos = <String>[];

    for (final room in comparison.rooms) {
      final items = <ReportComparisonItemData>[];

      for (final item in room.items) {
        // Collect photos for flagged items
        List<String> miPhotos = const [];
        List<String> moPhotos = const [];

        if (item.isWorsened) {
          // Find the actual room/items in the inspections to get photo paths
          final miRoom = comparison.moveIn.rooms
              .where((r) => r.templateId == room.templateId)
              .firstOrNull;
          final moRoom = comparison.moveOut.rooms
              .where((r) => r.templateId == room.templateId)
              .firstOrNull;

          final miItem = miRoom?.items
              .where((i) => i.templateId == item.templateId)
              .firstOrNull;
          final moItem = moRoom?.items
              .where((i) => i.templateId == item.templateId)
              .firstOrNull;

          miPhotos = _selectPhotos(
              miItem?.photos ?? [], 1, allPhotos.length);
          moPhotos = _selectPhotos(
              moItem?.photos ?? [], 1, allPhotos.length + miPhotos.length);
          allPhotos.addAll(miPhotos);
          allPhotos.addAll(moPhotos);
        }

        final compItem = ReportComparisonItemData(
          name: item.name,
          category: item.category,
          roomName: room.name,
          moveInCondition: item.moveInCondition.label,
          moveOutCondition: item.moveOutCondition.label,
          changeLabel: item.changeType.label,
          changeType: item.changeType,
          moveInPhotos: miPhotos,
          moveOutPhotos: moPhotos,
        );

        items.add(compItem);
        if (item.isWorsened) {
          flagged.add(compItem);
        }
      }

      final unchanged =
          room.items.where((i) => !i.hasChanged).length;

      compRooms.add(ReportComparisonRoomData(
        name: room.name,
        icon: room.icon,
        totalItems: room.totalItems,
        unchangedCount: unchanged,
        worsenedCount: room.worsenedItems,
        improvedCount: room.improvedItems,
        items: items,
      ));
    }

    return ReportData(
      reportType: ReportType.comparison,
      propertyName: property.name,
      propertyAddress: property.fullAddress,
      propertyType: property.propertyType.label,
      hasTenancy: tenancy != null,
      landlordName: tenancy?.landlordName,
      landlordPhone: tenancy?.landlordPhone,
      tenancyRent: tenancy?.monthlyRent.toStringAsFixed(0),
      tenancyDeposit: tenancy?.securityDeposit.toStringAsFixed(0),
      tenancyStart: tenancy?.tenancyStartDate.toIso8601String(),
      tenancyEnd: tenancy?.tenancyEndDate?.toIso8601String(),
      moveInDate: comparison.moveIn.startedAt.toIso8601String(),
      moveOutDate: comparison.moveOut.startedAt.toIso8601String(),
      totalRooms: comparison.rooms.length,
      totalItems: comparison.totalItems,
      unchangedCount: comparison.unchangedItems,
      worsenedCount: comparison.worsenedItems,
      improvedCount: comparison.improvedItems,
      roomsWithChanges: comparison.roomsWithChanges,
      comparisonRooms: compRooms,
      flaggedItems: flagged,
      selectedPhotoPaths: allPhotos,
      generatedAt: DateTime.now(),
    );
  }

  /// Selects a limited number of photos, respecting the total budget.
  static List<String> _selectPhotos(
    List<String> available,
    int maxFromThis,
    int currentTotal,
  ) {
    if (available.isEmpty) return const [];
    final remaining = _maxTotalPhotos - currentTotal;
    if (remaining <= 0) return const [];
    final take = maxFromThis.clamp(0, remaining);
    return available.take(take).toList();
  }
}
