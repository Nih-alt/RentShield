import '../../../core/database/hive_service.dart';
import 'report_model.dart';

class ReportRepository {
  List<ReportRecord> getAll() {
    return HiveService.reports.values
        .map((map) => ReportRecord.fromJson(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ReportRecord> getByPropertyId(String propertyId) {
    return getAll().where((r) => r.propertyId == propertyId).toList();
  }

  ReportRecord? getById(String id) {
    final map = HiveService.reports.get(id);
    if (map == null) return null;
    return ReportRecord.fromJson(Map<String, dynamic>.from(map));
  }

  Future<void> save(ReportRecord report) async {
    await HiveService.reports.put(report.id, report.toJson());
  }

  Future<void> delete(String id) async {
    await HiveService.reports.delete(id);
  }
}
