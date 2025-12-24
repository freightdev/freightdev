import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'utils/theme.dart';
import 'services/local_storage_service.dart';
import 'services/database_service.dart';
import 'providers/auth_provider.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Onboarding screens
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/company_setup_screen.dart';

// Dashboard screens
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/loads/loads_screen.dart';
import 'screens/loads/load_detail_screen.dart';
import 'screens/drivers/drivers_screen.dart';
import 'screens/drivers/driver_detail_screen.dart';
import 'screens/tracking/tracking_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/invoicing/invoicing_screen.dart';
import 'screens/invoicing/invoice_detail_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/eld/eld_screen.dart';
import 'screens/training/training_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/settings/company_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage (Hive)
  await LocalStorageService.initialize();

  // Initialize embedded SurrealDB
  try {
    await DatabaseService.initialize();
  } catch (e) {
    print('Warning: Failed to initialize SurrealDB: $e');
    // Continue without database - will use Hive fallback
  }

  runApp(
    const ProviderScope(
      child: FedTmsApp(),
    ),
  );
}

class FedTmsApp extends ConsumerWidget {
  const FedTmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: 'HWY-TMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final isOnboardingComplete = await LocalStorageService.isOnboardingComplete();
        final authState = ref.read(authNotifierProvider);
        final isAuthenticated = authState.value != null;

        final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // If not onboarded, redirect to onboarding
        if (!isOnboardingComplete && !isOnboardingRoute) {
          return '/onboarding';
        }

        // If onboarded but not authenticated and not on auth route
        if (isOnboardingComplete && !isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
          return '/login';
        }

        // If authenticated and on auth route, go to dashboard
        if (isAuthenticated && isAuthRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        // Onboarding Routes
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/onboarding/company-setup',
          builder: (context, state) => const CompanySetupScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Dashboard Routes
        GoRoute(
          path: '/',
          redirect: (context, state) => '/dashboard',
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // Loads Routes
        GoRoute(
          path: '/loads',
          builder: (context, state) => const LoadsScreen(),
        ),
        GoRoute(
          path: '/loads/:id',
          builder: (context, state) {
            final loadId = state.pathParameters['id']!;
            return LoadDetailScreen(loadId: loadId);
          },
        ),

        // Drivers Routes
        GoRoute(
          path: '/drivers',
          builder: (context, state) => const DriversScreen(),
        ),
        GoRoute(
          path: '/drivers/:id',
          builder: (context, state) {
            final driverId = state.pathParameters['id']!;
            return DriverDetailScreen(driverId: driverId);
          },
        ),

        // Tracking Route
        GoRoute(
          path: '/tracking',
          builder: (context, state) => const TrackingScreen(),
        ),

        // Messages Route
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),

        // Documents Route
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentsScreen(),
        ),

        // Invoicing Routes
        GoRoute(
          path: '/invoicing',
          builder: (context, state) => const InvoicingScreen(),
        ),
        GoRoute(
          path: '/invoicing/:id',
          builder: (context, state) {
            final invoiceId = state.pathParameters['id']!;
            return InvoiceDetailScreen(invoiceId: invoiceId);
          },
        ),

        // Calendar Route
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),

        // ELD Route
        GoRoute(
          path: '/eld',
          builder: (context, state) => const EldScreen(),
        ),

        // Training Route
        GoRoute(
          path: '/training',
          builder: (context, state) => const TrainingScreen(),
        ),

        // Reports Route
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // Settings Routes
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings/company',
          builder: (context, state) => const CompanySettingsScreen(),
        ),
      ],
    );
  }
}
