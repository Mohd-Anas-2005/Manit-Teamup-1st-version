import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/auth_gate.dart';
import '../features/authentication/presentation/email_verification_screen.dart';
import '../features/authentication/presentation/forgot_password_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/authentication/presentation/reset_password_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/teams/presentation/create_team_screen.dart';

class ManitTeamUpApp extends StatelessWidget {
  final Widget? home;

  const ManitTeamUpApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MANIT TeamUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home ?? const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-email': (_) => const EmailVerificationScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/create-team': (_) => const CreateTeamScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/onboarding': (ctx) => OnboardingScreen(
              onFinish: () => Navigator.of(ctx).pop(),
            ),
      },
    );
  }
}
