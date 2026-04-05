import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/inspection_providers.dart';
import '../data/inspection_model.dart';
import '../widgets/room_progress_card.dart';

class InspectionOverviewScreen extends ConsumerWidget {
  final String inspectionId;

  const InspectionOverviewScreen({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspection = ref.watch(inspectionByIdProvider(inspectionId));

    if (inspection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    final isCompleted = inspection.status == InspectionStatus.completed;
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('${inspection.type.label} Inspection'),
        actions: [
          if (!isCompleted)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Inspection'),
                      content: const Text(
                          'This will permanently delete this inspection and all its data.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(inspectionListProvider.notifier)
                        .delete(inspectionId);
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Inspection'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPaddingAll,
        children: [
          // Progress overview card
          _ProgressCard(inspection: inspection),
          AppSpacing.vXxl,

          // Status & date info
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inspection Completed',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.success)),
                        if (inspection.completedAt != null)
                          Text(
                            dateFormat.format(inspection.completedAt!),
                            style: AppTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vXxl,
          ],

          // Rooms section
          SectionHeader(
            title: 'Rooms',
            subtitle:
                '${inspection.completedRooms} of ${inspection.totalRooms} complete',
          ),
          AppSpacing.vMd,

          ...inspection.rooms.asMap().entries.map((entry) {
            final room = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RoomProgressCard(
                room: room,
                onTap: () => context.push(
                  '/inspections/$inspectionId/rooms/${room.id}',
                ),
              ),
            );
          }),

          AppSpacing.vXxl,

          // Complete button (only for drafts with all rooms done)
          if (!isCompleted) ...[
            ElevatedButton(
              onPressed: inspection.allRoomsComplete
                  ? () => context.push('/inspections/$inspectionId/summary')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surfaceVariant,
                disabledForegroundColor: AppColors.textTertiary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    inspection.allRoomsComplete
                        ? Icons.check_circle_outline
                        : Icons.lock_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inspection.allRoomsComplete
                        ? 'Review & Complete'
                        : 'Complete all rooms to finish',
                    style: AppTypography.button,
                  ),
                ],
              ),
            ),
          ],

          // Compare button for completed move-out inspections
          if (isCompleted &&
              inspection.type == InspectionType.moveOut &&
              inspection.linkedMoveInInspectionId != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/inspections/$inspectionId/compare'),
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text('View Before & After Comparison'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side:
                    BorderSide(color: AppColors.info.withValues(alpha: 0.3)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
            ),
          ],

          // Generate report button for completed inspections
          if (isCompleted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final reportType =
                    inspection.type == InspectionType.moveIn
                        ? 'moveIn'
                        : 'moveOut';
                context.push(
                    '/inspections/$inspectionId/report/$reportType');
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(
                  'Generate ${inspection.type.label} Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
            ),
          ],

          AppSpacing.vXxxl,
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Inspection inspection;

  const _ProgressCard({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final percentage = (inspection.overallProgress * 100).round();
    final isCompleted = inspection.status == InspectionStatus.completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [AppColors.success, const Color(0xFF16A34A)]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'Completed' : 'In Progress',
                style: AppTypography.labelMedium
                    .copyWith(color: Colors.white70),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderRadiusPill,
                ),
                child: Text(
                  inspection.type.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${inspection.checkedItems}/${inspection.totalItems} items',
                  style: AppTypography.bodyMedium
                      .copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: AppRadius.borderRadiusPill,
            child: LinearProgressIndicator(
              value: inspection.overallProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem(
                icon: Icons.meeting_room_outlined,
                value: '${inspection.completedRooms}/${inspection.totalRooms}',
                label: 'Rooms',
              ),
              const SizedBox(width: 20),
              _StatItem(
                icon: Icons.warning_amber_rounded,
                value: '${inspection.totalIssues}',
                label: 'Issues',
              ),
              const SizedBox(width: 20),
              _StatItem(
                icon: Icons.photo_camera_outlined,
                value: '${inspection.totalPhotos}',
                label: 'Photos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}
