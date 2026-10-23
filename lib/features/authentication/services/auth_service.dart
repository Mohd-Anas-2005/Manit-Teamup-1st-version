import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/auth_state.dart';

/// Result wrapper for authentication operations.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool requiresEmailVerification;

  const AuthResult.success({this.requiresEmailVerification = false})
      : isSuccess = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        requiresEmailVerification = false;
}

/// Central production Authentication Service.
///
/// Encapsulates all interactions with Supabase Auth:
/// - Email/Password Registration with metadata
/// - Email/Password Login
/// - Email Verification checks and resends
/// - Password recovery and updates
/// - Session restoration and expiration detection
/// - Zero credential leaks (passwords never stored or logged)
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient? _injectedClient;
  StreamSubscription<AuthState>? _authSubscription;

  /// Visible for testing: inject mock or custom SupabaseClient.
  @visibleForTesting
  set clientForTesting(SupabaseClient? client) {
    _injectedClient = client;
  }

  SupabaseClient? get _client => _injectedClient ?? SupabaseService.instance.client;

  final ValueNotifier<AppAuthState> authStateNotifier =
      ValueNotifier<AppAuthState>(const AppAuthState());

  AppAuthState get currentState => authStateNotifier.value;

  /// Initialize and restore existing session from secure local storage.
  Future<void> initialize() async {
    final client = _client;
    if (client == null) {
      authStateNotifier.value = AppAuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: SupabaseService.instance.initError ?? 'Supabase backend not initialized.',
      );
      return;
    }

    // Cancel any previous stream subscription
    await _authSubscription?.cancel();

    // Listen to real-time auth state events
    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      _handleAuthStateEvent(data.event, data.session);
    });

    // Inspect current session
    final currentSession = client.auth.currentSession;
    if (currentSession != null) {
      if (currentSession.isExpired) {
        try {
          final refreshRes = await client.auth.refreshSession();
          if (refreshRes.session != null) {
            _updateStateFromSession(refreshRes.session);
            return;
          }
        } catch (_) {
          authStateNotifier.value = const AppAuthState(
            status: AuthStatus.unauthenticated,
            isSessionExpired: true,
            errorMessage: 'Your session has expired. Please sign in again.',
          );
          return;
        }
      }

      _updateStateFromSession(currentSession);
    } else {
      authStateNotifier.value = const AppAuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  void _handleAuthStateEvent(AuthChangeEvent event, Session? session) {
    switch (event) {
      case AuthChangeEvent.signedIn:
        _updateStateFromSession(session);
        break;
      case AuthChangeEvent.signedOut:
        authStateNotifier.value = const AppAuthState(
          status: AuthStatus.unauthenticated,
        );
        break;
      case AuthChangeEvent.tokenRefreshed:
        _updateStateFromSession(session);
        break;
      case AuthChangeEvent.userUpdated:
        _updateStateFromSession(session);
        break;
      case AuthChangeEvent.passwordRecovery:
        authStateNotifier.value = authStateNotifier.value.copyWith(
          status: AuthStatus.passwordRecovery,
          session: session,
          user: session?.user,
        );
        break;
      default:
        break;
    }
  }

  void _updateStateFromSession(Session? session) {
    if (session == null) {
      authStateNotifier.value = const AppAuthState(
        status: AuthStatus.unauthenticated,
      );
      return;
    }

    final user = session.user;
    final isVerified = user.emailConfirmedAt != null;

    if (!isVerified) {
      authStateNotifier.value = AppAuthState(
        status: AuthStatus.unverifiedEmail,
        user: user,
        session: session,
      );
    } else {
      authStateNotifier.value = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
        session: session,
      );
    }
  }

  /// Sign in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Backend is not configured.');
    }

    authStateNotifier.value = authStateNotifier.value.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Failed to retrieve user details.');
      }

      final isVerified = user.emailConfirmedAt != null;
      if (!isVerified) {
        authStateNotifier.value = AppAuthState(
          status: AuthStatus.unverifiedEmail,
          user: user,
          session: response.session,
        );
        return const AuthResult.success(requiresEmailVerification: true);
      }

      authStateNotifier.value = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
        session: response.session,
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      final message = _mapAuthError(e.message);
      authStateNotifier.value = authStateNotifier.value.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      return AuthResult.failure(message);
    } catch (e) {
      const message = 'An unexpected connection error occurred. Please check your network and retry.';
      authStateNotifier.value = authStateNotifier.value.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      return const AuthResult.failure(message);
    }
  }

  /// Sign up with email, password, and institutional scholar profile metadata.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    String? scholarNumber,
  }) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Backend is not configured.');
    }

    authStateNotifier.value = authStateNotifier.value.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    final cleanEmail = email.trim();
    final isManit = AppAuthState.checkIsManitEmail(cleanEmail);

    try {
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (scholarNumber != null && scholarNumber.trim().isNotEmpty)
            'scholar_number': scholarNumber.trim(),
          'is_manit_verified': isManit,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed to create user account.');
      }

      final isVerified = user.emailConfirmedAt != null;

      if (!isVerified) {
        authStateNotifier.value = AppAuthState(
          status: AuthStatus.unverifiedEmail,
          user: user,
          session: response.session,
        );
        return const AuthResult.success(requiresEmailVerification: true);
      }

      authStateNotifier.value = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
        session: response.session,
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      final message = _mapAuthError(e.message);
      authStateNotifier.value = authStateNotifier.value.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      return AuthResult.failure(message);
    } catch (e) {
      final errStr = e.toString();
      final lower = errStr.toLowerCase();
      String message = 'Unable to complete registration. Please try again.';
      if (lower.contains('rate limit') || lower.contains('429') || lower.contains('over_email_send_rate_limit')) {
        message = 'Email rate limit reached on Supabase. Disable "Confirm email" in Supabase Auth settings, or wait a few minutes.';
      } else if (lower.contains('network') || lower.contains('socket') || lower.contains('connection')) {
        message = 'Network connection error. Please check your internet connection.';
      } else if (errStr.isNotEmpty && !errStr.contains('Exception:')) {
        message = errStr;
      }
      authStateNotifier.value = authStateNotifier.value.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      return AuthResult.failure(message);
    }
  }

  /// Send password recovery link to user's registered email address.
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Backend is not configured.');
    }

    try {
      await client.auth.resetPasswordForEmail(email.trim());
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return const AuthResult.failure('Unable to send password reset email. Please try again.');
    }
  }

  /// Update password (e.g. after following recovery link).
  Future<AuthResult> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Backend is not configured.');
    }

    try {
      final res = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (res.user != null) {
        authStateNotifier.value = AppAuthState(
          status: AuthStatus.authenticated,
          user: res.user,
          session: client.auth.currentSession,
        );
      }
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return const AuthResult.failure('Unable to update password. Please try again.');
    }
  }

  /// Resend confirmation email for pending unverified accounts.
  Future<AuthResult> resendVerificationEmail(String email) async {
    final client = _client;
    if (client == null) {
      return const AuthResult.failure('Backend is not configured.');
    }

    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return const AuthResult.failure('Failed to resend verification email.');
    }
  }

  /// Refresh user from Supabase to check if email has been verified.
  Future<bool> checkEmailVerificationStatus() async {
    final client = _client;
    if (client == null) return false;

    try {
      final userResponse = await client.auth.getUser();
      final user = userResponse.user;
      if (user != null && user.emailConfirmedAt != null) {
        authStateNotifier.value = AppAuthState(
          status: AuthStatus.authenticated,
          user: user,
          session: client.auth.currentSession,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Secure Sign Out.
  Future<void> signOut() async {
    final client = _client;
    try {
      if (client != null) {
        await client.auth.signOut();
      }
    } finally {
      authStateNotifier.value = const AppAuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Request account deletion: Clears user profile record and signs out.
  Future<AuthResult> deleteAccount() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return const AuthResult.failure('User is not authenticated.');
    }
    try {
      // 1. Delete user profile record
      await client.from('profiles').delete().eq('id', user.id);
      // 2. Sign out session
      await signOut();
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Failed to delete account: $e');
    }
  }

  /// Map raw Supabase / GoTrue error strings to clean, user-friendly messages.
  String _mapAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please verify and try again.';
    }
    if (lower.contains('user already registered') || lower.contains('email already in use')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Your email address has not been confirmed yet. Please verify your inbox.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    if (lower.contains('rate limit') || lower.contains('over_email_send_rate_limit')) {
      return 'Email rate limit reached on Supabase. Disable "Confirm email" in Supabase Auth settings, or wait a few minutes.';
    }
    if (lower.contains('email_address_invalid') || lower.contains('is invalid')) {
      return 'This email address cannot be registered (unconfirmed account already pending or invalid domain).';
    }
    return raw;
  }

  void dispose() {
    _authSubscription?.cancel();
    authStateNotifier.dispose();
  }
}
