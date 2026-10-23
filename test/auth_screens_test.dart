import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/core/theme/app_theme.dart';
import 'package:manit_teamup/features/authentication/domain/auth_state.dart';
import 'package:manit_teamup/features/authentication/presentation/auth_gate.dart';
import 'package:manit_teamup/features/authentication/presentation/email_verification_screen.dart';
import 'package:manit_teamup/features/authentication/presentation/forgot_password_screen.dart';
import 'package:manit_teamup/features/authentication/presentation/login_screen.dart';
import 'package:manit_teamup/features/authentication/presentation/register_screen.dart';
import 'package:manit_teamup/features/authentication/presentation/reset_password_screen.dart';
import 'package:manit_teamup/features/authentication/services/auth_service.dart';

Widget _wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: child,
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Renders login fields and triggers validation errors on empty submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LoginScreen()));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Institutional Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Shows Verified MANIT badge on institutional email input',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LoginScreen()));
      await tester.pump();

      expect(find.text('Verified MANIT'), findsNothing);

      // Enter standard Gmail
      await tester.enterText(
        find.byType(TextFormField).first,
        'student@gmail.com',
      );
      await tester.pump();
      expect(find.text('Verified MANIT'), findsNothing);

      // Enter institutional email
      await tester.enterText(
        find.byType(TextFormField).first,
        '211112044@stu.manit.ac.in',
      );
      await tester.pump();
      expect(find.text('Verified MANIT'), findsOneWidget);
    });

    testWidgets('Toggles password visibility when eye icon tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LoginScreen()));
      await tester.pump();

      final passwordFinder = find.byType(TextFormField).at(1);
      final initialFormField = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      expect(initialFormField.obscureText, isTrue);

      // Tap visibility icon
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final updatedFormField = tester.widget<EditableText>(
        find.descendant(of: passwordFinder, matching: find.byType(EditableText)),
      );
      expect(updatedFormField.obscureText, isFalse);
    });

    testWidgets('Displays initial error message if session expired or failed',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const LoginScreen(
        initialErrorMessage: 'Your session has expired. Please sign in again.',
      )));
      await tester.pump();

      expect(find.text('Your session has expired. Please sign in again.'), findsOneWidget);
      expect(find.byTooltip('Retry'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders all fields including password confirmation and validates matching',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const RegisterScreen()));
      await tester.pump();

      expect(find.text('Join MANIT TeamUp'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Scholar / Roll Number (Optional)'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register & Continue'), findsOneWidget);

      // Fill mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Rahul Verma');
      await tester.enterText(find.byType(TextFormField).at(1), '211112044@stu.manit.ac.in');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'Mismatch999');

      await tester.tap(find.text('Register & Continue'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('Validates email field and displays instructions',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const ForgotPasswordScreen()));
      await tester.pump();

      expect(find.text('Recover Access'), findsOneWidget);
      expect(find.text('Send Recovery Link'), findsOneWidget);

      await tester.tap(find.text('Send Recovery Link'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });
  });

  group('EmailVerificationScreen Widget Tests', () {
    testWidgets('Displays target email, instructions, and resend button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const EmailVerificationScreen(
        email: 'scholar21@stu.manit.ac.in',
      )));
      await tester.pump();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('scholar21@stu.manit.ac.in'), findsOneWidget);
      expect(find.text('Verified MANIT'), findsOneWidget);
      expect(find.text('I Have Verified — Check Status'), findsOneWidget);
      expect(find.text('Resend Verification Link'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('Validates password length and matching confirmation',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithTheme(const ResetPasswordScreen()));
      await tester.pump();

      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Test short password
      await tester.enterText(find.byType(TextFormField).at(0), '123');
      await tester.enterText(find.byType(TextFormField).at(1), '123');

      await tester.tap(find.text('Update Password & Continue'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('AuthGate Widget Reactive Flow Tests', () {
    testWidgets('Renders splash loading indicator in initial state',
        (WidgetTester tester) async {
      AuthService.instance.authStateNotifier.value = const AppAuthState(
        status: AuthStatus.initial,
      );

      await tester.pumpWidget(_wrapWithTheme(const AuthGate()));
      await tester.pump();

      expect(find.text('Connecting Campus Innovators'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders LoginScreen when unauthenticated',
        (WidgetTester tester) async {
      AuthService.instance.authStateNotifier.value = const AppAuthState(
        status: AuthStatus.unauthenticated,
      );

      await tester.pumpWidget(_wrapWithTheme(const AuthGate()));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Renders EmailVerificationScreen when email verification is pending',
        (WidgetTester tester) async {
      AuthService.instance.authStateNotifier.value = const AppAuthState(
        status: AuthStatus.unverifiedEmail,
      );

      await tester.pumpWidget(_wrapWithTheme(const AuthGate()));
      await tester.pump();

      expect(find.text('Verify Your Email'), findsOneWidget);
    });
  });
}
