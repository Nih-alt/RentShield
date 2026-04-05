import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/report_providers.dart';
import '../data/report_model.dart';

class ReportHistorySection extends ConsumerWidget {
  final String propertyId;

  const ReportHistorySection({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsByPropertyIdProvider(propertyId));

    if (reports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Generated Reports',
        ),
        AppSpacing.vMd,
        ...reports.map((report) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReportTile(report: report),
            )),
      ],
    );
  }
}

class _ReportTile extends ConsumerWidget {
  final ReportRecord report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');
    final fileSize = _formatFileSize(report.fileSizeBytes);
    final fileExists = File(report.filePath).existsSync();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor(report.reportType).withValues(alpha: 0.1),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: _typeColor(report.reportType),
              size: 20,
            ),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reportType.label,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${dateFormat.format(report.createdAt)} \u2022 $fileSize',
                  style: AppTypography.bodySmall,
                ),
                if (!fileExists) ...[
                  const SizedBox(height: 2),
                  Text(
                    'File no longer available',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
          if (fileExists)
            IconButton(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_rounded, size: 18),
              color: AppColors.primary,
              tooltip: 'Share',
              constraints: const BoxConstraints(
                  minWidth: 36, minHeight: 36),
            ),
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.textTertiary,
            tooltip: 'Delete',
            constraints: const BoxConstraints(
                minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final file = XFile(report.filePath);
      await Share.shareXFiles(
        [file],
        subject: report.reportType.label,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('This will delete this generated report.'),
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

    if (confirm == true) {
      await ref.read(reportListProvider.notifier).delete(report.id);
    }
  }

  Color _typeColor(ReportType type) {
    switch (type) {
      case ReportType.moveIn:
        return AppColors.success;
      case ReportType.moveOut:
        return AppColors.info;
      case ReportType.comparison:
        return AppColors.accent;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
