import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
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

// StateNotifier to handle auth loading and errors
class AuthStateNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
  return AuthStateNotifier(ref.watch(authServiceProvider));
});
