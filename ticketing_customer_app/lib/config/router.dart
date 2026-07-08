import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/booting_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tickets/ticket_list_screen.dart';
import '../screens/tickets/create_ticket_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';
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
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isBooting = state.matchedLocation == '/boot';

      if (user == null) {
        if (state.matchedLocation == '/register') return null;
        return '/login';
      }

      final profile = await ref.read(userServiceProvider).getUserProfile(user.id);
      final role = profile?.role ?? 'customer';

      if (role != 'customer') {
        // Hanya izinkan pengguna biasa (customer) di aplikasi ini.
        await ref.read(authServiceProvider).signOut();
        return '/login';
      }

      if (isLoggingIn || isBooting) {
        return '/';
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketListScreen(),
      ),
      GoRoute(
        path: '/tickets/create',
        builder: (context, state) => const CreateTicketScreen(),
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

    ],
  );
});

