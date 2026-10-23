package com.example.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// ==========================================
// MANIT TEAMUP CO-ORDINATED COLOR SYSTEM
// Midnight Navy • Charcoal • Electric Violet
// Indigo • Cyan & Turquoise • Coral & Orange • Magenta
// Soft White & Lavender Typography
// ==========================================

// Base Dark Atmospheric Surfaces
val MidnightNavyDeep = Color(0xFF060912)
val MidnightNavy = Color(0xFF0A0E1A)
val MidnightNavySubtle = Color(0xFF0F1527)
val CharcoalSurface = Color(0xFF141926)
val CharcoalSurfaceVariant = Color(0xFF1E2436)
val CharcoalSurfaceElevated = Color(0xFF242B3F)
val CharcoalBorder = Color(0xFF2B344D)
val CharcoalDivider = Color(0xFF1E2538)

// Electric Violet & Indigo (Primary Brand Anchors)
val ElectricViolet = Color(0xFF7C3AED)
val ElectricVioletLight = Color(0xFF8B5CF6)
val ElectricVioletGlow = Color(0xFFA78BFA)
val ElectricVioletSubtle = Color(0x2E7C3AED)
val ElectricVioletGlass = Color(0x1F8B5CF6)
val IndigoAccent = Color(0xFF4F46E5)
val IndigoLight = Color(0xFF6366F1)
val IndigoSubtle = Color(0x284F46E5)

// Cyan & Turquoise (Live Active Indicators, Nodes, Hackathons)
val CyanAccent = Color(0xFF06B6D4)
val CyanLight = Color(0xFF22D3EE)
val CyanSubtle = Color(0x2506B6D4)
val TurquoiseAccent = Color(0xFF14B8A6)
val TurquoiseLight = Color(0xFF2DD4BF)
val TurquoiseSubtle = Color(0x2514B8A6)

// Coral & Orange (Urgent Recruitment, Open Vacancies, Alerts)
val CoralAccent = Color(0xFFF43F5E)
val CoralLight = Color(0xFFFB7185)
val CoralSubtle = Color(0x28F43F5E)
val SunsetOrange = Color(0xFFF97316)
val OrangeLight = Color(0xFFFB923C)
val OrangeSubtle = Color(0x25F97316)

// Magenta & Pink (Special Project Categories, Highlights)
val MagentaAccent = Color(0xFFD946EF)
val MagentaLight = Color(0xFFE879F9)
val MagentaSubtle = Color(0x25D946EF)

// Status & Verification Indicators
val StatusSuccess = Color(0xFF10B981)
val StatusSuccessLight = Color(0xFF34D399)
val StatusSuccessSubtle = Color(0x2210B981)
val StatusWarning = Color(0xFFF59E0B)
val StatusWarningSubtle = Color(0x24F59E0B)

// Typography Palette
val TextPrimary = Color(0xFFF8FAFC)
val TextLavender = Color(0xFFE0E7FF)
val TextSecondary = Color(0xFF94A3B8)
val TextMuted = Color(0xFF64748B)
val White = Color(0xFFFFFFFF)

// Atmospheric Gradient Presets
val HeroGlowGradient = Brush.linearGradient(
    colors = listOf(ElectricViolet, IndigoAccent, CyanAccent)
)

val CardBorderGlow = Brush.linearGradient(
    colors = listOf(ElectricVioletLight.copy(alpha = 0.5f), CyanLight.copy(alpha = 0.3f), Color.Transparent)
)

val VerifiedManitGradient = Brush.horizontalGradient(
    colors = listOf(ElectricViolet, MagentaAccent)
)

val NetworkNodeGlow = Brush.radialGradient(
    colors = listOf(CyanLight.copy(alpha = 0.8f), CyanAccent.copy(alpha = 0.2f), Color.Transparent)
)
