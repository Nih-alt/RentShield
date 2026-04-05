import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String propertiesBox = 'properties';
  static const String tenanciesBox = 'tenancies';
  static const String inspectionsBox = 'inspections';
  static const String reportsBox = 'reports';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(propertiesBox);
    await Hive.openBox<Map>(tenanciesBox);
    await Hive.openBox<Map>(inspectionsBox);
    await Hive.openBox<Map>(reportsBox);
    await Hive.openBox(settingsBox);
  }

  static Box<Map> get properties => Hive.box<Map>(propertiesBox);
  static Box<Map> get tenancies => Hive.box<Map>(tenanciesBox);
  static Box<Map> get inspections => Hive.box<Map>(inspectionsBox);
  static Box<Map> get reports => Hive.box<Map>(reportsBox);
  static Box get settings => Hive.box(settingsBox);

  /// Whether the user has completed onboarding.
  static bool get hasCompletedOnboarding =>
      settings.get('onboardingCompleted', defaultValue: false) as bool;

  static Future<void> setOnboardingCompleted() =>
      settings.put('onboardingCompleted', true);
}
