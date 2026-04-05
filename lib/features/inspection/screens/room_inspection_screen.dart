import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/inspection_providers.dart';
import '../data/inspection_model.dart';
import '../widgets/condition_selector.dart';
import '../widgets/photo_attachment_block.dart';

class RoomInspectionScreen extends ConsumerStatefulWidget {
  final String inspectionId;
  final String roomId;

  const RoomInspectionScreen({
    super.key,
    required this.inspectionId,
    required this.roomId,
  });

  @override
  ConsumerState<RoomInspectionScreen> createState() =>
      _RoomInspectionScreenState();
}

class _RoomInspectionScreenState extends ConsumerState<RoomInspectionScreen> {
  late InspectionRoom _room;
  late List<InspectionChecklistItem> _items;
  late List<String> _roomPhotos;
  String? _roomNotes;
  bool _loaded = false;

  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _itemNotesControllers = {};

  // Track which items have their detail panel expanded
  final Set<String> _expandedItems = {};

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _itemNotesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromInspection() {
    final inspection = ref.read(inspectionByIdProvider(widget.inspectionId));
    if (inspection == null) return;

    try {
      _room = inspection.rooms.firstWhere((r) => r.id == widget.roomId);
    } catch (_) {
      return;
    }

    _items = List.from(_room.items);
    _roomPhotos = List.from(_room.photos);
    _roomNotes = _room.notes;
    _notesController.text = _roomNotes ?? '';

    for (final item in _items) {
      _itemNotesControllers[item.id] =
          TextEditingController(text: item.notes ?? '');
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final updatedItems = _items.map((item) {
      final notesText = _itemNotesControllers[item.id]?.text.trim();
      return item.copyWith(
        notes: notesText != null && notesText.isNotEmpty ? notesText : null,
      );
    }).toList();

    final roomNotesText = _notesController.text.trim();
    final updatedRoom = _room.copyWith(
      items: updatedItems,
      photos: _roomPhotos,
      notes: roomNotesText.isNotEmpty ? roomNotesText : null,
    );

    await ref
        .read(inspectionListProvider.notifier)
        .updateRoom(widget.inspectionId, updatedRoom);
  }

  void _updateItemCondition(int index, ItemCondition condition) {
    setState(() {
      _items[index] = _items[index].copyWith(condition: condition);
    });
    _save();
  }

  void _updateItemPhotos(int index, List<String> photos) {
    setState(() {
      _items[index] = _items[index].copyWith(photos: photos);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    // Re-read from provider on first build
    if (!_loaded) {
      _initFromInspection();
      if (!_loaded) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Room not found')),
        );
      }
    }

    final inspection = ref.watch(inspectionByIdProvider(widget.inspectionId));
    final isCompleted =
        inspection?.status == InspectionStatus.completed;

    final checkedCount = _items.where((i) => i.isChecked).length;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_room.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _room.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: checkedCount == _items.length
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                  child: Text(
                    '$checkedCount/${_items.length}',
                    style: AppTypography.labelMedium.copyWith(
                      color: checkedCount == _items.length
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: AppSpacing.screenPaddingAll,
          children: [
            // Room-level photos
            PhotoAttachmentBlock(
              label: 'Room Photos',
              photos: _roomPhotos,
              onChanged: isCompleted == true
                  ? (_) {}
                  : (photos) {
                      setState(() => _roomPhotos = photos);
                      _save();
                    },
            ),
            AppSpacing.vLg,

            // Room-level notes
            Text('Room Notes', style: AppTypography.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              readOnly: isCompleted == true,
              style: AppTypography.bodyMedium,
              onChanged: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'General notes about this room...',
                hintStyle:
                    AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            ),
            AppSpacing.vXxl,

            // Checklist items grouped by category
            ..._buildCategoryGroups(isCompleted == true),

            AppSpacing.vXxxl,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryGroups(bool readOnly) {
    // Group items by category
    final categories = <String, List<MapEntry<int, InspectionChecklistItem>>>{};
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      categories.putIfAbsent(item.category, () => []);
      categories[item.category]!.add(MapEntry(i, item));
    }

    final widgets = <Widget>[];
    for (final entry in categories.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            entry.key.toUpperCase(),
            style: AppTypography.labelMedium.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      for (final itemEntry in entry.value) {
        widgets.add(
          _ChecklistItemCard(
            item: itemEntry.value,
            index: itemEntry.key,
            readOnly: readOnly,
            isExpanded: _expandedItems.contains(itemEntry.value.id),
            notesController: _itemNotesControllers[itemEntry.value.id]!,
            onConditionChanged: (condition) =>
                _updateItemCondition(itemEntry.key, condition),
            onPhotosChanged: (photos) =>
                _updateItemPhotos(itemEntry.key, photos),
            onNotesSaved: () => _save(),
            onToggleExpand: () {
              setState(() {
                if (_expandedItems.contains(itemEntry.value.id)) {
                  _expandedItems.remove(itemEntry.value.id);
                } else {
                  _expandedItems.add(itemEntry.value.id);
                }
              });
            },
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(AppSpacing.vMd);
    }

    return widgets;
  }
}

class _ChecklistItemCard extends StatelessWidget {
  final InspectionChecklistItem item;
  final int index;
  final bool readOnly;
  final bool isExpanded;
  final TextEditingController notesController;
  final ValueChanged<ItemCondition> onConditionChanged;
  final ValueChanged<List<String>> onPhotosChanged;
  final VoidCallback onNotesSaved;
  final VoidCallback onToggleExpand;

  const _ChecklistItemCard({
    required this.item,
    required this.index,
    required this.readOnly,
    required this.isExpanded,
    required this.notesController,
    required this.onConditionChanged,
    required this.onPhotosChanged,
    required this.onNotesSaved,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetails =
        item.photos.isNotEmpty || (item.notes != null && item.notes!.isNotEmpty);

    return AppCard(
      hasShadow: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              // Condition icon
              Icon(
                conditionIcon(item.condition),
                size: 20,
                color: conditionColor(item.condition),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: item.isChecked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              // Expand/collapse details
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasDetails) ...[
                        if (item.photos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.photo_outlined,
                                size: 14, color: AppColors.info),
                          ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.notes_outlined,
                                size: 14, color: AppColors.textTertiary),
                          ),
                      ],
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Condition selector
          const SizedBox(height: 10),
          if (readOnly)
            ConditionBadge(condition: item.condition)
          else
            ConditionSelector(
              selected: item.condition,
              onChanged: onConditionChanged,
            ),

          // Expandable details
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),

            // Item photos
            PhotoAttachmentBlock(
              label: 'Item Photos',
              photos: item.photos,
              onChanged: readOnly ? (_) {} : onPhotosChanged,
            ),
            const SizedBox(height: 12),

            // Item notes
            Text('Item Notes', style: AppTypography.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: notesController,
              maxLines: 2,
              readOnly: readOnly,
              style: AppTypography.bodyMedium,
              onChanged: (_) => onNotesSaved(),
              decoration: InputDecoration(
                hintText: 'Note about this item...',
                hintStyle: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textTertiary),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
