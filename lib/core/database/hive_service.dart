import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String propertiesBox = 'properties';
  static const String tenanciesBox = 'tenancies';
  static const String inspectionsBox = 'inspections';
  static const String reportsBox = 'reports';
  static const String settingsBox = 'settings';

  static bool _initialized = false;

  static Future<void> init() async {
    await Hive.initFlutter();
    await _openBoxSafe<Map>(propertiesBox);
    await _openBoxSafe<Map>(tenanciesBox);
    await _openBoxSafe<Map>(inspectionsBox);
    await _openBoxSafe<Map>(reportsBox);
    await _openBoxSafe(settingsBox);
    _initialized = true;
  }

  /// Opens a Hive box, and if it fails (corrupted data), deletes and retries.
  static Future<Box<T>> _openBoxSafe<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  /// Emergency recovery: close everything, delete all boxes, re-init.
  static Future<void> deleteAndReinit() async {
    await Hive.close();
    await Hive.initFlutter();
    for (final name in [
      propertiesBox,
      tenanciesBox,
      inspectionsBox,
      reportsBox,
      settingsBox,
    ]) {
      await Hive.deleteBoxFromDisk(name);
    }
    await init();
  }

  static Box<Map> get properties => Hive.box<Map>(propertiesBox);
  static Box<Map> get tenancies => Hive.box<Map>(tenanciesBox);
  static Box<Map> get inspections => Hive.box<Map>(inspectionsBox);
  static Box<Map> get reports => Hive.box<Map>(reportsBox);
  static Box get settings => Hive.box(settingsBox);

  /// Whether the user has completed onboarding.
  static bool get hasCompletedOnboarding {
    if (!_initialized) return false;
    try {
      return settings.get('onboardingCompleted', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setOnboardingCompleted() =>
      settings.put('onboardingCompleted', true);

  /// Reset onboarding flag so user can replay the walkthrough.
  static Future<void> resetOnboarding() =>
      settings.put('onboardingCompleted', false);
}
