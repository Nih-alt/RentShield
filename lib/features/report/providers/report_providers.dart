import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../property/providers/property_providers.dart';
import '../../tenancy/providers/tenancy_providers.dart';
import '../../inspection/providers/inspection_providers.dart';
import '../../inspection/data/comparison_model.dart';
import '../data/report_model.dart';
import '../data/report_repository.dart';
import '../data/report_data_builder.dart';
import '../data/pdf_report_generator.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

final reportListProvider =
    StateNotifierProvider<ReportListNotifier, List<ReportRecord>>((ref) {
  return ReportListNotifier(ref.watch(reportRepositoryProvider));
});

final reportsByPropertyIdProvider =
    Provider.family<List<ReportRecord>, String>((ref, propertyId) {
  final reports = ref.watch(reportListProvider);
  return reports.where((r) => r.propertyId == propertyId).toList();
});

/// Tracks report generation state.
enum ReportGenerationStatus { idle, generating, success, error }

class ReportGenerationState {
  final ReportGenerationStatus status;
  final String? filePath;
  final String? errorMessage;
  final ReportRecord? report;

  const ReportGenerationState({
    this.status = ReportGenerationStatus.idle,
    this.filePath,
    this.errorMessage,
    this.report,
  });

  ReportGenerationState copyWith({
    ReportGenerationStatus? status,
    String? filePath,
    String? errorMessage,
    ReportRecord? report,
  }) {
    return ReportGenerationState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      report: report ?? this.report,
    );
  }
}

final reportGenerationProvider = StateNotifierProvider.autoDispose<
    ReportGenerationNotifier, ReportGenerationState>((ref) {
  return ReportGenerationNotifier(ref);
});

class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  final Ref _ref;
  static const _uuid = Uuid();

  ReportGenerationNotifier(this._ref)
      : super(const ReportGenerationState());

  /// Generate a single inspection report (move-in or move-out).
  Future<void> generateSingleReport(String inspectionId) async {
    state = const ReportGenerationState(
        status: ReportGenerationStatus.generating);

    try {
      final inspection =
          _ref.read(inspectionByIdProvider(inspectionId));
      if (inspection == null) {
        throw Exception('Inspection not found');
      }

      final property =
          _ref.read(propertyByIdProvider(inspection.propertyId));
      if (property == null) {
        throw Exception('Property not found');
      }

      final tenancy =
          _ref.read(tenancyByPropertyIdProvider(inspection.propertyId));

      // Build report data
      final reportData = ReportDataBuilder.buildSingleInspection(
        inspection: inspection,
        property: property,
        tenancy: tenancy,
      );

      // Generate PDF
      final generator = PdfReportGenerator();
      final filePath = await generator.generate(reportData);

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Save report record
      final record = ReportRecord(
        id: _uuid.v4(),
        propertyId: inspection.propertyId,
        reportType: reportData.reportType,
        filePath: filePath,
        fileName: filePath.split(Platform.pathSeparator).last,
        createdAt: DateTime.now(),
        inspectionId: inspectionId,
        fileSizeBytes: fileSize,
      );

      await _ref.read(reportRepositoryProvider).save(record);
      _ref.read(reportListProvider.notifier).reload();

      state = ReportGenerationState(
        status: ReportGenerationStatus.success,
        filePath: filePath,
        report: record,
      );
    } catch (e) {
      state = ReportGenerationState(
        status: ReportGenerationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Generate a comparison report from a move-out inspection.
  Future<void> generateComparisonReport(String moveOutInspectionId) async {
    state = const ReportGenerationState(
        status: ReportGenerationStatus.generating);

    try {
      final moveOut =
          _ref.read(inspectionByIdProvider(moveOutInspectionId));
      if (moveOut == null || moveOut.linkedMoveInInspectionId == null) {
        throw Exception('Move-out inspection or linked move-in not found');
      }

      final moveIn = _ref.read(
          inspectionByIdProvider(moveOut.linkedMoveInInspectionId!));
      if (moveIn == null) {
        throw Exception('Linked move-in inspection not found');
      }

      final property =
          _ref.read(propertyByIdProvider(moveOut.propertyId));
      if (property == null) {
        throw Exception('Property not found');
      }

      final tenancy =
          _ref.read(tenancyByPropertyIdProvider(moveOut.propertyId));

      // Compute comparison
      final comparison = computeComparison(moveIn, moveOut);

      // Build report data
      final reportData = ReportDataBuilder.buildComparison(
        comparison: comparison,
        property: property,
        tenancy: tenancy,
      );

      // Generate PDF
      final generator = PdfReportGenerator();
      final filePath = await generator.generate(reportData);

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Save report record
      final record = ReportRecord(
        id: _uuid.v4(),
        propertyId: moveOut.propertyId,
        reportType: ReportType.comparison,
        filePath: filePath,
        fileName: filePath.split(Platform.pathSeparator).last,
        createdAt: DateTime.now(),
        inspectionId: moveOutInspectionId,
        linkedInspectionId: moveOut.linkedMoveInInspectionId,
        fileSizeBytes: fileSize,
      );

      await _ref.read(reportRepositoryProvider).save(record);
      _ref.read(reportListProvider.notifier).reload();

      state = ReportGenerationState(
        status: ReportGenerationStatus.success,
        filePath: filePath,
        report: record,
      );
    } catch (e) {
      state = ReportGenerationState(
        status: ReportGenerationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const ReportGenerationState();
  }
}

class ReportListNotifier extends StateNotifier<List<ReportRecord>> {
  final ReportRepository _repo;

  ReportListNotifier(this._repo) : super([]) {
    reload();
  }

  void reload() {
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    // Try to delete the file too
    final report = _repo.getById(id);
    if (report != null) {
      try {
        final file = File(report.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    await _repo.delete(id);
    reload();
  }
}
