package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.*

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Fullscreen
import androidx.compose.material.icons.rounded.FullscreenExit
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

private tailrec fun Context.activityOf(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.activityOf()
    else -> null
}

/** Hides the status and navigation bars while [on]; a swipe from the edge shows them briefly. */
@Composable
fun FullScreenEffect(on: Boolean) {
    val view = LocalView.current
    DisposableEffect(on) {
        val c = view.context.activityOf()?.window?.let { WindowCompat.getInsetsController(it, view) }
        if (on) {
            c?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            c?.hide(WindowInsetsCompat.Type.systemBars())
        }
        onDispose { if (on) c?.show(WindowInsetsCompat.Type.systemBars()) }
    }
}

@Composable
fun FullScreenAction(onClick: () -> Unit) =
    IconButton(onClick = onClick) { Icon(Icons.Rounded.Fullscreen, TR("ملء الشاشة", "Vollbild")) }

@Composable
fun ExitFullScreenButton(onExit: () -> Unit) = SmallFloatingActionButton(
    onClick = onExit,
    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.75f),
    contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
    elevation = FloatingActionButtonDefaults.elevation(0.dp, 0.dp, 0.dp, 0.dp),
) { Icon(Icons.Rounded.FullscreenExit, TR("الخروج من ملء الشاشة", "Vollbild beenden")) }

/** Thin top row holding only the exit button, so it never covers the page or the controls. */
@Composable
fun ExitFullScreenBar(onExit: () -> Unit) =
    Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp), horizontalArrangement = Arrangement.End) {
        ExitFullScreenButton(onExit)
    }
