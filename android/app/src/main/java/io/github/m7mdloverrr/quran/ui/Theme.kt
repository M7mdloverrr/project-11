package io.github.m7mdloverrr.quran.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import io.github.m7mdloverrr.quran.R

val Emerald = Color(0xFF0E7C5A)
val EmeraldBright = Color(0xFF34C08E)
val DarkGreen = Color(0xFF063D2C)
val Ink = Color(0xFF0A0D0C)

val QuranFont = FontFamily(Font(R.font.amiri_quran))

class PageColors(val page: Color, val text: Color, val mark: Color, val highlight: Color, val selected: Color)

val LocalPageColors = staticCompositionLocalOf {
    PageColors(Color.White, Color.Black, Emerald, Emerald.copy(alpha = 0.20f), Emerald.copy(alpha = 0.08f))
}

private val Light = lightColorScheme(
    primary = Emerald,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD4F1E4),
    onPrimaryContainer = DarkGreen,
    secondary = DarkGreen,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE3EFEA),
    onSecondaryContainer = DarkGreen,
    background = Color(0xFFF4F7F5),
    onBackground = Ink,
    surface = Color(0xFFF4F7F5),
    onSurface = Ink,
    surfaceVariant = Color(0xFFE6EEEA),
    onSurfaceVariant = Color(0xFF3F4A45),
    surfaceContainer = Color(0xFFEDF3F0),
    surfaceContainerHigh = Color(0xFFE6EEEA),
    outline = Color(0xFF8A9A93),
    outlineVariant = Color(0xFFCFDAD5),
)

private val Dark = darkColorScheme(
    primary = EmeraldBright,
    onPrimary = Color(0xFF00281B),
    primaryContainer = DarkGreen,
    onPrimaryContainer = Color(0xFFBDEFD9),
    secondary = Color(0xFF8FD9B9),
    onSecondary = Color(0xFF00281B),
    secondaryContainer = Color(0xFF14302A),
    onSecondaryContainer = Color(0xFFCBEBDD),
    background = Color(0xFF050807),
    onBackground = Color(0xFFEDF3F0),
    surface = Color(0xFF050807),
    onSurface = Color(0xFFEDF3F0),
    surfaceVariant = Color(0xFF16201C),
    onSurfaceVariant = Color(0xFFB9C7C1),
    surfaceContainer = Color(0xFF0E1513),
    surfaceContainerHigh = Color(0xFF16201C),
    outline = Color(0xFF6F807A),
    outlineVariant = Color(0xFF26332E),
)

@Composable
fun QuranTheme(dark: Boolean, content: @Composable () -> Unit) {
    val page = if (dark) {
        PageColors(Color(0xFF0F1513), Color(0xFFF3F3F0), EmeraldBright, EmeraldBright.copy(alpha = 0.24f), EmeraldBright.copy(alpha = 0.10f))
    } else {
        PageColors(Color.White, Color.Black, Emerald, Emerald.copy(alpha = 0.20f), Emerald.copy(alpha = 0.08f))
    }
    CompositionLocalProvider(LocalPageColors provides page) {
        MaterialTheme(colorScheme = if (dark) Dark else Light, content = content)
    }
}
