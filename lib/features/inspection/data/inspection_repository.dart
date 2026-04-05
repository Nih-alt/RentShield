import '../../../core/database/hive_service.dart';
import 'inspection_model.dart';

class InspectionRepository {
  List<Inspection> getAll() {
    return HiveService.inspections.values
        .map((map) => Inspection.fromJson(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Inspection> getByPropertyId(String propertyId) {
    return getAll().where((i) => i.propertyId == propertyId).toList();
  }

  Inspection? getById(String id) {
    final map = HiveService.inspections.get(id);
    if (map == null) return null;
    return Inspection.fromJson(Map<String, dynamic>.from(map));
  }

  Future<void> save(Inspection inspection) async {
    await HiveService.inspections.put(inspection.id, inspection.toJson());
  }

  Future<void> delete(String id) async {
    await HiveService.inspections.delete(id);
  }
}
