import 'package:flutter/material.dart';

/// MANIT TeamUp Coordinated Color System
/// Midnight Navy • Charcoal • Electric Violet • Cyan • Coral • Magenta
abstract final class AppColors {
  // Base Atmospheric Surfaces
  static const Color midnightNavyDeep = Color(0xFF060912);
  static const Color midnightNavy = Color(0xFF0A0E1A);
  static const Color midnightNavySubtle = Color(0xFF0F1527);
  static const Color charcoalSurface = Color(0xFF141926);
  static const Color charcoalSurfaceVariant = Color(0xFF1E2436);
  static const Color charcoalSurfaceElevated = Color(0xFF242B3F);
  static const Color charcoalBorder = Color(0xFF2B344D);
  static const Color charcoalDivider = Color(0xFF1E2538);

  // Electric Violet & Indigo (Primary Brand Anchors)
  static const Color electricViolet = Color(0xFF7C3AED);
  static const Color electricVioletLight = Color(0xFF8B5CF6);
  static const Color electricVioletGlow = Color(0xFFA78BFA);
  static const Color electricVioletSubtle = Color(0x2E7C3AED);
  static const Color electricVioletGlass = Color(0x1F8B5CF6);
  static const Color indigoAccent = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF6366F1);
  static const Color indigoSubtle = Color(0x284F46E5);

  // Cyan & Turquoise (Active Live Indicators, Hackathons)
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);
  static const Color cyanSubtle = Color(0x2506B6D4);
  static const Color turquoiseAccent = Color(0xFF14B8A6);
  static const Color turquoiseLight = Color(0xFF2DD4BF);
  static const Color turquoiseSubtle = Color(0x2514B8A6);

  // Coral & Orange (Urgent Recruitment, Open Vacancies, Alerts)
  static const Color coralAccent = Color(0xFFF43F5E);
  static const Color coralLight = Color(0xFFFB7185);
  static const Color coralSubtle = Color(0x28F43F5E);
  static const Color sunsetOrange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeSubtle = Color(0x25F97316);

  // Magenta & Pink (Special Categories & Highlights)
  static const Color magentaAccent = Color(0xFFD946EF);
  static const Color magentaLight = Color(0xFFE879F9);
  static const Color magentaSubtle = Color(0x25D946EF);

  // Status & Verification Indicators
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessLight = Color(0xFF34D399);
  static const Color statusSuccessSubtle = Color(0x2210B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningSubtle = Color(0x24F59E0B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusErrorSubtle = Color(0x24EF4444);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textLavender = Color(0xFFE0E7FF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Color(0xFFFFFFFF);

  // Atmospheric Gradients
  static const LinearGradient heroGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricViolet, indigoAccent, cyanAccent],
  );

  static const LinearGradient verifiedManitGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [electricViolet, magentaAccent],
  );

  static const LinearGradient coralSunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coralAccent, sunsetOrange],
  );

  static const LinearGradient cyanTurquoiseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanAccent, turquoiseAccent],
  );

  static const LinearGradient cardBorderGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x7F8B5CF6),
      Color(0x4C22D3EE),
      Colors.transparent,
    ],
  );
}
