import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent; // [Biometric]
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
// import '../../../../core/config/supabase_client.dart'; // [Biometric]
import '../../../../core/services/sentry_service.dart';
import '../../../../core/services/secure_storage_provider.dart';
import '../../../../core/providers/analytics_provider.dart';

// ============================================================================
// Data Source Provider
// ============================================================================

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

// ============================================================================
// Repository Provider
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

// ============================================================================
// User Session Key — increments on every sign-in / sign-out so all data
// providers that watch it automatically re-run for the new user.
// ============================================================================

final userSessionProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// Auth State Provider
// ============================================================================

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// ============================================================================
// Current User Provider
// ============================================================================

final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});

// ============================================================================
// Auth State Notifier
// ============================================================================

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  StreamSubscription<UserEntity?>? _authSubscription;
  // StreamSubscription? _tokenSyncSubscription; // [Biometric]

  AuthNotifier(this._repository, this._ref) : super(AuthState()) {
    _init();
  }

  void _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getCurrentUser();
      state = AuthState(user: user, isLoading: false);

      // Set user context in Sentry
      if (user != null) {
        await _setUserContext(user);
      }
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
    }

    // Subscribe to Supabase auth events so external session changes
    // (biometric refreshSession, deep-link sign-in, token rotation) automatically
    // update the notifier — no explicit refreshCurrentUser() call needed.
    _authSubscription = _repository.authStateChanges.listen((user) {
      state = AuthState(user: user, isLoading: false);
      if (user != null) {
        _setUserContext(user);
      } else {
        _clearUserContext();
      }
    });

    // [Biometric: commented out — token sync subscription for refresh token rotation]
    // final storage = _ref.read(secureStorageServiceProvider);
    // _tokenSyncSubscription = supabase.auth.onAuthStateChange.listen((event) {
    //   final token = event.session?.refreshToken;
    //   if (token != null &&
    //       (event.event == AuthChangeEvent.signedIn ||
    //           event.event == AuthChangeEvent.tokenRefreshed ||
    //           event.event == AuthChangeEvent.initialSession)) {
    //     storage.saveRefreshToken(token);
    //   }
    // });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    // _tokenSyncSubscription?.cancel(); // [Biometric]
    super.dispose();
  }

  Future<void> _setUserContext(UserEntity user) async {
    await SentryService.setUser(id: user.id, email: user.email);
    SentryService.addBreadcrumb(
      message: 'User authenticated',
      category: 'auth',
      data: {'user_id': user.id},
    );
  }

  Future<void> _clearUserContext() async {
    await SentryService.clearUser();
    SentryService.addBreadcrumb(
      message: 'User signed out',
      category: 'auth',
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AuthState(user: user, isLoading: false);

      // Bump session key so all data providers re-run for the new user
      _ref.read(userSessionProvider.notifier).state++;

      // Set user context in Sentry and track sign in
      await _setUserContext(user);

      // Track sign in event
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.trackSignIn(method: 'email');
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      // If email confirmation is disabled, the datasource returns a fully
      // authenticated user. If confirmation is required, getCurrentUser()
      // returns null (unconfirmed users are treated as unauthenticated).
      final currentUser = await _repository.getCurrentUser();
      state = AuthState(user: currentUser, isLoading: false);

      if (currentUser != null) {
        _ref.read(userSessionProvider.notifier).state++;
        await _setUserContext(currentUser);
      }

      // Track sign up event
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.trackSignUp(method: 'email');
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.trackFeatureUsed('account_deleted');

      await _repository.deleteAccount();
      state = AuthState(user: null, isLoading: false);

      _ref.read(userSessionProvider.notifier).state++;
      await _clearUserContext();
      await _ref.read(secureStorageServiceProvider).clearEmail();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Track sign out before clearing user
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.trackSignOut();

      await _repository.signOut();
      state = AuthState(user: null, isLoading: false);

      // Bump session key so all cached data providers are cleared
      _ref.read(userSessionProvider.notifier).state++;

      // Clear user context from Sentry
      await _clearUserContext();
    } catch (e) {
      state = AuthState(
        user: state.user,
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        currency: currency,
      );
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  Future<void> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.verifyEmailOTP(
        email: email,
        token: token,
      );
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Re-reads the current user from Supabase — call this after email confirmation
  /// so the router reflects the newly authenticated state.
  Future<void> refreshCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
      if (user != null) {
        await _setUserContext(user);
      }
    } catch (e, stack) {
      // Keep existing state on error; do not wipe out a valid session.
      SentryService.captureException(e, stackTrace: stack, hint: 'refreshCurrentUser failed');
    }
  }

  Future<void> resendOTP(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.resendOTP(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  bool isEmailNotConfirmed(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('email not confirmed');
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('user not found') ||
        errorStr.contains('invalid email or password')) {
      return 'Invalid email or password';
    } else if (errorStr.contains('email not confirmed')) {
      return 'Please confirm your email address';
    } else if (errorStr.contains('user already registered') ||
        errorStr.contains('an account with this email already exists')) {
      return 'An account with this email already exists. Please sign in.';
    } else if (errorStr.contains('too many signup attempts') ||
        errorStr.contains('email rate limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    } else if (errorStr.contains('password')) {
      return 'Password does not meet requirements';
    } else if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Network error. Please check your connection';
    } else if (errorStr.contains('banned') ||
        errorStr.contains('user is banned')) {
      return 'Your account has been disabled. Please contact support.';
    } else if (errorStr.contains('database error') ||
        errorStr.contains('server error')) {
      return 'A server error occurred. Please try again.';
    } else if (errorStr.contains('sign up failed:')) {
      // Surface the specific message the datasource already formatted
      const prefix = 'sign up failed:';
      final idx = errorStr.indexOf(prefix);
      if (idx != -1) {
        final specific = error.toString().substring(idx + prefix.length).trim();
        if (specific.isNotEmpty && specific.length < 200) return specific;
      }
      return 'Failed to create account. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) {
    return AuthNotifier(ref.watch(authRepositoryProvider), ref);
  },
);
