import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/inspection_providers.dart';
import '../data/inspection_model.dart';
import '../widgets/condition_selector.dart';

class InspectionSummaryScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const InspectionSummaryScreen({super.key, required this.inspectionId});

  @override
  ConsumerState<InspectionSummaryScreen> createState() =>
      _InspectionSummaryScreenState();
}

class _InspectionSummaryScreenState
    extends ConsumerState<InspectionSummaryScreen> {
  bool _completing = false;

  Future<void> _complete() async {
    setState(() => _completing = true);
    try {
      await ref
          .read(inspectionListProvider.notifier)
          .complete(widget.inspectionId);

      if (mounted) {
        // Pop back to the inspection overview (which will now show completed state)
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final inspection = ref.watch(inspectionByIdProvider(widget.inspectionId));

    if (inspection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    // Compute stats
    final totalOk = inspection.rooms.fold(0, (s, r) => s + r.okCount);
    final totalMinor = inspection.rooms.fold(0, (s, r) => s + r.minorCount);
    final totalMajor = inspection.rooms.fold(0, (s, r) => s + r.majorCount);
    final totalMissing =
        inspection.rooms.fold(0, (s, r) => s + r.missingCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Complete'),
      ),
      body: ListView(
        padding: AppSpacing.screenPaddingAll,
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: AppRadius.borderRadiusXl,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fact_check_outlined,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('Inspection Summary', style: AppTypography.h2),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${inspection.type.label} inspection started on ${dateFormat.format(inspection.startedAt)}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                // Stats grid
                Row(
                  children: [
                    _StatTile(
                      count: totalOk,
                      label: 'Good',
                      color: AppColors.success,
                    ),
                    AppSpacing.hSm,
                    _StatTile(
                      count: totalMinor,
                      label: 'Minor',
                      color: AppColors.warning,
                    ),
                    AppSpacing.hSm,
                    _StatTile(
                      count: totalMajor,
                      label: 'Major',
                      color: AppColors.error,
                    ),
                    AppSpacing.hSm,
                    _StatTile(
                      count: totalMissing,
                      label: 'Missing',
                      color: conditionColor(ItemCondition.missing),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${inspection.totalPhotos} photos attached',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vXxl,

          // Room-by-room breakdown
          Text('Room Breakdown', style: AppTypography.h3),
          AppSpacing.vMd,

          ...inspection.rooms.map((room) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoomSummaryCard(room: room),
              )),

          AppSpacing.vXxl,

          // Issues list (if any)
          if (totalMinor + totalMajor + totalMissing > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: AppRadius.borderRadiusMd,
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${totalMinor + totalMajor + totalMissing} issues found',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...inspection.rooms.expand((room) {
                    return room.items
                        .where((i) =>
                            i.condition == ItemCondition.minorDamage ||
                            i.condition == ItemCondition.majorDamage ||
                            i.condition == ItemCondition.missing)
                        .map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  ConditionBadge(condition: i.condition),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${room.name} \u2022 ${i.name}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ));
                  }),
                ],
              ),
            ),
            AppSpacing.vXxl,
          ],

          // Complete button
          AppButton(
            label: 'Mark as Completed',
            onPressed: _complete,
            isLoading: _completing,
            icon: Icons.check_circle_outline,
          ),
          AppSpacing.vMd,
          Text(
            'Once completed, this inspection will be saved as your official move-in record.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),

          AppSpacing.vXxxl,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.h2.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomSummaryCard extends StatelessWidget {
  final InspectionRoom room;

  const _RoomSummaryCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: room.hasIssues
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Center(
              child: Text(room.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (room.okCount > 0)
                      Text('${room.okCount} OK',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.success)),
                    if (room.minorCount > 0)
                      Text('${room.minorCount} Minor',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.warning)),
                    if (room.majorCount > 0)
                      Text('${room.majorCount} Major',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.error)),
                    if (room.missingCount > 0)
                      Text('${room.missingCount} Missing',
                          style: AppTypography.labelSmall.copyWith(
                              color: conditionColor(ItemCondition.missing))),
                  ],
                ),
              ],
            ),
          ),
          if (room.photos.isNotEmpty ||
              room.items.any((i) => i.photos.isNotEmpty))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_outlined, size: 14, color: AppColors.info),
                const SizedBox(width: 3),
                Text(
                  '${room.photos.length + room.items.fold(0, (s, i) => s + i.photos.length)}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.info),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
