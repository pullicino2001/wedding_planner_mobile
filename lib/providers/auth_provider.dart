import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth/auth_service.dart';

// ─── Service provider ────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

// ─── Auth state (nullable = not signed in) ───────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<GoogleSignInAccount?>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final account = await _service.silentSignIn();
    if (mounted) state = AsyncValue.data(account);
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      final account = await _service.signIn();
      if (mounted) state = AsyncValue.data(account);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    if (mounted) state = const AsyncValue.data(null);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GoogleSignInAccount?>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);

// ─── Convenience: current user (nullable) ────────────────────────────────────

final currentUserProvider = Provider<GoogleSignInAccount?>((ref) {
  return ref.watch(authProvider).value;
});
