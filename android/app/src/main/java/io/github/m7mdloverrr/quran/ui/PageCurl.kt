package io.github.m7mdloverrr.quran.ui

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Matrix
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.zIndex
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.sin

/** Shown page and the running page turn: [dir] 1 = turning [index] away to the next page, -1 = laying the previous page back over [index]. */
class CurlState(initial: Int) {
    var index by mutableIntStateOf(initial)
    var dir by mutableIntStateOf(0)
    /** How far the top page is turned: 0 flat, 1 fully turned over. */
    var p by mutableFloatStateOf(0f)

    suspend fun turnTo(target: Int, count: Int) {
        if (target == index || dir != 0 || target !in 0 until count) return
        when (target) {
            index + 1 -> { dir = 1; run(0f, 1f) { index = target } }
            index - 1 -> { dir = -1; run(1f, 0f) { index = target } }
            else -> index = target
        }
    }

    internal suspend fun run(from: Float, to: Float, ms: Int = 950, done: () -> Unit) {
        try {
            animate(from, to, animationSpec = tween(ms, easing = FastOutSlowInEasing)) { v, _ -> p = v }
            done()
        } finally {
            dir = 0
        }
    }
}

private class Fold(val m: Offset, val n: Offset)

/** The lifted corner (bottom left in RTL) is pulled across the page; the fold is the perpendicular bisector. */
private fun fold(size: Size, p: Float, rtl: Boolean): Fold {
    val w = size.width
    val h = size.height
    val c = Offset(if (rtl) 0f else w, h)
    val travel = p * 2f * w
    val target = Offset(if (rtl) travel else w - travel, h - sin(p * PI).toFloat() * h * 0.22f)
    val v = target - c
    val len = v.getDistance().coerceAtLeast(0.001f)
    return Fold((c + target) / 2f, v / len)
}

/** Half-plane on the corner side of the fold (keep = false) or on the far side (keep = true). */
private fun half(f: Fold, keep: Boolean, big: Float): Path {
    val d = Offset(-f.n.y, f.n.x)
    val o = f.n * (if (keep) big else -big)
    val a = f.m + d * big
    val b = f.m - d * big
    return Path().apply {
        moveTo(a.x, a.y); lineTo(b.x, b.y); lineTo(b.x + o.x, b.y + o.y); lineTo(a.x + o.x, a.y + o.y); close()
    }
}

private fun reflection(f: Fold): Matrix {
    val dx = -f.n.y
    val dy = f.n.x
    val a = dx * dx - dy * dy
    val b = 2 * dx * dy
    return Matrix(floatArrayOf(a, b, 0f, 0f, b, -a, 0f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 0f, 1f))
}

private fun ContentDrawScope.curlTop(p: Float, rtl: Boolean, paper: Color) {
    if (p <= 0.002f) { drawContent(); return }
    if (p >= 0.998f) return
    val f = fold(size, p, rtl)
    val big = (size.width + size.height) * 3f
    clipPath(half(f, true, big)) { this@curlTop.drawContent() }
    val m = f.m
    val sw = size.width * (0.18f + 0.25f * (1f - p))
    withTransform({
        translate(m.x, m.y); transform(reflection(f)); translate(-m.x, -m.y)
        clipPath(half(f, false, big))
    }) {
        this@curlTop.drawContent()
        drawRect(paper.copy(alpha = 0.9f))
        drawRect(
            Brush.linearGradient(
                0f to Color.Black.copy(alpha = 0.28f), 0.18f to Color.White.copy(alpha = 0.22f), 0.55f to Color.Transparent,
                start = m, end = m - f.n * sw,
            ),
        )
    }
    val edge = sin(p * PI).toFloat()
    clipPath(half(f, true, big)) {
        drawRect(
            Brush.linearGradient(listOf(Color.Black.copy(alpha = 0.18f * edge), Color.Transparent), start = m, end = m + f.n * (sw * 0.15f)),
        )
    }
}

private fun ContentDrawScope.curlBottom(p: Float, rtl: Boolean) {
    drawContent()
    if (p <= 0.002f || p >= 0.998f) return
    val f = fold(size, p, rtl)
    val big = (size.width + size.height) * 3f
    val k = sin(p * PI).toFloat()
    clipPath(half(f, false, big)) {
        drawRect(Brush.linearGradient(listOf(Color.Black.copy(alpha = 0.45f * k), Color.Transparent), start = f.m, end = f.m - f.n * (size.width * 0.22f)))
    }
}

/** Book-like pager: pages curl over from the corner instead of sliding. Swipe towards the spine side to turn. */
@Composable
fun CurlPager(state: CurlState, count: Int, modifier: Modifier, rtl: Boolean, paper: Color, page: @Composable (Int) -> Unit) {
    val scope = rememberCoroutineScope()
    Box(
        modifier.pointerInput(count, rtl) {
            var dragging = false
            detectHorizontalDragGestures(
                onDragStart = { dragging = false },
                onDragEnd = {
                    if (!dragging) return@detectHorizontalDragGestures
                    val from = state.p
                    scope.launch {
                        if (state.dir == 1) { if (from > 0.3f) state.run(from, 1f, 450) { state.index++ } else state.run(from, 0f, 300) {} }
                        else if (state.dir == -1) { if (from < 0.7f) state.run(from, 0f, 450) { state.index-- } else state.run(from, 1f, 300) {} }
                    }
                },
                onDragCancel = { state.dir = 0 },
            ) { change, dx ->
                val fwd = if (rtl) dx else -dx
                if (!dragging) {
                    if (state.dir != 0) return@detectHorizontalDragGestures
                    if (fwd > 0 && state.index < count - 1) { state.dir = 1; state.p = 0f }
                    else if (fwd < 0 && state.index > 0) { state.dir = -1; state.p = 1f }
                    else return@detectHorizontalDragGestures
                    dragging = true
                }
                change.consume()
                state.p = (state.p + fwd / (size.width * 1.6f)).coerceIn(0f, 1f)
            }
        },
    ) {
        val i = state.index.coerceIn(0, (count - 1).coerceAtLeast(0))
        val (bottom, top) = when (state.dir) {
            1 -> (i + 1).coerceAtMost(count - 1) to i
            -1 -> i to (i - 1).coerceAtLeast(0)
            else -> -1 to i
        }
        if (bottom >= 0) key(bottom) {
            Box(Modifier.fillMaxSize().zIndex(0f).drawWithContent { curlBottom(state.p, rtl) }) { page(bottom) }
        }
        key(top) {
            Box(Modifier.fillMaxSize().zIndex(1f).drawWithContent { if (state.dir == 0) drawContent() else curlTop(state.p, rtl, paper) }) { page(top) }
        }
    }
}
