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
import '../providers/property_providers.dart';
import '../../tenancy/providers/tenancy_providers.dart';
import '../../inspection/providers/inspection_providers.dart';
import '../../inspection/data/inspection_model.dart';
import '../../report/providers/report_providers.dart';
import '../../report/widgets/report_history_section.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyByIdProvider(propertyId));
    final tenancy = ref.watch(tenancyByPropertyIdProvider(propertyId));
    final inspections =
        ref.watch(inspectionsByPropertyIdProvider(propertyId));

    if (property == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Property not found')),
      );
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    );

    // Separate inspections by type
    final moveInInspections = inspections
        .where((i) => i.type == InspectionType.moveIn)
        .toList();
    final moveOutInspections = inspections
        .where((i) => i.type == InspectionType.moveOut)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/properties/$propertyId/edit');
              } else if (value == 'delete') {
                final inspCount = inspections.length;
                final hasReports = ref
                    .read(reportsByPropertyIdProvider(propertyId))
                    .isNotEmpty;
                final details = <String>[];
                if (tenancy != null) details.add('tenancy details');
                if (inspCount > 0) {
                  details.add('$inspCount inspection${inspCount > 1 ? 's' : ''}');
                }
                if (hasReports) details.add('generated reports');
                final detailText = details.isEmpty
                    ? 'This will permanently delete this property.'
                    : 'This will permanently delete this property, including ${details.join(', ')}.';

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Property'),
                    content: Text(detailText),
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
                  // Delete associated data
                  final reports =
                      ref.read(reportsByPropertyIdProvider(propertyId));
                  for (final report in reports) {
                    await ref
                        .read(reportListProvider.notifier)
                        .delete(report.id);
                  }
                  if (tenancy != null) {
                    await ref
                        .read(tenancyListProvider.notifier)
                        .delete(tenancy.id);
                  }
                  for (final insp in inspections) {
                    await ref
                        .read(inspectionListProvider.notifier)
                        .delete(insp.id);
                  }
                  await ref
                      .read(propertyListProvider.notifier)
                      .delete(propertyId);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Property'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Property'),
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
          // Property info card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                      child: Center(
                        child: Text(
                          property.propertyType.icon,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    AppSpacing.hLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(property.name, style: AppTypography.h2),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.borderRadiusSm,
                            ),
                            child: Text(
                              property.propertyType.label,
                              style: AppTypography.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vLg,
                const Divider(),
                AppSpacing.vMd,
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: property.fullAddress,
                ),
                if (property.notes != null &&
                    property.notes!.isNotEmpty) ...[
                  AppSpacing.vMd,
                  _DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: property.notes!,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vXxl,

          // Tenancy section
          SectionHeader(
            title: 'Tenancy Details',
            trailing: TextButton.icon(
              onPressed: () =>
                  context.push('/properties/$propertyId/tenancy'),
              icon: Icon(
                tenancy != null ? Icons.edit_outlined : Icons.add_rounded,
                size: 16,
              ),
              label: Text(tenancy != null ? 'Edit' : 'Add'),
            ),
          ),
          AppSpacing.vMd,

          if (tenancy == null)
            AppCard(
              onTap: () =>
                  context.push('/properties/$propertyId/tenancy'),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Tenancy Details',
                            style: AppTypography.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Rent, deposit, landlord info',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          label: 'Monthly Rent',
                          value:
                              currencyFormat.format(tenancy.monthlyRent),
                          color: AppColors.info,
                        ),
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: _InfoChip(
                          label: 'Security Deposit',
                          value: currencyFormat
                              .format(tenancy.securityDeposit),
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vLg,
                  const Divider(),
                  AppSpacing.vMd,
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Start Date',
                    value: DateFormat('dd MMM yyyy')
                        .format(tenancy.tenancyStartDate),
                  ),
                  if (tenancy.tenancyEndDate != null) ...[
                    AppSpacing.vSm,
                    _DetailRow(
                      icon: Icons.event_outlined,
                      label: 'End Date',
                      value: DateFormat('dd MMM yyyy')
                          .format(tenancy.tenancyEndDate!),
                    ),
                  ],
                  AppSpacing.vMd,
                  const Divider(),
                  AppSpacing.vMd,
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Landlord',
                    value:
                        '${tenancy.landlordName} \u2022 ${tenancy.landlordPhone}',
                  ),
                  if (tenancy.brokerName != null &&
                      tenancy.brokerName!.isNotEmpty) ...[
                    AppSpacing.vSm,
                    _DetailRow(
                      icon: Icons.support_agent_outlined,
                      label: 'Broker',
                      value:
                          '${tenancy.brokerName} \u2022 ${tenancy.brokerPhone ?? ''}',
                    ),
                  ],
                  if (tenancy.notes != null &&
                      tenancy.notes!.isNotEmpty) ...[
                    AppSpacing.vMd,
                    _DetailRow(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: tenancy.notes!,
                    ),
                  ],
                ],
              ),
            ),

          AppSpacing.vXxl,

          // Inspections section
          _InspectionsSection(
            propertyId: propertyId,
            moveInInspections: moveInInspections,
            moveOutInspections: moveOutInspections,
          ),
          AppSpacing.vXxl,

          // Reports section
          ReportHistorySection(propertyId: propertyId),

          AppSpacing.vXxxl,
        ],
      ),
    );
  }
}

class _InspectionsSection extends ConsumerWidget {
  final String propertyId;
  final List<Inspection> moveInInspections;
  final List<Inspection> moveOutInspections;

  const _InspectionsSection({
    required this.propertyId,
    required this.moveInInspections,
    required this.moveOutInspections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAnyInspection =
        moveInInspections.isNotEmpty || moveOutInspections.isNotEmpty;
    final completedMoveIns = moveInInspections
        .where((i) => i.status == InspectionStatus.completed)
        .toList();
    final canStartMoveOut = completedMoveIns.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Inspections',
        ),
        AppSpacing.vMd,

        if (!hasAnyInspection)
          // Empty state CTA
          AppCard(
            onTap: () => _startMoveIn(context, ref),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Move-in Inspection',
                          style: AppTypography.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Document property condition room by room',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          )
        else ...[
          // Move-in inspections group
          if (moveInInspections.isNotEmpty) ...[
            _GroupLabel(
              label: 'Move-in',
              trailing: moveInInspections.isEmpty
                  ? TextButton.icon(
                      onPressed: () => _startMoveIn(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('New'),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            ...moveInInspections.map((inspection) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InspectionCard(inspection: inspection),
                )),
          ],

          // Move-out inspections group
          if (moveOutInspections.isNotEmpty) ...[
            AppSpacing.vMd,
            const _GroupLabel(label: 'Move-out'),
            const SizedBox(height: 8),
            ...moveOutInspections.map((inspection) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InspectionCard(
                    inspection: inspection,
                    showCompare: inspection.status == InspectionStatus.completed,
                  ),
                )),
          ],

          // Start move-out CTA
          if (canStartMoveOut && moveOutInspections.isEmpty) ...[
            AppSpacing.vMd,
            AppCard(
              onTap: () => _startMoveOut(context, ref, completedMoveIns),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: const Icon(Icons.compare_arrows_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Move-out Inspection',
                            style: AppTypography.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Compare against move-in condition',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _startMoveIn(BuildContext context, WidgetRef ref) async {
    final inspection = await ref
        .read(inspectionListProvider.notifier)
        .createMoveIn(propertyId);
    if (context.mounted) {
      context.push('/inspections/${inspection.id}');
    }
  }

  Future<void> _startMoveOut(
      BuildContext context, WidgetRef ref, List<Inspection> completedMoveIns) async {
    // If only one completed move-in, use it directly
    if (completedMoveIns.length == 1) {
      final inspection = await ref
          .read(inspectionListProvider.notifier)
          .createMoveOut(propertyId, completedMoveIns.first.id);
      if (context.mounted) {
        context.push('/inspections/${inspection.id}');
      }
      return;
    }

    // Multiple completed move-ins - let user choose
    if (!context.mounted) return;
    final dateFormat = DateFormat('dd MMM yyyy');
    final selected = await showModalBottomSheet<Inspection>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Move-in to Compare Against',
                  style: AppTypography.h3),
              const SizedBox(height: 4),
              Text('Choose which move-in inspection this move-out should link to.',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              ...completedMoveIns.map((mi) => ListTile(
                    leading: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success),
                    title: Text(
                        'Move-in \u2022 ${dateFormat.format(mi.startedAt)}'),
                    subtitle: Text(
                        '${mi.totalRooms} rooms \u2022 ${mi.totalItems} items'),
                    onTap: () => Navigator.pop(ctx, mi),
                  )),
            ],
          ),
        ),
      ),
    );

    if (selected != null && context.mounted) {
      final inspection = await ref
          .read(inspectionListProvider.notifier)
          .createMoveOut(propertyId, selected.id);
      if (context.mounted) {
        context.push('/inspections/${inspection.id}');
      }
    }
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _GroupLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final Inspection inspection;
  final bool showCompare;

  const _InspectionCard({
    required this.inspection,
    this.showCompare = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = inspection.status == InspectionStatus.draft;
    final dateFormat = DateFormat('dd MMM yyyy');
    final percentage = (inspection.overallProgress * 100).round();

    return AppCard(
      onTap: () => context.push('/inspections/${inspection.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDraft
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(
                  isDraft
                      ? Icons.edit_note_rounded
                      : Icons.check_circle_rounded,
                  color: isDraft ? AppColors.primary : AppColors.success,
                  size: 22,
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inspection.type.label} Inspection',
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDraft
                          ? 'Draft \u2022 $percentage% complete'
                          : 'Completed ${dateFormat.format(inspection.completedAt!)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),

          // Progress bar for drafts
          if (isDraft) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: AppRadius.borderRadiusPill,
              child: LinearProgressIndicator(
                value: inspection.overallProgress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],

          // Summary chips
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MiniStat(
                icon: Icons.meeting_room_outlined,
                label:
                    '${inspection.completedRooms}/${inspection.totalRooms} rooms',
              ),
              if (inspection.totalIssues > 0)
                _MiniStat(
                  icon: Icons.warning_amber_rounded,
                  label: '${inspection.totalIssues} issues',
                  color: AppColors.warning,
                ),
              if (inspection.totalPhotos > 0)
                _MiniStat(
                  icon: Icons.photo_camera_outlined,
                  label: '${inspection.totalPhotos} photos',
                  color: AppColors.info,
                ),
            ],
          ),

          // Compare button for completed move-out inspections
          if (showCompare) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/inspections/${inspection.id}/compare'),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: const Text('View Comparison'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: BorderSide(
                      color: AppColors.info.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: c),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        AppSpacing.hSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              const SizedBox(height: 1),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
