import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manit_teamup/core/theme/app_colors.dart';
import 'package:manit_teamup/core/theme/app_theme.dart';
import 'package:manit_teamup/core/theme/app_typography.dart';

void main() {
  group('AppTheme & Design Tokens Test', () {
    test('Verifies coordinated color palette tokens', () {
      expect(AppColors.midnightNavy, const Color(0xFF0A0E1A));
      expect(AppColors.midnightNavyDeep, const Color(0xFF060912));
      expect(AppColors.charcoalSurface, const Color(0xFF141926));
      expect(AppColors.electricViolet, const Color(0xFF7C3AED));
      expect(AppColors.cyanAccent, const Color(0xFF06B6D4));
      expect(AppColors.coralAccent, const Color(0xFFF43F5E));
      expect(AppColors.magentaAccent, const Color(0xFFD946EF));
    });

    test('Verifies Material 3 dark theme configuration', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.electricViolet);
      expect(theme.colorScheme.secondary, AppColors.cyanAccent);
      expect(theme.colorScheme.tertiary, AppColors.coralAccent);
      expect(theme.scaffoldBackgroundColor, AppColors.midnightNavy);
    });

    test('Verifies AppTypography tokens', () {
      expect(AppTypography.displayLarge.fontSize, 32);
      expect(AppTypography.displayLarge.color, AppColors.textPrimary);
      expect(AppTypography.bodyMedium.color, AppColors.textSecondary);
    });
  });
}
