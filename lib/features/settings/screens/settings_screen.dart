import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
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
                Column(
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
              ],
            ),
          ),
          AppSpacing.vXxl,

          // Data & Backup section
          Text('Data & Backup', style: AppTypography.labelMedium),
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

          // General section
          Text('General', style: AppTypography.labelMedium),
          AppSpacing.vMd,

          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'How It Works',
            subtitle: 'Learn how Rent Shield protects you',
            onTap: () => _showHowItWorks(context),
          ),
          AppSpacing.vSm,
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
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
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing backup...')),
      );

      final filePath = await BackupService.exportBackup();
      await BackupService.shareBackup(filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
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
        title: const Text('Storage Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StorageRow(label: 'Properties', count: stats['properties'] ?? 0),
            _StorageRow(label: 'Tenancies', count: stats['tenancies'] ?? 0),
            _StorageRow(
                label: 'Inspections', count: stats['inspections'] ?? 0),
            _StorageRow(label: 'Reports', count: stats['reports'] ?? 0),
            const SizedBox(height: 12),
            Text(
              'All data is stored locally on this device using Hive.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
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

  void _showHowItWorks(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How It Works'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HowStep(
              number: '1',
              title: 'Add Your Property',
              desc: 'Enter property details and tenancy information.',
            ),
            _HowStep(
              number: '2',
              title: 'Move-in Inspection',
              desc:
                  'Document every room — condition, photos, and notes.',
            ),
            _HowStep(
              number: '3',
              title: 'Move-out Inspection',
              desc:
                  'Repeat the process when moving out, linked to your move-in.',
            ),
            _HowStep(
              number: '4',
              title: 'Compare & Report',
              desc:
                  'View before/after comparison and generate PDF reports to share.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_outlined,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Rent Shield'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0 (Beta)', style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            Text(
              'Rent Shield helps tenants protect their security deposit by documenting '
              'property condition during move-in and move-out with photos, notes, '
              'and professional PDF reports.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'All your data stays on your device. No account needed. No cloud sync required.',
              style: AppTypography.bodySmall,
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
        title: const Text('Privacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rent Shield stores all data locally on your device. '
              'No data is sent to any server or cloud service.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Photos are stored in the app\'s local storage directory. '
              'Backup files are shared only when you explicitly choose to export them.',
              style: AppTypography.bodySmall,
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
          Icon(icon, size: 22, color: AppColors.textSecondary),
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

  const _StorageRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.borderRadiusPill,
            ),
            child: Text('$count', style: AppTypography.labelLarge),
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

  const _HowStep({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
