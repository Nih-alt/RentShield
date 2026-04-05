import 'package:go_router/go_router.dart';
import '../database/hive_service.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/property/screens/create_property_screen.dart';
import '../../features/property/screens/property_details_screen.dart';
import '../../features/tenancy/screens/tenancy_form_screen.dart';
import '../../features/inspection/screens/inspection_overview_screen.dart';
import '../../features/inspection/screens/room_inspection_screen.dart';
import '../../features/inspection/screens/inspection_summary_screen.dart';
import '../../features/inspection/screens/comparison_screen.dart';
import '../../features/report/screens/report_generation_screen.dart';
import '../../features/report/data/report_model.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: HiveService.hasCompletedOnboarding ? '/' : '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/properties/create',
      builder: (context, state) => const CreatePropertyScreen(),
    ),
    GoRoute(
      path: '/properties/:id',
      builder: (context, state) => PropertyDetailsScreen(
        propertyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/properties/:id/edit',
      builder: (context, state) => CreatePropertyScreen(
        editPropertyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/properties/:id/tenancy',
      builder: (context, state) => TenancyFormScreen(
        propertyId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/inspections/:id',
      builder: (context, state) => InspectionOverviewScreen(
        inspectionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/inspections/:id/rooms/:roomId',
      builder: (context, state) => RoomInspectionScreen(
        inspectionId: state.pathParameters['id']!,
        roomId: state.pathParameters['roomId']!,
      ),
    ),
    GoRoute(
      path: '/inspections/:id/summary',
      builder: (context, state) => InspectionSummaryScreen(
        inspectionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/inspections/:id/compare',
      builder: (context, state) => ComparisonScreen(
        moveOutInspectionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/inspections/:id/report/:type',
      builder: (context, state) => ReportGenerationScreen(
        inspectionId: state.pathParameters['id']!,
        reportType: ReportType.values.byName(state.pathParameters['type']!),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
