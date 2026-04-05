import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/inspection_providers.dart';
import '../data/comparison_model.dart';
import '../widgets/condition_selector.dart';

class ComparisonScreen extends ConsumerWidget {
  final String moveOutInspectionId;

  const ComparisonScreen({super.key, required this.moveOutInspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(comparisonProvider(moveOutInspectionId));

    if (comparison == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comparison')),
        body: const Center(child: Text('Comparison data not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Before & After'),
      ),
      body: ListView(
        padding: AppSpacing.screenPaddingAll,
        children: [
          // Summary header
          _ComparisonSummaryCard(comparison: comparison),
          AppSpacing.vXxl,

          // Stats grid
          _StatsGrid(comparison: comparison),
          AppSpacing.vXxl,

          // Flagged issues section
          if (comparison.worsenedItems > 0) ...[
            _FlaggedIssuesSection(comparison: comparison),
            AppSpacing.vXxl,
          ],

          // Room-by-room comparison
          const SectionHeader(
            title: 'Room Breakdown',
            subtitle: 'Tap a room to see item details',
          ),
          AppSpacing.vMd,

          ...comparison.rooms.map((room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoomComparisonCard(room: room),
              )),

          AppSpacing.vXxl,

          // Generate comparison report CTA
          ElevatedButton.icon(
            onPressed: () => context.push(
                '/inspections/$moveOutInspectionId/report/comparison'),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Generate Comparison Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textOnAccent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
          ),

          AppSpacing.vXxxl,
        ],
      ),
    );
  }
}

class _ComparisonSummaryCard extends StatelessWidget {
  final InspectionComparison comparison;

  const _ComparisonSummaryCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final hasIssues = comparison.worsenedItems > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasIssues
              ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
              : [AppColors.success, const Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasIssues
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasIssues
                      ? '${comparison.worsenedItems} item${comparison.worsenedItems > 1 ? 's' : ''} worsened'
                      : 'No condition worsened',
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Move-in',
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(comparison.moveIn.startedAt),
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      size: 14, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Move-out',
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white60)),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(comparison.moveOut.startedAt),
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final InspectionComparison comparison;

  const _StatsGrid({required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            count: comparison.unchangedItems,
            label: 'Unchanged',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
        ),
        AppSpacing.hSm,
        Expanded(
          child: _StatBox(
            count: comparison.worsenedItems,
            label: 'Worsened',
            color: AppColors.error,
            icon: Icons.trending_down_rounded,
          ),
        ),
        AppSpacing.hSm,
        Expanded(
          child: _StatBox(
            count: comparison.improvedItems,
            label: 'Improved',
            color: AppColors.info,
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text('$count', style: AppTypography.h2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FlaggedIssuesSection extends StatelessWidget {
  final InspectionComparison comparison;

  const _FlaggedIssuesSection({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final issues = <({String roomName, ItemComparison item})>[];
    for (final room in comparison.rooms) {
      for (final item in room.items) {
        if (item.isWorsened) {
          issues.add((roomName: room.name, item: item));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Flagged Issues',
          subtitle: 'Items that got worse during tenancy',
        ),
        AppSpacing.vMd,
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.04),
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: issues.asMap().entries.map((entry) {
              final i = entry.key;
              final issue = entry.value;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${issue.roomName} \u2022 ${issue.item.name}',
                              style: AppTypography.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ConditionBadge(
                                    condition: issue.item.moveInCondition),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward,
                                      size: 12,
                                      color: AppColors.textTertiary),
                                ),
                                ConditionBadge(
                                    condition: issue.item.moveOutCondition),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _ChangeBadge(changeType: issue.item.changeType),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RoomComparisonCard extends StatefulWidget {
  final RoomComparison room;

  const _RoomComparisonCard({required this.room});

  @override
  State<_RoomComparisonCard> createState() => _RoomComparisonCardState();
}

class _RoomComparisonCardState extends State<_RoomComparisonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final hasChanges = room.hasChanges;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header (always visible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasChanges
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Center(
                      child: Text(room.icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.name, style: AppTypography.labelLarge),
                        const SizedBox(height: 2),
                        if (hasChanges)
                          Text(
                            '${room.changedItems} changed \u2022 ${room.worsenedItems} worsened',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.warning),
                          )
                        else
                          Text(
                            'No changes',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.success),
                          ),
                      ],
                    ),
                  ),
                  // Photo diff
                  if (room.moveInPhotos > 0 || room.moveOutPhotos > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_outlined,
                              size: 13, color: AppColors.info),
                          const SizedBox(width: 3),
                          Text(
                            '${room.moveInPhotos}/${room.moveOutPhotos}',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Expanded item list
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: room.items.map((item) {
                  return _BeforeAfterItemRow(item: item);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BeforeAfterItemRow extends StatelessWidget {
  final ItemComparison item;

  const _BeforeAfterItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasChanged = item.hasChanged;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: hasChanged
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (hasChanged) _ChangeBadge(changeType: item.changeType),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Move-in condition
              Expanded(
                child: Row(
                  children: [
                    Text('In: ',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textTertiary)),
                    ConditionBadge(condition: item.moveInCondition),
                  ],
                ),
              ),
              // Arrow
              if (hasChanged)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward,
                      size: 12, color: AppColors.textTertiary),
                ),
              // Move-out condition
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Out: ',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textTertiary)),
                    ConditionBadge(condition: item.moveOutCondition),
                  ],
                ),
              ),
            ],
          ),
          // Notes/photos indicators
          if (item.moveInHasNotes ||
              item.moveOutHasNotes ||
              item.moveInPhotos > 0 ||
              item.moveOutPhotos > 0) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                if (item.moveInPhotos > 0 || item.moveOutPhotos > 0)
                  Text(
                    'Photos: ${item.moveInPhotos} in / ${item.moveOutPhotos} out',
                    style: AppTypography.caption,
                  ),
                if (item.moveInHasNotes || item.moveOutHasNotes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text('Notes attached', style: AppTypography.caption),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final ChangeType changeType;

  const _ChangeBadge({required this.changeType});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (changeType) {
      case ChangeType.unchanged:
        return const SizedBox.shrink();
      case ChangeType.worsened:
      case ChangeType.newIssue:
        color = AppColors.error;
        icon = Icons.trending_down_rounded;
      case ChangeType.improved:
      case ChangeType.resolved:
        color = AppColors.info;
        icon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            changeType.label,
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
