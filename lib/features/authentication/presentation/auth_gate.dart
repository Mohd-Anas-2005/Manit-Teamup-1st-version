import 'package:flutter/material.dart';
import '../../../core/navigation/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/auth_state.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Central AuthGate widget.
///
/// Ensures strict security:
/// - Never renders protected screens before authentication state is resolved.
/// - Restores sessions seamlessly without flashing login screens.
/// - Redirects unverified users to the verification screen.
/// - Displays expired session notifications cleanly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAuthState>(
      valueListenable: AuthService.instance.authStateNotifier,
      builder: (context, authState, _) {
        switch (authState.status) {
          case AuthStatus.initial:
            return const _AuthLoadingSplashScreen();

          case AuthStatus.unverifiedEmail:
            return EmailVerificationScreen(
              email: authState.email,
            );

          case AuthStatus.passwordRecovery:
            return const ResetPasswordScreen();

          case AuthStatus.authenticated:
            return const AppScaffold();

          case AuthStatus.unauthenticated:
          case AuthStatus.authenticating:
          case AuthStatus.error:
            return LoginScreen(
              initialErrorMessage: authState.isSessionExpired
                  ? 'Your session has expired. Please sign in again.'
                  : authState.errorMessage,
            );
        }
      },
    );
  }
}

class _AuthLoadingSplashScreen extends StatelessWidget {
  const _AuthLoadingSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.heroGlowGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.hub_rounded, size: 40, color: AppColors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'MANIT TeamUp',
              style: AppTypography.displayLarge.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Connecting Campus Innovators',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricVioletLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
