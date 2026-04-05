import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/hive_service.dart';

class BackupService {
  /// Exports all app data as a structured JSON file.
  ///
  /// Includes: properties, tenancies, inspections, report metadata.
  /// Does NOT include: actual PDF files or photos (they are local file paths).
  static Future<String> exportBackup() async {
    final now = DateTime.now();
    final stats = getStorageStats();

    final backup = <String, dynamic>{
      'appName': 'Rent Shield',
      'version': '1.0.0',
      'exportedAt': now.toIso8601String(),
      'dataStats': stats,
      'note':
          'This backup contains property, tenancy, inspection, and report metadata. '
          'Photos and PDF report files are not included in this backup. '
          'To preserve photos, back up your device storage separately.',
      'properties': _boxToList(HiveService.properties),
      'tenancies': _boxToList(HiveService.tenancies),
      'inspections': _boxToList(HiveService.inspections),
      'reports': _boxToList(HiveService.reports),
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = now
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filePath = '${dir.path}/rent_shield_backup_$timestamp.json';
    final file = File(filePath);
    await file.writeAsString(json);

    return filePath;
  }

  /// Shares the backup file via platform share sheet.
  static Future<void> shareBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }
    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      subject: 'Rent Shield Backup',
    );
  }

  static List<Map<String, dynamic>> _boxToList(dynamic box) {
    final list = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(Map<String, dynamic>.from(value));
      }
    }
    return list;
  }

  /// Returns storage stats: number of records per box.
  static Map<String, int> getStorageStats() {
    return {
      'properties': HiveService.properties.length,
      'tenancies': HiveService.tenancies.length,
      'inspections': HiveService.inspections.length,
      'reports': HiveService.reports.length,
    };
  }

  /// Cleans up orphaned report records whose PDF files no longer exist on disk.
  /// Returns the number of orphaned records found (does not delete them).
  static Future<int> countOrphanedReports() async {
    int orphaned = 0;
    final box = HiveService.reports;
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final filePath = value['filePath'] as String?;
        if (filePath != null) {
          final exists = await File(filePath).exists();
          if (!exists) orphaned++;
        }
      }
    }
    return orphaned;
  }
}
