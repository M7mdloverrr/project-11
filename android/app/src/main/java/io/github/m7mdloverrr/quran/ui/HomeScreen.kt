package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.shown

import androidx.compose.material3.Surface
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.Explore
import androidx.compose.material.icons.rounded.Movie
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.ui.graphics.vector.ImageVector
import io.github.m7mdloverrr.quran.prayer.PrayerCalc
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.MenuBook
import androidx.compose.material.icons.rounded.BookmarkRemove
import androidx.compose.material.icons.rounded.CloudDownload
import androidx.compose.material.icons.rounded.Numbers
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.Settings
import io.github.m7mdloverrr.quran.data.ar

@Composable
fun Loading() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
}

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    vm: AppViewModel,
    openPage: (Int) -> Unit,
    openSettings: () -> Unit,
    openDownloads: () -> Unit,
    openPrayer: () -> Unit,
    openQibla: () -> Unit,
    openStudio: () -> Unit,
    openTasmee: () -> Unit,
) {
    val quran by vm.quran.collectAsStateWithLifecycle()
    val settings by vm.settings.collectAsStateWithLifecycle()
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var jump by remember { mutableStateOf(false) }
    Scaffold(containerColor = Color.Transparent, 
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("القرآن الكريم", fontFamily = QuranFont, fontSize = 28.sp) },
                navigationIcon = { IconButton(onClick = openDownloads) { Icon(Icons.Rounded.CloudDownload, "التحميلات") } },
                actions = {
                    IconButton(onClick = { jump = true }) { Icon(Icons.Rounded.Numbers, "الانتقال إلى صفحة") }
                    IconButton(onClick = openSettings) { Icon(Icons.Rounded.Settings, "الإعدادات") }
                },
            )
        },
    ) { pad ->
        val q = quran
        val st = settings
        if (q == null || st == null) {
            Box(Modifier.padding(pad)) { Loading() }
            return@Scaffold
        }
        LazyColumn(Modifier.padding(pad).fillMaxSize(), contentPadding = PaddingValues(bottom = 24.dp)) {
            item(key = "continue") { ContinueCard(q, st, openPage) }
            item(key = "quick") {
                Row(Modifier.padding(start = 16.dp, end = 16.dp, bottom = 8.dp).fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    val lat = st.lat
                    val lon = st.lon
                    val sub = if (lat != null && lon != null) {
                        val (i, t) = PrayerCalc.next(lat, lon, st.prayerMethod, st.madhab)
                        "${PrayerCalc.names[i]} ${prayerTime(t)}"
                    } else "حدّد موقعك"
                    QuickCard("مواقيت الصلاة", sub, Icons.Rounded.AccessTime, Modifier.weight(1f), openPrayer)
                    QuickCard("القبلة", "البوصلة", Icons.Rounded.Explore, Modifier.weight(1f), openQibla)
                }
            }
            item(key = "studio") {
                QuickCard("استوديو الفيديو", "اصنع فيديو تلاوة بخلفية طبيعية", Icons.Rounded.Movie, Modifier.padding(start = 16.dp, end = 16.dp, bottom = 8.dp).fillMaxWidth(), openStudio)
            }
            item(key = "tasmee") {
                QuickCard("التسميع", "سمّع حفظك ويصحّح لك التطبيق كلمةً كلمة", Icons.Rounded.Mic, Modifier.padding(start = 16.dp, end = 16.dp, bottom = 8.dp).fillMaxWidth(), openTasmee)
            }
            stickyHeader(key = "tabs") {
                PrimaryTabRow(selectedTabIndex = tab, containerColor = MaterialTheme.colorScheme.background) {
                    listOf("السور", "الأجزاء", "العلامات").forEachIndexed { i, t ->
                        Tab(selected = tab == i, onClick = { tab = i }, text = { Text(t) })
                    }
                }
            }
            when (tab) {
                0 -> surahItems(q) { openPage(it.startPage) }
                1 -> juzItems(q, openPage)
                else -> bookmarkItems(q, st, openPage) { vm.toggleBookmark(it) }
            }
        }
    }
    if (jump) PageJumpDialog({ jump = false }) { jump = false; openPage(it) }
}

@Composable
private fun QuickCard(title: String, sub: String, icon: ImageVector, modifier: Modifier, onClick: () -> Unit) {
    Surface(onClick = onClick, modifier = modifier, shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainerHigh) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(icon, null, tint = MaterialTheme.colorScheme.primary)
            Column {
                Text(title, style = MaterialTheme.typography.titleSmall)
                Text(sub, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
            }
        }
    }
}

@Composable
private fun ContinueCard(q: Quran, st: Settings, openPage: (Int) -> Unit) {
    val page = st.lastPage.coerceIn(1, 604)
    val first = q.pages[page - 1].first()
    val hasHistory = st.lastPage > 0
    Box(
        Modifier
            .padding(16.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Brush.linearGradient(listOf(DarkGreen, Emerald)))
            .clickable { openPage(page) }
            .padding(20.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(if (hasHistory) "متابعة القراءة" else "ابدأ القراءة", color = Color.White.copy(alpha = 0.8f), style = MaterialTheme.typography.labelLarge)
            Text(q.surah(first.surah).name, color = Color.White, fontFamily = QuranFont, fontSize = 26.sp)
            Text(
                "الجزء ${first.juz.ar()} • الصفحة ${page.ar()} • ${st.reciter.nameAr}",
                color = Color.White.copy(alpha = 0.85f), style = MaterialTheme.typography.bodyMedium,
            )
            Spacer(Modifier.height(4.dp))
            Button(
                onClick = { openPage(page) },
                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = DarkGreen),
            ) {
                Icon(Icons.AutoMirrored.Rounded.MenuBook, null)
                Text("  افتح المصحف")
            }
        }
    }
}

private fun LazyListScope.bookmarkItems(q: Quran, st: Settings, openPage: (Int) -> Unit, remove: (String) -> Unit) {
    val list = st.bookmarks.mapNotNull { q.ayahOrNull(it) }.sortedWith(compareBy({ it.surah }, { it.number }))
    if (list.isEmpty()) item(key = "empty") {
        Text(
            "لا توجد علامات بعد.\nاضغط على أي آية في المصحف ثم على رمز العلامة.",
            Modifier.fillMaxWidth().padding(32.dp),
            textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
    items(list, key = { it.key }) { a ->
        Row(
            Modifier.fillMaxWidth().clickable { openPage(a.page) }.padding(start = 16.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text("${q.surah(a.surah).name} • الآية ${a.number.ar()}", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                Text(a.shown, fontFamily = AyahFont, fontSize = 18.sp, maxLines = 1)
            }
            IconButton(onClick = { remove(a.key) }) { Icon(Icons.Rounded.BookmarkRemove, "حذف العلامة") }
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
    }
}
