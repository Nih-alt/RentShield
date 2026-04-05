import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_card.dart';
import '../../property/providers/property_providers.dart';
import '../../tenancy/providers/tenancy_providers.dart';
import '../../inspection/providers/inspection_providers.dart';
import '../../inspection/data/inspection_model.dart';
import '../../property/data/property_model.dart';
import '../../report/providers/report_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertyListProvider);
    final allInspections = ref.watch(inspectionListProvider);
    final allReports = ref.watch(reportListProvider);
    final draftCount = allInspections
        .where((i) => i.status == InspectionStatus.draft)
        .length;
    final completedCount = allInspections
        .where((i) => i.status == InspectionStatus.completed)
        .length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium app bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rent Shield',
                    style: AppTypography.h1.copyWith(fontSize: 20),
                  ),
                  Text(
                    'Protect your deposit',
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          // Content
          if (properties.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.home_work_outlined,
                title: 'No properties yet',
                subtitle:
                    'Add your first rental property to start documenting its condition and protecting your deposit.',
                actionLabel: 'Add Property',
                onAction: () => context.push('/properties/create'),
              ),
            )
          else
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats row
                  _StatsRow(
                    propertyCount: properties.length,
                    draftInspections: draftCount,
                    completedInspections: completedCount,
                    reportCount: allReports.length,
                  ),
                  AppSpacing.vXxl,

                  // Properties section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Properties', style: AppTypography.h2),
                      TextButton.icon(
                        onPressed: () => context.push('/properties/create'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  AppSpacing.vMd,

                  // Property cards
                  ...properties.map((property) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PropertyCard(property: property),
                      )),

                  AppSpacing.vXxxl,
                ]),
              ),
            ),
        ],
      ),

      // FAB for quick add
      floatingActionButton: properties.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/properties/create'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int propertyCount;
  final int draftInspections;
  final int completedInspections;
  final int reportCount;

  const _StatsRow({
    required this.propertyCount,
    required this.draftInspections,
    required this.completedInspections,
    required this.reportCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderRadiusXl,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$propertyCount ${propertyCount == 1 ? 'Property' : 'Properties'}',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          if (draftInspections > 0 ||
              completedInspections > 0 ||
              reportCount > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (completedInspections > 0)
                  _MiniStatChip(
                    icon: Icons.check_circle_outline,
                    label:
                        '$completedInspections completed',
                  ),
                if (draftInspections > 0)
                  _MiniStatChip(
                    icon: Icons.edit_note_rounded,
                    label:
                        '$draftInspections draft${draftInspections > 1 ? 's' : ''}',
                  ),
                if (reportCount > 0)
                  _MiniStatChip(
                    icon: Icons.picture_as_pdf_rounded,
                    label:
                        '$reportCount report${reportCount > 1 ? 's' : ''}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  final Property property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancy = ref.watch(tenancyByPropertyIdProvider(property.id));
    final inspections =
        ref.watch(inspectionsByPropertyIdProvider(property.id));
    final hasDraft = inspections
        .any((i) => i.status == InspectionStatus.draft);
    final hasCompletedMoveIn = inspections.any((i) =>
        i.status == InspectionStatus.completed &&
        i.type == InspectionType.moveIn);
    final hasCompletedMoveOut = inspections.any((i) =>
        i.status == InspectionStatus.completed &&
        i.type == InspectionType.moveOut);
    final hasNoInspections = inspections.isEmpty;

    return AppCard(
      onTap: () => context.push('/properties/${property.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Property type badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(property.propertyType)
                      .withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Center(
                  child: Text(
                    property.propertyType.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: AppTypography.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.shortAddress,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),

          // Status badges
          if (tenancy != null ||
              hasDraft ||
              hasCompletedMoveIn ||
              hasCompletedMoveOut ||
              hasNoInspections) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (hasNoInspections && tenancy == null)
                  _StatusChip(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Start inspection',
                    color: AppColors.textTertiary,
                  ),
                if (tenancy != null)
                  _StatusChip(
                    icon: Icons.check_circle_outline,
                    label: 'Tenancy active',
                    color: AppColors.success,
                  ),
                if (hasCompletedMoveIn)
                  _StatusChip(
                    icon: Icons.verified_outlined,
                    label: 'Move-in done',
                    color: AppColors.info,
                  ),
                if (hasCompletedMoveOut)
                  _StatusChip(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Move-out done',
                    color: AppColors.success,
                  ),
                if (hasDraft)
                  _StatusChip(
                    icon: Icons.edit_note_rounded,
                    label: 'Draft inspection',
                    color: AppColors.warning,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(PropertyType type) {
    switch (type) {
      case PropertyType.flat:
        return AppColors.flat;
      case PropertyType.apartment:
        return AppColors.apartment;
      case PropertyType.house:
        return AppColors.house;
      case PropertyType.room:
        return AppColors.room;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
