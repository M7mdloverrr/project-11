package io.github.m7mdloverrr.quran

import io.github.m7mdloverrr.quran.ui.PrayerScreen
import io.github.m7mdloverrr.quran.ui.QiblaScreen
import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import io.github.m7mdloverrr.quran.ui.DownloadsScreen
import io.github.m7mdloverrr.quran.ui.HomeScreen
import io.github.m7mdloverrr.quran.ui.QuranTheme
import io.github.m7mdloverrr.quran.ui.ReaderScreen
import io.github.m7mdloverrr.quran.ui.SettingsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            val vm: AppViewModel = viewModel()
            val settings by vm.settings.collectAsStateWithLifecycle()
            val dark = when (settings?.theme) {
                1 -> false
                2 -> true
                else -> isSystemInDarkTheme()
            }
            val notifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
            LaunchedEffect(Unit) {
                if (Build.VERSION.SDK_INT >= 33) notifications.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
            QuranTheme(dark, settings?.pageStyle ?: 0) {
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                    Surface(color = MaterialTheme.colorScheme.background) {
                        val nav = rememberNavController()
                        LaunchedEffect(Unit) {
                            if (intent?.getStringExtra("open") == "prayer") nav.navigate("prayer")
                        }
                        NavHost(nav, startDestination = "home") {
                            composable("home") {
                                HomeScreen(
                                    vm,
                                    openPage = { nav.navigate("reader/$it") },
                                    openSettings = { nav.navigate("settings") },
                                    openDownloads = { nav.navigate("downloads") },
                                    openPrayer = { nav.navigate("prayer") },
                                    openQibla = { nav.navigate("qibla") },
                                )
                            }
                            composable("reader/{page}", arguments = listOf(navArgument("page") { type = NavType.IntType })) {
                                ReaderScreen(vm, it.arguments?.getInt("page") ?: 1) { nav.popBackStack() }
                            }
                            composable("settings") { SettingsScreen(vm) { nav.popBackStack() } }
                            composable("downloads") { DownloadsScreen(vm) { nav.popBackStack() } }
                            composable("prayer") { PrayerScreen(vm, { nav.popBackStack() }) { nav.navigate("qibla") } }
                            composable("qibla") { QiblaScreen(vm) { nav.popBackStack() } }
                        }
                    }
                }
            }
        }
    }
}
