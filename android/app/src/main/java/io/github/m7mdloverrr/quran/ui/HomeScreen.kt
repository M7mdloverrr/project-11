package io.github.m7mdloverrr.quran.ui

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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(vm: AppViewModel, openPage: (Int) -> Unit, openSettings: () -> Unit, openDownloads: () -> Unit) {
    val quran by vm.quran.collectAsStateWithLifecycle()
    val settings by vm.settings.collectAsStateWithLifecycle()
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var jump by remember { mutableStateOf(false) }
    Scaffold(
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
        Column(Modifier.padding(pad)) {
            ContinueCard(q, st, openPage)
            PrimaryTabRow(selectedTabIndex = tab, containerColor = MaterialTheme.colorScheme.background) {
                listOf("السور", "الأجزاء", "العلامات").forEachIndexed { i, t ->
                    Tab(selected = tab == i, onClick = { tab = i }, text = { Text(t) })
                }
            }
            when (tab) {
                0 -> SurahList(q) { openPage(it.startPage) }
                1 -> JuzList(q, openPage)
                else -> Bookmarks(q, st, openPage) { vm.toggleBookmark(it) }
            }
        }
    }
    if (jump) PageJumpDialog({ jump = false }) { jump = false; openPage(it) }
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

@Composable
private fun Bookmarks(q: Quran, st: Settings, openPage: (Int) -> Unit, remove: (String) -> Unit) {
    val list = st.bookmarks.mapNotNull { q.ayahOrNull(it) }.sortedWith(compareBy({ it.surah }, { it.number }))
    if (list.isEmpty()) {
        Text(
            "لا توجد علامات بعد.\nاضغط على أي آية في المصحف ثم على رمز العلامة.",
            Modifier.fillMaxWidth().padding(32.dp),
            textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        return
    }
    LazyColumn(contentPadding = PaddingValues(bottom = 24.dp)) {
        items(list, key = { it.key }) { a ->
            Row(
                Modifier.fillMaxWidth().clickable { openPage(a.page) }.padding(start = 16.dp, top = 10.dp, bottom = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("${q.surah(a.surah).name} • الآية ${a.number.ar()}", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                    Text(a.text, fontFamily = QuranFont, fontSize = 18.sp, maxLines = 1)
                }
                IconButton(onClick = { remove(a.key) }) { Icon(Icons.Rounded.BookmarkRemove, "حذف العلامة") }
            }
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
        }
    }
}
