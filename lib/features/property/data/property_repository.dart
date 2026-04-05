import '../../../core/database/hive_service.dart';
import 'property_model.dart';

class PropertyRepository {
  List<Property> getAll() {
    return HiveService.properties.values
        .map((map) => Property.fromJson(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Property? getById(String id) {
    final map = HiveService.properties.get(id);
    if (map == null) return null;
    return Property.fromJson(Map<String, dynamic>.from(map));
  }

  Future<void> save(Property property) async {
    await HiveService.properties.put(property.id, property.toJson());
  }

  Future<void> delete(String id) async {
    await HiveService.properties.delete(id);
  }
}
