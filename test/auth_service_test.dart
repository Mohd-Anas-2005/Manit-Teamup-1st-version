import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/features/authentication/domain/auth_state.dart';
import 'package:manit_teamup/features/authentication/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppAuthState Domain Model Tests', () {
    test('Defaults to initial unauthenticated state', () {
      const state = AppAuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isEmailVerified, isFalse);
      expect(state.isManitEmail, isFalse);
      expect(state.isSessionExpired, isFalse);
    });

    test('checkIsManitEmail correctly identifies institutional domains', () {
      expect(AppAuthState.checkIsManitEmail('scholar21@stu.manit.ac.in'), isTrue);
      expect(AppAuthState.checkIsManitEmail('FACULTY@MANIT.AC.IN'), isTrue);
      expect(AppAuthState.checkIsManitEmail('student@gmail.com'), isFalse);
      expect(AppAuthState.checkIsManitEmail('attacker@stu.manit.ac.in.fake.com'), isFalse);
      expect(AppAuthState.checkIsManitEmail(''), isFalse);
    });

    test('isEmailVerified returns true only when emailConfirmedAt is populated', () {
      final unverifiedUser = User(
        id: 'user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'scholar@stu.manit.ac.in',
      );

      final verifiedUser = User(
        id: 'user-2',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'scholar@stu.manit.ac.in',
        emailConfirmedAt: DateTime.now().toIso8601String(),
      );

      final stateUnverified = AppAuthState(
        status: AuthStatus.unverifiedEmail,
        user: unverifiedUser,
      );
      expect(stateUnverified.isEmailVerified, isFalse);
      expect(stateUnverified.isAuthenticated, isFalse);

      final stateVerified = AppAuthState(
        status: AuthStatus.authenticated,
        user: verifiedUser,
      );
      expect(stateVerified.isEmailVerified, isTrue);
      expect(stateVerified.isAuthenticated, isTrue);
    });

    test('isAuthenticated evaluates false if session is expired', () {
      final verifiedUser = User(
        id: 'user-3',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'scholar@stu.manit.ac.in',
        emailConfirmedAt: DateTime.now().toIso8601String(),
      );

      final state = AppAuthState(
        status: AuthStatus.authenticated,
        user: verifiedUser,
        isSessionExpired: true,
      );

      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith produces expected updated immutable state', () {
      const initial = AppAuthState(status: AuthStatus.initial);
      final updated = initial.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Invalid credentials',
        isSessionExpired: true,
      );

      expect(updated.status, AuthStatus.unauthenticated);
      expect(updated.errorMessage, 'Invalid credentials');
      expect(updated.isSessionExpired, isTrue);
      expect(initial.status, AuthStatus.initial);
    });
  });

  group('AuthService State & Invariants Tests', () {
    test('AuthService returns failure when backend is not configured', () async {
      final auth = AuthService.instance;
      auth.clientForTesting = null;

      final signInRes = await auth.signIn(
        email: 'scholar@stu.manit.ac.in',
        password: 'password123',
      );
      expect(signInRes.isSuccess, isFalse);
      expect(signInRes.errorMessage, contains('Backend is not configured'));

      final signUpRes = await auth.signUp(
        email: 'scholar@stu.manit.ac.in',
        password: 'password123',
        fullName: 'Test Scholar',
      );
      expect(signUpRes.isSuccess, isFalse);

      final resetRes = await auth.sendPasswordResetEmail('scholar@stu.manit.ac.in');
      expect(resetRes.isSuccess, isFalse);

      final updateRes = await auth.updatePassword('newPassword123');
      expect(updateRes.isSuccess, isFalse);

      final resendRes = await auth.resendVerificationEmail('scholar@stu.manit.ac.in');
      expect(resendRes.isSuccess, isFalse);
    });

    test('AuthService.signOut resets state to unauthenticated', () async {
      final auth = AuthService.instance;
      auth.authStateNotifier.value = const AppAuthState(
        status: AuthStatus.authenticated,
      );

      await auth.signOut();
      expect(auth.currentState.status, AuthStatus.unauthenticated);
      expect(auth.currentState.isAuthenticated, isFalse);
    });
  });
}
