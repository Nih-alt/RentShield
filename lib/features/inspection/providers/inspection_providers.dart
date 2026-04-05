import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/inspection_model.dart';
import '../data/inspection_repository.dart';
import '../data/comparison_model.dart';
import '../data/room_template.dart';

final inspectionRepositoryProvider =
    Provider((ref) => InspectionRepository());

final inspectionListProvider =
    StateNotifierProvider<InspectionListNotifier, List<Inspection>>((ref) {
  return InspectionListNotifier(ref.watch(inspectionRepositoryProvider));
});

final inspectionsByPropertyIdProvider =
    Provider.family<List<Inspection>, String>((ref, propertyId) {
  final inspections = ref.watch(inspectionListProvider);
  return inspections.where((i) => i.propertyId == propertyId).toList();
});

final inspectionByIdProvider =
    Provider.family<Inspection?, String>((ref, id) {
  final inspections = ref.watch(inspectionListProvider);
  try {
    return inspections.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
});

/// Computes comparison for a move-out inspection against its linked move-in.
final comparisonProvider =
    Provider.family<InspectionComparison?, String>((ref, moveOutInspectionId) {
  final moveOut = ref.watch(inspectionByIdProvider(moveOutInspectionId));
  if (moveOut == null || moveOut.linkedMoveInInspectionId == null) return null;

  final moveIn =
      ref.watch(inspectionByIdProvider(moveOut.linkedMoveInInspectionId!));
  if (moveIn == null) return null;

  return computeComparison(moveIn, moveOut);
});

class InspectionListNotifier extends StateNotifier<List<Inspection>> {
  final InspectionRepository _repo;
  static const _uuid = Uuid();

  InspectionListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  /// Creates a new move-in inspection from default room templates.
  Future<Inspection> createMoveIn(String propertyId) async {
    final now = DateTime.now();
    final inspectionId = _uuid.v4();

    final rooms = DefaultTemplates.rooms.map((template) {
      final roomId = _uuid.v4();
      return InspectionRoom(
        id: roomId,
        templateId: template.id,
        name: template.name,
        icon: template.icon,
        items: template.checklistItems.map((item) {
          return InspectionChecklistItem(
            id: _uuid.v4(),
            templateId: item.id,
            name: item.name,
            category: item.category,
            condition: ItemCondition.ok,
          );
        }).toList(),
      );
    }).toList();

    final inspection = Inspection(
      id: inspectionId,
      propertyId: propertyId,
      type: InspectionType.moveIn,
      status: InspectionStatus.draft,
      createdAt: now,
      updatedAt: now,
      startedAt: now,
      rooms: rooms,
    );

    await _repo.save(inspection);
    _load();
    return inspection;
  }

  /// Creates a move-out inspection cloning structure from the linked move-in.
  Future<Inspection> createMoveOut(
      String propertyId, String linkedMoveInId) async {
    final moveIn = _repo.getById(linkedMoveInId);
    if (moveIn == null) {
      throw StateError('Linked move-in inspection not found');
    }

    final now = DateTime.now();
    final inspectionId = _uuid.v4();

    // Clone room/item structure from move-in (same templateIds) with fresh IDs
    final rooms = moveIn.rooms.map((miRoom) {
      return InspectionRoom(
        id: _uuid.v4(),
        templateId: miRoom.templateId,
        name: miRoom.name,
        icon: miRoom.icon,
        items: miRoom.items.map((miItem) {
          return InspectionChecklistItem(
            id: _uuid.v4(),
            templateId: miItem.templateId,
            name: miItem.name,
            category: miItem.category,
            condition: ItemCondition.ok,
          );
        }).toList(),
      );
    }).toList();

    final inspection = Inspection(
      id: inspectionId,
      propertyId: propertyId,
      type: InspectionType.moveOut,
      status: InspectionStatus.draft,
      createdAt: now,
      updatedAt: now,
      startedAt: now,
      linkedMoveInInspectionId: linkedMoveInId,
      rooms: rooms,
    );

    await _repo.save(inspection);
    _load();
    return inspection;
  }

  /// Updates a single room within an inspection.
  Future<void> updateRoom(
      String inspectionId, InspectionRoom updatedRoom) async {
    final inspection = _repo.getById(inspectionId);
    if (inspection == null) return;

    final rooms = inspection.rooms.map((r) {
      return r.id == updatedRoom.id ? updatedRoom : r;
    }).toList();

    final updated = inspection.copyWith(
      rooms: rooms,
      updatedAt: DateTime.now(),
    );
    await _repo.save(updated);
    _load();
  }

  /// Marks an inspection as completed.
  Future<void> complete(String inspectionId) async {
    final inspection = _repo.getById(inspectionId);
    if (inspection == null) return;

    final now = DateTime.now();
    final updated = inspection.copyWith(
      status: InspectionStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    await _repo.save(updated);
    _load();
  }

  /// Deletes an inspection.
  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}
