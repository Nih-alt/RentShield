import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../data/inspection_model.dart';
import 'condition_selector.dart';

class RoomProgressCard extends StatelessWidget {
  final InspectionRoom room;
  final VoidCallback onTap;

  const RoomProgressCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = room.isComplete;
    final hasIssues = room.hasIssues;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: isComplete
                ? (hasIssues
                    ? AppColors.warning.withValues(alpha: 0.4)
                    : AppColors.success.withValues(alpha: 0.4))
                : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Room icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? (hasIssues
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1))
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: Center(
                    child: Text(room.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: AppTypography.h3),
                      const SizedBox(height: 2),
                      Text(
                        '${room.checkedItems} of ${room.totalItems} items checked',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Status indicator
                if (isComplete)
                  Icon(
                    hasIssues
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color: hasIssues ? AppColors.warning : AppColors.success,
                    size: 22,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
              ],
            ),

            // Progress bar
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.borderRadiusPill,
              child: LinearProgressIndicator(
                value: room.progress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isComplete
                      ? (hasIssues ? AppColors.warning : AppColors.success)
                      : AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),

            // Issue summary chips
            if (room.checkedItems > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (room.okCount > 0)
                    _MiniChip(
                      label: '${room.okCount} OK',
                      color: AppColors.success,
                    ),
                  if (room.minorCount > 0)
                    _MiniChip(
                      label: '${room.minorCount} Minor',
                      color: AppColors.warning,
                    ),
                  if (room.majorCount > 0)
                    _MiniChip(
                      label: '${room.majorCount} Major',
                      color: AppColors.error,
                    ),
                  if (room.missingCount > 0)
                    _MiniChip(
                      label: '${room.missingCount} Missing',
                      color: conditionColor(ItemCondition.missing),
                    ),
                  if (room.photos.isNotEmpty ||
                      room.items.any((i) => i.photos.isNotEmpty))
                    _MiniChip(
                      label:
                          '${room.photos.length + room.items.fold(0, (s, i) => s + i.photos.length)} photos',
                      color: AppColors.info,
                      icon: Icons.photo_camera_outlined,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _MiniChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
