import 'inspection_model.dart';

/// Describes how an item's condition changed between move-in and move-out.
enum ChangeType {
  unchanged,
  worsened,
  improved,
  newIssue,
  resolved;

  String get label {
    switch (this) {
      case ChangeType.unchanged:
        return 'No change';
      case ChangeType.worsened:
        return 'Worsened';
      case ChangeType.improved:
        return 'Improved';
      case ChangeType.newIssue:
        return 'New issue';
      case ChangeType.resolved:
        return 'Resolved';
    }
  }
}

/// Comparison result for a single checklist item.
class ItemComparison {
  final String name;
  final String category;
  final String templateId;
  final ItemCondition moveInCondition;
  final ItemCondition moveOutCondition;
  final ChangeType changeType;
  final bool moveInHasNotes;
  final bool moveOutHasNotes;
  final int moveInPhotos;
  final int moveOutPhotos;

  const ItemComparison({
    required this.name,
    required this.category,
    required this.templateId,
    required this.moveInCondition,
    required this.moveOutCondition,
    required this.changeType,
    this.moveInHasNotes = false,
    this.moveOutHasNotes = false,
    this.moveInPhotos = 0,
    this.moveOutPhotos = 0,
  });

  bool get hasChanged => changeType != ChangeType.unchanged;
  bool get isWorsened =>
      changeType == ChangeType.worsened || changeType == ChangeType.newIssue;
}

/// Comparison result for a room.
class RoomComparison {
  final String name;
  final String icon;
  final String templateId;
  final List<ItemComparison> items;
  final bool moveInHasNotes;
  final bool moveOutHasNotes;
  final int moveInPhotos;
  final int moveOutPhotos;

  const RoomComparison({
    required this.name,
    required this.icon,
    required this.templateId,
    required this.items,
    this.moveInHasNotes = false,
    this.moveOutHasNotes = false,
    this.moveInPhotos = 0,
    this.moveOutPhotos = 0,
  });

  int get totalItems => items.length;
  int get changedItems => items.where((i) => i.hasChanged).length;
  int get worsenedItems => items.where((i) => i.isWorsened).length;
  int get improvedItems =>
      items.where((i) => i.changeType == ChangeType.improved || i.changeType == ChangeType.resolved).length;
  bool get hasChanges => changedItems > 0;
}

/// Full comparison between a move-in and move-out inspection.
class InspectionComparison {
  final Inspection moveIn;
  final Inspection moveOut;
  final List<RoomComparison> rooms;

  const InspectionComparison({
    required this.moveIn,
    required this.moveOut,
    required this.rooms,
  });

  int get totalItems => rooms.fold(0, (s, r) => s + r.totalItems);
  int get changedItems => rooms.fold(0, (s, r) => s + r.changedItems);
  int get unchangedItems => totalItems - changedItems;
  int get worsenedItems => rooms.fold(0, (s, r) => s + r.worsenedItems);
  int get improvedItems => rooms.fold(0, (s, r) => s + r.improvedItems);
  int get roomsWithChanges => rooms.where((r) => r.hasChanges).length;
}

/// Computes comparison between a completed move-in and a move-out inspection.
InspectionComparison computeComparison(
    Inspection moveIn, Inspection moveOut) {
  final roomComparisons = <RoomComparison>[];

  for (final moveOutRoom in moveOut.rooms) {
    // Match room by templateId
    final moveInRoom = moveIn.rooms
        .where((r) => r.templateId == moveOutRoom.templateId)
        .firstOrNull;

    if (moveInRoom == null) continue;

    final itemComparisons = <ItemComparison>[];

    for (final moveOutItem in moveOutRoom.items) {
      // Match item by templateId
      final moveInItem = moveInRoom.items
          .where((i) => i.templateId == moveOutItem.templateId)
          .firstOrNull;

      final miCondition = moveInItem?.condition ?? ItemCondition.unchecked;
      final moCondition = moveOutItem.condition;

      final changeType = _determineChangeType(miCondition, moCondition);

      itemComparisons.add(ItemComparison(
        name: moveOutItem.name,
        category: moveOutItem.category,
        templateId: moveOutItem.templateId,
        moveInCondition: miCondition,
        moveOutCondition: moCondition,
        changeType: changeType,
        moveInHasNotes:
            moveInItem?.notes != null && moveInItem!.notes!.isNotEmpty,
        moveOutHasNotes:
            moveOutItem.notes != null && moveOutItem.notes!.isNotEmpty,
        moveInPhotos: moveInItem?.photos.length ?? 0,
        moveOutPhotos: moveOutItem.photos.length,
      ));
    }

    final miRoomPhotos = moveInRoom.photos.length +
        moveInRoom.items.fold<int>(0, (s, i) => s + i.photos.length);
    final moRoomPhotos = moveOutRoom.photos.length +
        moveOutRoom.items.fold<int>(0, (s, i) => s + i.photos.length);

    roomComparisons.add(RoomComparison(
      name: moveOutRoom.name,
      icon: moveOutRoom.icon,
      templateId: moveOutRoom.templateId,
      items: itemComparisons,
      moveInHasNotes:
          moveInRoom.notes != null && moveInRoom.notes!.isNotEmpty,
      moveOutHasNotes:
          moveOutRoom.notes != null && moveOutRoom.notes!.isNotEmpty,
      moveInPhotos: miRoomPhotos,
      moveOutPhotos: moRoomPhotos,
    ));
  }

  return InspectionComparison(
    moveIn: moveIn,
    moveOut: moveOut,
    rooms: roomComparisons,
  );
}

ChangeType _determineChangeType(
    ItemCondition moveIn, ItemCondition moveOut) {
  // If both unchecked, treat as unchanged
  if (moveIn == ItemCondition.unchecked &&
      moveOut == ItemCondition.unchecked) {
    return ChangeType.unchanged;
  }

  // Same condition = no change
  if (moveIn == moveOut) return ChangeType.unchanged;

  // Move-in was OK, move-out has issue = new issue
  if (moveIn == ItemCondition.ok && moveOut.severity > moveIn.severity) {
    return ChangeType.newIssue;
  }

  // Move-in had issue, move-out is OK = resolved
  if (moveOut == ItemCondition.ok && moveIn.severity > moveOut.severity) {
    return ChangeType.resolved;
  }

  // Severity increased = worsened
  if (moveOut.severity > moveIn.severity) {
    return ChangeType.worsened;
  }

  // Severity decreased = improved
  if (moveOut.severity < moveIn.severity) {
    return ChangeType.improved;
  }

  return ChangeType.unchanged;
}
