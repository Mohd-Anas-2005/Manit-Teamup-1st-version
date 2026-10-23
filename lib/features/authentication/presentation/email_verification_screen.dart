import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/manit_badge.dart';
import '../domain/auth_state.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  final VoidCallback? onVerified;

  const EmailVerificationScreen({
    super.key,
    this.email,
    this.onVerified,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _feedbackMessage;
  bool _isError = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  String get _targetEmail {
    if (widget.email != null && widget.email!.isNotEmpty) {
      return widget.email!;
    }
    return AuthService.instance.currentState.email ?? 'your email';
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 1) {
        setState(() => _resendCooldown--);
      } else {
        setState(() => _resendCooldown = 0);
        timer.cancel();
      }
    });
  }

  Future<void> _handleCheckStatus() async {
    setState(() {
      _isChecking = true;
      _feedbackMessage = null;
      _isError = false;
    });

    final verified = await AuthService.instance.checkEmailVerificationStatus();

    if (!mounted) return;

    setState(() {
      _isChecking = false;
      if (verified) {
        _feedbackMessage = 'Email verified successfully! Welcome to MANIT TeamUp.';
        _isError = false;
        widget.onVerified?.call();
      } else {
        _feedbackMessage =
            'Email confirmation not detected yet. Please ensure you clicked the verification link in your inbox.';
        _isError = true;
      }
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _feedbackMessage = null;
      _isError = false;
    });

    final res = await AuthService.instance.resendVerificationEmail(_targetEmail);

    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (res.isSuccess) {
        _feedbackMessage = 'Verification link resent to $_targetEmail.';
        _isError = false;
        _startCooldown();
      } else {
        _feedbackMessage = res.errorMessage ?? 'Failed to resend email.';
        _isError = true;
      }
    });
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isManit = AppAuthState.checkIsManitEmail(_targetEmail);

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Email Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isManit ? AppColors.verifiedManitGradient : AppColors.heroGlowGradient,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x337C3AED),
                          blurRadius: 24,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_unread_rounded, size: 40, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Verify Your Email',
                  style: AppTypography.displayLarge.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'We have dispatched an activation link to:',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalSurfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.charcoalBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _targetEmail,
                          style: const TextStyle(
                            color: AppColors.cyanLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isManit) ...[
                        const SizedBox(width: 8),
                        const ManitBadge(label: 'Verified MANIT'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.charcoalBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.electricVioletLight, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Instructions:',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Open your mail client and check for an email from MANIT TeamUp.\n'
                        '2. For @stu.manit.ac.in emails, check your institutional Outlook or Webmail.\n'
                        '3. If not visible in Inbox, please check Spam / Junk folders.\n'
                        '4. Tap the verification link, then return here and press "Check Status".',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_feedbackMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError ? AppColors.coralSubtle : AppColors.statusSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError
                            ? AppColors.coralLight.withValues(alpha: 0.3)
                            : AppColors.statusSuccess.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          color: _isError ? AppColors.coralAccent : AppColors.statusSuccess,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _feedbackMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _isError ? AppColors.coralLight : AppColors.statusSuccess,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                AppButton(
                  label: 'I Have Verified — Check Status',
                  isLoading: _isChecking,
                  onPressed: _handleCheckStatus,
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: (_resendCooldown > 0 || _isResending) ? null : _handleResend,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend Email ($_resendCooldown s)'
                        : 'Resend Verification Link',
                    style: const TextStyle(color: AppColors.cyanLight),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: _resendCooldown > 0 ? AppColors.charcoalBorder : AppColors.cyanLight.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: _handleSignOut,
                  child: const Text(
                    'Sign In with Another Account',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
