import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../services/auth_service.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Current User ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

// User Model Provider
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value(null);
  return authService.userModelStream(userId);
});

// Auth Notifier for handling auth actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithApple();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
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

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    state = const AsyncValue.loading();
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      // auth state를 갱신하여 UI 업데이트
      _ref.invalidate(authStateProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

// Is Logged In Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
