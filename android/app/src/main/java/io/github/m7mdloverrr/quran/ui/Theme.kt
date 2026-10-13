package io.github.m7mdloverrr.quran.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import io.github.m7mdloverrr.quran.R

val Emerald = Color(0xFF0E7C5A)
val EmeraldBright = Color(0xFF34C08E)
val DarkGreen = Color(0xFF063D2C)
val Ink = Color(0xFF0A0D0C)

val QuranFonts = listOf(
    "أميري قرآن" to FontFamily(Font(R.font.amiri_quran)),
    "أميري" to FontFamily(Font(R.font.amiri)),
    "شهرزاد" to FontFamily(Font(R.font.scheherazade)),
    "نسخ" to FontFamily(Font(R.font.noto_naskh)),
)
var quranFontIndex by mutableIntStateOf(0)
val QuranFont: FontFamily get() = QuranFonts.getOrElse(quranFontIndex) { QuranFonts[0] }.second

class PageColors(val page: Color, val text: Color, val mark: Color, val highlight: Color, val selected: Color)

val LocalPageColors = staticCompositionLocalOf {
    PageColors(Color.White, Color.Black, Emerald, Emerald.copy(alpha = 0.20f), Emerald.copy(alpha = 0.08f))
}

private val Light = lightColorScheme(
    inversePrimary = EmeraldBright,
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
    inversePrimary = Emerald,
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

val PageStyleNames = listOf("ورق المصحف", "كريمي", "أخضر هادئ", "سادة")

private val lightPages = listOf(
    Color(0xFFFBF3DF) to Color(0xFF1B1B18),
    Color(0xFFF2E3C2) to Color(0xFF2A1E10),
    Color(0xFFEAF4EC) to Color(0xFF10201A),
    Color(0xFFFFFFFF) to Color(0xFF000000),
)

private val darkPages = listOf(
    Color(0xFF1E1B14) to Color(0xFFEFE6D2),
    Color(0xFF2A2116) to Color(0xFFF1E2C4),
    Color(0xFF0F2A21) to Color(0xFFE8F3EE),
    Color(0xFF17201D) to Color(0xFFF3F3F0),
)

fun pageColors(dark: Boolean, style: Int): PageColors {
    val (bg, fg) = (if (dark) darkPages else lightPages)[style.coerceIn(0, 3)]
    val m = if (dark) EmeraldBright else Emerald
    return PageColors(bg, fg, m, m.copy(alpha = if (dark) 0.24f else 0.20f), m.copy(alpha = if (dark) 0.10f else 0.08f))
}

@Composable
fun QuranTheme(dark: Boolean, pageStyle: Int = 0, content: @Composable () -> Unit) {
    val page = pageColors(dark, pageStyle)
    CompositionLocalProvider(LocalPageColors provides page) {
        MaterialTheme(colorScheme = if (dark) Dark else Light, content = content)
    }
}
