import '../../../core/database/hive_service.dart';
import 'tenancy_model.dart';

class TenancyRepository {
  List<TenancyRecord> getAll() {
    return HiveService.tenancies.values
        .map((map) => TenancyRecord.fromJson(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  TenancyRecord? getByPropertyId(String propertyId) {
    try {
      final map = HiveService.tenancies.values.firstWhere(
        (map) => Map<String, dynamic>.from(map)['propertyId'] == propertyId,
      );
      return TenancyRecord.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TenancyRecord tenancy) async {
    await HiveService.tenancies.put(tenancy.id, tenancy.toJson());
  }

  Future<void> delete(String id) async {
    await HiveService.tenancies.delete(id);
  }
}
