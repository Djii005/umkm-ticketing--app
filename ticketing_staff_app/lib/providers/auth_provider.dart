import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for the UserService instance
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Provider to stream auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider to get current user directly
final currentUserProvider = Provider<User?>((ref) {
  // Listen to auth state changes to update the current user
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});

// Provider to fetch the current user's profile (contains role: admin | teknisi | customer)
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(userServiceProvider).getUserProfile(user.id);
});

// StateNotifier to handle auth loading and errors
class AuthStateNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final UserService _userService;

  AuthStateNotifier(this._authService, this._userService) : super(const AsyncValue.data(null));

  // If [expectedRole] is provided, sign-in will be rejected (and the session
  // signed back out) when the account's role does not match the selected
  // login tab (Pengguna / Admin / Teknisi) on the login screen.
  Future<void> signIn(String email, String password, {String? expectedRole}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(email: email, password: password);
      final userId = response.user?.id;

      if (expectedRole != null && userId != null) {
        final profile = await _userService.getUserProfile(userId);
        if (profile == null || profile.role != expectedRole) {
          await _authService.signOut();
          throw Exception('Akun ini tidak terdaftar sebagai ${_roleLabel(expectedRole)}.');
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'teknisi':
        return 'Teknisi';
      default:
        return 'Pengguna';
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    debugPrint('[DEBUG] AuthStateNotifier.signUp: Starting registration for email: $email');
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signUp(email: email, password: password, fullName: fullName);
      debugPrint('[DEBUG] AuthStateNotifier.signUp: SUCCESS. User ID: ${response.user?.id}, Confirm status: ${response.user?.emailConfirmedAt}');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('[DEBUG] AuthStateNotifier.signUp: ERROR occurred!');
      debugPrint('[DEBUG] AuthStateNotifier.signUp: Error details: $e');
      debugPrint('[DEBUG] AuthStateNotifier.signUp: Stacktrace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<void>>((ref) {
  return AuthStateNotifier(ref.watch(authServiceProvider), ref.watch(userServiceProvider));
});
