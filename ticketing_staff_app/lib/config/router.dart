import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/booting_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/dashboard/teknisi_dashboard_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';
import '../screens/tickets/admin_ticket_list_screen.dart';
import '../screens/tickets/teknisi_ticket_list_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_hospitals_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/profile/profile_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authServiceProvider).authStateChanges;
  final bootCompleted = ref.watch(bootCompletedProvider);

  return GoRouter(
    initialLocation: '/boot',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      if (!bootCompleted) {
        return '/boot';
      }

      final user = ref.read(currentUserProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isBooting = state.matchedLocation == '/boot';

      if (user == null) {
        return '/login';
      }

      final profile = await ref.read(userServiceProvider).getUserProfile(user.id);
      final role = profile?.role ?? 'customer';

      if (role == 'customer') {
        // Pelanggan tidak boleh masuk ke aplikasi staf.
        await ref.read(authServiceProvider).signOut();
        return '/login';
      }

      final homePath = role == 'admin' ? '/admin' : '/teknisi';

      if (isLoggingIn || isBooting || state.matchedLocation == '/') {
        return homePath;
      }

      final isSharedRoute =
          (state.matchedLocation.startsWith('/tickets/') && state.matchedLocation != '/tickets/create') ||
              state.matchedLocation == '/profile';

      if (role == 'admin' && !state.matchedLocation.startsWith('/admin') && !isSharedRoute) {
        return '/admin';
      }
      if (role == 'teknisi' && !state.matchedLocation.startsWith('/teknisi') && !isSharedRoute) {
        return '/teknisi';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const BootingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const BootingScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) {
          final ticketId = state.pathParameters['id'] ?? '';
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Admin ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/tickets',
        builder: (context, state) => const AdminTicketListScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/hospitals',
        builder: (context, state) => const AdminHospitalsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),

      // ── Teknisi ────────────────────────────────────────────────────────
      GoRoute(
        path: '/teknisi',
        builder: (context, state) => const TeknisiDashboardScreen(),
      ),
      GoRoute(
        path: '/teknisi/tickets',
        builder: (context, state) => const TeknisiTicketListScreen(),
      ),
      GoRoute(
        path: '/teknisi/history',
        builder: (context, state) => const TeknisiTicketListScreen(historyOnly: true),
      ),
    ],
  );
});

