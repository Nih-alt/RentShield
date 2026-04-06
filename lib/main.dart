import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/database/hive_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts from blocking startup with network requests.
  // Fonts are cached after first successful download; on first launch
  // without cache the system font is used as a seamless fallback.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize local database — wrapped in try-catch so the app always
  // starts even if Hive has corrupted data.  Without this, an unhandled
  // exception here causes runApp() to never execute, leaving the user
  // stuck on the native splash screen forever.
  try {
    await HiveService.init();
  } catch (_) {
    // Attempt recovery: wipe boxes and re-initialize.
    try {
      await HiveService.deleteAndReinit();
    } catch (_) {
      // If even recovery fails, launch anyway — screens will show
      // empty state rather than an infinite splash.
    }
  }

  runApp(const ProviderScope(child: RentShieldApp()));
}

class RentShieldApp extends StatelessWidget {
  const RentShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rent Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
