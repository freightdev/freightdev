import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: StorageService.isAuthenticated ? '/dashboard' : '/login',
    debugLogDiagnostics: true,
    routes: [
      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'load-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LoadDetailsScreen(loadId: id);
            },
          ),
        ],
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Loads
      GoRoute(
        path: '/loads',
        name: 'loads',
        builder: (context, state) => const LoadsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'load-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LoadDetailsScreen(loadId: id);
            },
          ),
        ],
      ),

      // Drivers
      GoRoute(
        path: '/drivers',
        name: 'drivers',
        builder: (context, state) => const DriversScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'driver-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DriverDetailsScreen(driverId: id);
            },
          ),
        ],
      ),

      // Accounting
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => const InvoicesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'invoice-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailsScreen(invoiceId: id);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),

      // Compliance
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),

      GoRoute(
        path: '/hos',
        name: 'hos',
        builder: (context, state) => const HosScreen(),
      ),

      // Training
      GoRoute(
        path: '/training',
        name: 'training',
        builder: (context, state) => const CoursesScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = StorageService.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
  );
});
