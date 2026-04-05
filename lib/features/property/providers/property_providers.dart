import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/property_model.dart';
import '../data/property_repository.dart';

final propertyRepositoryProvider = Provider((ref) => PropertyRepository());

final propertyListProvider =
    StateNotifierProvider<PropertyListNotifier, List<Property>>((ref) {
  return PropertyListNotifier(ref.watch(propertyRepositoryProvider));
});

final propertyByIdProvider =
    Provider.family<Property?, String>((ref, id) {
  final properties = ref.watch(propertyListProvider);
  try {
    return properties.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

class PropertyListNotifier extends StateNotifier<List<Property>> {
  final PropertyRepository _repo;
  static const _uuid = Uuid();

  PropertyListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<Property> create({
    required String name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    required PropertyType propertyType,
    String? notes,
  }) async {
    final now = DateTime.now();
    final property = Property(
      id: _uuid.v4(),
      name: name,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      pincode: pincode,
      propertyType: propertyType,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.save(property);
    _load();
    return property;
  }

  Future<void> update(Property property) async {
    await _repo.save(property);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}
