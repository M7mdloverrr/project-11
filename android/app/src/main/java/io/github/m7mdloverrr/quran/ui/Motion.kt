package io.github.m7mdloverrr.quran.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlin.random.Random

/** Fades and slides content up when it first appears, [index] staggering a list of items. */
fun Modifier.appear(index: Int = 0): Modifier = composed {
    val a = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(index * 70L)
        a.animateTo(1f, tween(480, easing = FastOutSlowInEasing))
    }
    val dy = with(LocalDensity.current) { 24.dp.toPx() }
    graphicsLayer {
        alpha = a.value
        translationY = (1f - a.value) * dy
        val s = 0.96f + 0.04f * a.value
        scaleX = s; scaleY = s
    }
}

/** Springs slightly smaller while pressed. */
fun Modifier.pressScale(source: MutableInteractionSource): Modifier = composed {
    val pressed by source.collectIsPressedAsState()
    val s by animateFloatAsState(if (pressed) 0.96f else 1f, spring(Spring.DampingRatioMediumBouncy, Spring.StiffnessMedium), label = "press")
    graphicsLayer { scaleX = s; scaleY = s }
}

private class Piece(val x: Float, val delay: Float, val speed: Float, val spin: Float, val size: Float, val color: Color, val sway: Float)

/** A short burst of falling confetti. */
@Composable
fun Confetti(modifier: Modifier = Modifier) {
    val colors = listOf(Color(0xFF2E9E6A), Color(0xFFE0B341), Color(0xFF7CC4A0), Color(0xFFF2D27A), Color(0xFF1F7A53))
    val pieces = remember { List(46) { Piece(Random.nextFloat(), Random.nextFloat() * 0.35f, 0.6f + Random.nextFloat() * 0.6f, Random.nextFloat() * 720f - 360f, 5f + Random.nextFloat() * 6f, colors.random(), Random.nextFloat() * 40f - 20f) } }
    val t = remember { Animatable(0f) }
    LaunchedEffect(Unit) { t.animateTo(1f, tween(2600)) }
    Canvas(modifier) {
        val d = density
        for (p in pieces) {
            val k = ((t.value - p.delay) / (1f - p.delay)).coerceIn(0f, 1f)
            if (k <= 0f || k >= 1f) continue
            val y = -20f * d + k * p.speed * (size.height + 40f * d)
            val x = p.x * size.width + kotlin.math.sin(k * 9f + p.sway) * p.sway * d
            val c = Offset(x, y)
            rotate(p.spin * k, c) {
                drawRect(p.color.copy(alpha = 1f - k * 0.6f), c - Offset(p.size * d / 2, p.size * d / 4), Size(p.size * d, p.size * d / 2))
            }
        }
    }
}
