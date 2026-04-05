import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/database/hive_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../shared/widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppSpacing.screenPaddingAll,
        children: [
          // App info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.borderRadiusXl,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                AppSpacing.hLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent Shield',
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version 1.0.0 (Beta)',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vXxl,

          // Data & Backup section
          _SectionLabel(label: 'Data & Backup'),
          AppSpacing.vMd,

          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Export Backup',
            subtitle: 'Save all data as a JSON file',
            onTap: () => _exportBackup(context),
          ),
          AppSpacing.vSm,
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'View data counts and storage info',
            onTap: () => _showStorageInfo(context),
          ),
          AppSpacing.vXxl,

          // Help & Info section
          _SectionLabel(label: 'Help & Info'),
          AppSpacing.vMd,

          _SettingsTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Replay Walkthrough',
            subtitle: 'View the app introduction again',
            onTap: () => _replayOnboarding(context),
          ),
          AppSpacing.vSm,
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'How It Works',
            subtitle: 'Learn how Rent Shield protects you',
            onTap: () => _showHowItWorks(context),
          ),
          AppSpacing.vXxl,

          // About section
          _SectionLabel(label: 'About'),
          AppSpacing.vMd,

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Rent Shield',
            subtitle: 'Protect your rental deposit',
            onTap: () => _showAbout(context),
          ),
          AppSpacing.vSm,
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'All data is stored locally on your device',
            onTap: () => _showPrivacy(context),
          ),

          AppSpacing.vXxxl,

          // Footer
          Center(
            child: Text(
              'Made with care for tenants everywhere.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ),
          AppSpacing.vSm,
          Center(
            child: Text(
              'Rent Shield v1.0.0',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
            ),
          ),
          AppSpacing.vXxl,
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing backup...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      final filePath = await BackupService.exportBackup();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      await BackupService.shareBackup(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showStorageInfo(BuildContext context) {
    final stats = BackupService.getStorageStats();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.storage_outlined,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Storage Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StorageRow(
                label: 'Properties',
                count: stats['properties'] ?? 0,
                icon: Icons.home_work_outlined),
            _StorageRow(
                label: 'Tenancies',
                count: stats['tenancies'] ?? 0,
                icon: Icons.description_outlined),
            _StorageRow(
                label: 'Inspections',
                count: stats['inspections'] ?? 0,
                icon: Icons.camera_alt_outlined),
            _StorageRow(
                label: 'Reports',
                count: stats['reports'] ?? 0,
                icon: Icons.picture_as_pdf_rounded),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All data is stored locally on this device using encrypted local storage. Photos are saved in the app directory.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _replayOnboarding(BuildContext context) async {
    await HiveService.resetOnboarding();
    if (context.mounted) {
      context.go('/onboarding');
    }
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('How Rent Shield Works', style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                'Four simple steps to protect your deposit.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),
              _HowStep(
                number: '1',
                title: 'Add Your Property',
                desc: 'Enter property details, address, and tenancy information like rent and deposit amounts.',
                color: AppColors.primary,
              ),
              _HowStep(
                number: '2',
                title: 'Move-in Inspection',
                desc: 'Document every room with photos, notes, and condition ratings for each item.',
                color: AppColors.success,
              ),
              _HowStep(
                number: '3',
                title: 'Move-out Inspection',
                desc: 'Repeat the inspection when moving out. Rent Shield links it to your original move-in record.',
                color: AppColors.info,
              ),
              _HowStep(
                number: '4',
                title: 'Compare & Report',
                desc: 'View a side-by-side comparison and generate a professional PDF report to share as evidence.',
                color: AppColors.accent,
                isLast: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                  ),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Rent Shield'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0 (Beta)', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            Text(
              'Rent Shield helps tenants protect their security deposit by documenting '
              'property condition during move-in and move-out with photos, notes, '
              'and professional PDF reports.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All your data stays on your device. No account needed. No cloud sync required.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Privacy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rent Shield stores all data locally on your device. '
              'No data is sent to any server or cloud service.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            _PrivacyItem(
              icon: Icons.phone_android_rounded,
              text: 'All data stored locally on your device',
            ),
            _PrivacyItem(
              icon: Icons.cloud_off_rounded,
              text: 'No cloud uploads or remote connections',
            ),
            _PrivacyItem(
              icon: Icons.photo_library_outlined,
              text: 'Photos saved in app-private storage',
            ),
            _PrivacyItem(
              icon: Icons.share_outlined,
              text: 'Exports shared only when you choose to',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _StorageRow({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.borderRadiusPill,
            ),
            child: Text(
              '$count',
              style: AppTypography.labelLarge.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final Color color;
  final bool isLast;

  const _HowStep({
    required this.number,
    required this.title,
    required this.desc,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 3),
                Text(desc, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
