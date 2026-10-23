import 'package:supabase_flutter/supabase_flutter.dart';

/// Representation of the authentication lifecycle states.
enum AuthStatus {
  /// App is checking persisted session from local storage.
  initial,

  /// Authentication operation in progress (signing in, registering, etc.)
  authenticating,

  /// User is signed in with a valid, verified session.
  authenticated,

  /// User is not signed in.
  unauthenticated,

  /// User registered or signed in, but their email verification is pending.
  unverifiedEmail,

  /// User opened the application via a password recovery link.
  passwordRecovery,

  /// An authentication error occurred.
  error,
}

/// Immutable state containing user session and verification details.
class AppAuthState {
  final AuthStatus status;
  final User? user;
  final Session? session;
  final String? errorMessage;
  final bool isSessionExpired;

  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.session,
    this.errorMessage,
    this.isSessionExpired = false,
  });

  String? get userId => user?.id;
  String? get email => user?.email;

  /// Whether the user has a verified email confirmed by Supabase Auth.
  bool get isEmailVerified {
    if (user == null) return false;
    return user!.emailConfirmedAt != null;
  }

  /// Whether the user is fully authenticated and allowed into protected screens.
  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      user != null &&
      !isSessionExpired;

  /// Whether the current email belongs to an institutional MANIT domain.
  bool get isManitEmail {
    if (email == null) return false;
    return checkIsManitEmail(email!);
  }

  /// Static helper to check if an email matches the institutional MANIT domain.
  static bool checkIsManitEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@stu.manit.ac.in') || lower.endsWith('@manit.ac.in');
  }

  AppAuthState copyWith({
    AuthStatus? status,
    User? user,
    Session? session,
    String? errorMessage,
    bool? isSessionExpired,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      errorMessage: errorMessage,
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
    );
  }
}
