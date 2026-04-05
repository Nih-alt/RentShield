import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/report_providers.dart';
import '../data/report_model.dart';

class ReportGenerationScreen extends ConsumerStatefulWidget {
  final String inspectionId;
  final ReportType reportType;

  const ReportGenerationScreen({
    super.key,
    required this.inspectionId,
    required this.reportType,
  });

  @override
  ConsumerState<ReportGenerationScreen> createState() =>
      _ReportGenerationScreenState();
}

class _ReportGenerationScreenState
    extends ConsumerState<ReportGenerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });
  }

  void _startGeneration() {
    final notifier = ref.read(reportGenerationProvider.notifier);
    if (widget.reportType == ReportType.comparison) {
      notifier.generateComparisonReport(widget.inspectionId);
    } else {
      notifier.generateSingleReport(widget.inspectionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportGenerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType.label),
      ),
      body: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: switch (state.status) {
          ReportGenerationStatus.idle ||
          ReportGenerationStatus.generating =>
            _GeneratingState(reportType: widget.reportType),
          ReportGenerationStatus.success =>
            _SuccessState(
              report: state.report!,
              filePath: state.filePath!,
              onRegenerate: _startGeneration,
            ),
          ReportGenerationStatus.error =>
            _ErrorState(
              message: state.errorMessage ?? 'Unknown error',
              onRetry: _startGeneration,
            ),
        },
      ),
    );
  }
}

class _GeneratingState extends StatelessWidget {
  final ReportType reportType;

  const _GeneratingState({required this.reportType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          ),
          AppSpacing.vXxl,
          Text('Generating Report', style: AppTypography.h2),
          AppSpacing.vSm,
          Text(
            'Building your ${reportType.shortLabel.toLowerCase()} report...',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vLg,
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusPill,
              child: const LinearProgressIndicator(
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatefulWidget {
  final ReportRecord report;
  final String filePath;
  final VoidCallback onRegenerate;

  const _SuccessState({
    required this.report,
    required this.filePath,
    required this.onRegenerate,
  });

  @override
  State<_SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<_SuccessState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');
    final fileSize = _formatFileSize(widget.report.fileSizeBytes);

    return Column(
      children: [
        const Spacer(),

        // Success icon with animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),
        AppSpacing.vXxl,
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text('Report Ready', style: AppTypography.h2),
              AppSpacing.vSm,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your ${widget.report.reportType.shortLabel.toLowerCase()} report has been generated successfully.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vXxl,

        // File info card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.error, size: 24),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.fileName,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$fileSize \u2022 ${dateFormat.format(widget.report.createdAt)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Action buttons - primary: Share, secondary: Regenerate
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSharing ? null : () => _shareReport(context),
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, size: 18),
            label: Text(_isSharing ? 'Preparing...' : 'Share Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: widget.onRegenerate,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Regenerate Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
            ),
          ),
        ),
        AppSpacing.vXxl,
      ],
    );
  }

  Future<void> _shareReport(BuildContext context) async {
    // Check file exists before sharing
    final file = File(widget.filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report file not found. Try regenerating the report.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSharing = true);
    try {
      final xFile = XFile(widget.filePath);
      await Share.shareXFiles(
        [xFile],
        subject: widget.report.reportType.label,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share report: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
          ),
          AppSpacing.vXxl,
          Text('Generation Failed', style: AppTypography.h2),
          AppSpacing.vSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message.replaceAll('Exception: ', ''),
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.vXxl,
          SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
