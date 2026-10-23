package com.example.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = ElectricViolet,
    onPrimary = TextPrimary,
    primaryContainer = CharcoalSurfaceVariant,
    onPrimaryContainer = ElectricVioletLight,
    secondary = CyanAccent,
    onSecondary = MidnightNavyDeep,
    secondaryContainer = CharcoalSurfaceVariant,
    onSecondaryContainer = CyanLight,
    tertiary = MagentaAccent,
    onTertiary = TextPrimary,
    tertiaryContainer = CharcoalSurfaceVariant,
    onTertiaryContainer = MagentaLight,
    background = MidnightNavy,
    onBackground = TextPrimary,
    surface = CharcoalSurface,
    onSurface = TextPrimary,
    surfaceVariant = CharcoalSurfaceVariant,
    onSurfaceVariant = TextSecondary,
    outline = CharcoalBorder,
    outlineVariant = CharcoalDivider,
    error = CoralAccent,
    onError = TextPrimary,
    errorContainer = CharcoalSurfaceVariant,
    onErrorContainer = CoralLight
)

@Composable
fun ManitTeamUpTheme(
    content: @Composable () -> Unit
) {
    val colorScheme = DarkColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = MidnightNavy.toArgb()
                window.navigationBarColor = MidnightNavy.toArgb()
                val controller = WindowCompat.getInsetsController(window, view)
                controller.isAppearanceLightStatusBars = false
                controller.isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
