package io.github.m7mdloverrr.quran.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.MenuBook
import androidx.compose.material.icons.rounded.Bookmark
import androidx.compose.material.icons.rounded.BookmarkBorder
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Repeat
import androidx.compose.material.icons.rounded.SkipNext
import androidx.compose.material.icons.rounded.SkipPrevious
import androidx.compose.material.icons.rounded.TextDecrease
import androidx.compose.material.icons.rounded.TextIncrease
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.PlayingState
import io.github.m7mdloverrr.quran.data.Ayah
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.Settings
import io.github.m7mdloverrr.quran.data.ar
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged

private const val AYAH_MARK = "\u06DD"

@OptIn(ExperimentalMaterial3Api::class, FlowPreview::class)
@Composable
fun ReaderScreen(vm: AppViewModel, startPage: Int, onBack: () -> Unit) {
    val quran by vm.quran.collectAsStateWithLifecycle()
    val settings by vm.settings.collectAsStateWithLifecycle()
    val q = quran
    val st = settings
    if (q == null || st == null) {
        Loading()
        return
    }
    val playing by vm.playing.collectAsStateWithLifecycle()
    val message by vm.message.collectAsStateWithLifecycle()
    val listState = rememberLazyListState(initialFirstVisibleItemIndex = (startPage - 1).coerceIn(0, 603))
    var selected by remember { mutableStateOf<Ayah?>(null) }
    var navSheet by remember { mutableStateOf(false) }
    val positions = remember { HashMap<String, Float>() }
    val snackbar = remember { SnackbarHostState() }
    val page by remember { derivedStateOf { listState.firstVisibleItemIndex + 1 } }
    val pageFirst = q.pages[page - 1].first()

    LaunchedEffect(listState) {
        snapshotFlow { listState.firstVisibleItemIndex + 1 }.distinctUntilChanged().debounce(600).collect { vm.savePage(it) }
    }
    LaunchedEffect(playing.surah, playing.ayah) {
        if (playing.active) followAyah(q, playing, listState, positions)
    }
    LaunchedEffect(message) {
        val m = message ?: return@LaunchedEffect
        val r = snackbar.showSnackbar(m.text, actionLabel = if (m.retry) "إعادة المحاولة" else null, duration = SnackbarDuration.Long)
        if (r == SnackbarResult.ActionPerformed) vm.retry()
        vm.consumeMessage(m.id)
    }

    val target: Ayah? = if (playing.active) q.ayah(playing.surah, playing.ayah.coerceAtLeast(1)) else selected
    val currentKey = if (playing.active) "${playing.surah}:${playing.ayah}" else null

    Scaffold(
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(q.surah(pageFirst.surah).name, fontFamily = QuranFont, fontSize = 22.sp)
                        Text("الجزء ${pageFirst.juz.ar()} • الصفحة ${page.ar()}", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "رجوع") } },
                actions = {
                    IconButton(onClick = { vm.setFontSize(st.fontSize - 2) }, enabled = st.fontSize > 18) { Icon(Icons.Rounded.TextDecrease, "تصغير الخط") }
                    IconButton(onClick = { vm.setFontSize(st.fontSize + 2) }, enabled = st.fontSize < 44) { Icon(Icons.Rounded.TextIncrease, "تكبير الخط") }
                    IconButton(onClick = { navSheet = true }) { Icon(Icons.AutoMirrored.Rounded.MenuBook, "الفهرس") }
                },
            )
        },
        bottomBar = {
            AnimatedVisibility(target != null, enter = slideInVertically { it }, exit = slideOutVertically { it }) {
                target?.let { PlayerBar(vm, q, st, playing, it) }
            }
        },
    ) { pad ->
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize().padding(pad),
            contentPadding = PaddingValues(vertical = 8.dp),
        ) {
            items(q.pages.size, key = { it + 1 }) { i ->
                QuranPage(
                    q, i + 1, q.pages[i], st, currentKey, selected?.key.takeIf { !playing.active },
                    onTap = { a ->
                        selected = a
                        vm.play(a.surah, a.number)
                    },
                    onPositions = { positions.putAll(it) },
                )
            }
        }
    }

    if (navSheet) {
        ModalBottomSheet(onDismissRequest = { navSheet = false }) {
            var tab by remember { mutableIntStateOf(0) }
            var pageDialog by remember { mutableStateOf(false) }
            val go: (Int) -> Unit = { p -> navSheet = false; listStateScrollRequest(listState, p) }
            PrimaryTabRow(selectedTabIndex = tab) {
                listOf("السور", "الأجزاء", "صفحة").forEachIndexed { idx, t ->
                    Tab(selected = tab == idx, onClick = { if (idx == 2) pageDialog = true else tab = idx }, text = { Text(t) })
                }
            }
            Box(Modifier.height(480.dp)) {
                if (tab == 0) SurahList(q) { go(it.startPage) } else JuzList(q, go)
            }
            if (pageDialog) PageJumpDialog({ pageDialog = false }) { pageDialog = false; go(it) }
        }
    }
    LaunchedEffect(scrollRequest.intValue) {
        val p = scrollRequest.intValue
        if (p > 0) {
            listState.scrollToItem(p - 1)
            scrollRequest.intValue = 0
        }
    }
}

private val scrollRequest = mutableIntStateOf(0)

private fun listStateScrollRequest(@Suppress("UNUSED_PARAMETER") state: LazyListState, page: Int) {
    scrollRequest.intValue = page
}

private suspend fun followAyah(q: Quran, playing: PlayingState, state: LazyListState, positions: Map<String, Float>) {
    val ayah = q.ayah(playing.surah, playing.ayah.coerceAtLeast(1))
    val index = ayah.page - 1
    val key = if (playing.ayah == 0) "${playing.surah}:0" else ayah.key
    val info = state.layoutInfo
    val item = info.visibleItemsInfo.firstOrNull { it.index == index }
    val y = positions[key]
    if (item == null || y == null) {
        state.animateScrollToItem(index, (y ?: 0f).toInt().coerceAtLeast(0))
        return
    }
    val abs = item.offset + y
    val top = info.viewportStartOffset + 40
    val bottom = info.viewportEndOffset - (info.viewportEndOffset - info.viewportStartOffset) * 0.35f
    if (abs < top || abs > bottom) state.animateScrollToItem(index, y.toInt().coerceAtLeast(0) - 120)
}

@Composable
private fun QuranPage(
    q: Quran,
    pageNo: Int,
    ayahs: List<Ayah>,
    st: Settings,
    currentKey: String?,
    selectedKey: String?,
    onTap: (Ayah) -> Unit,
    onPositions: (Map<String, Float>) -> Unit,
) {
    val colors = LocalPageColors.current
    var root by remember { mutableStateOf<LayoutCoordinates?>(null) }
    Surface(
        Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp).onGloballyPositioned { root = it },
        shape = RoundedCornerShape(18.dp),
        color = colors.page,
        shadowElevation = 1.dp,
    ) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(q.surah(ayahs.first().surah).name, fontFamily = QuranFont, fontSize = 14.sp, color = colors.mark)
                Text("الجزء ${ayahs.first().juz.ar()}", fontSize = 12.sp, color = colors.mark)
            }
            var i = 0
            while (i < ayahs.size) {
                val s = ayahs[i].surah
                var j = i
                while (j < ayahs.size && ayahs[j].surah == s) j++
                val segment = ayahs.subList(i, j)
                if (segment.first().number == 1) {
                    SurahBanner(q.surah(s).name, q.surah(s).ayahs.size, q.surah(s).isMeccan)
                    if (q.surah(s).hasBasmala) {
                        val hl = currentKey == "$s:0"
                        Text(
                            q.basmala,
                            Modifier.fillMaxWidth()
                                .background(if (hl) colors.highlight else Color.Transparent, RoundedCornerShape(8.dp))
                                .onGloballyPositioned { c -> root?.let { r -> onPositions(mapOf("$s:0" to r.localPositionOf(c, androidx.compose.ui.geometry.Offset.Zero).y)) } },
                            fontFamily = QuranFont, fontSize = (st.fontSize * 0.95f).sp, color = colors.text, textAlign = TextAlign.Center,
                        )
                    }
                }
                AyahParagraph(segment, st, currentKey, selectedKey, root, onTap, onPositions)
                i = j
            }
            Text(
                pageNo.ar(),
                Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center, fontSize = 13.sp, color = colors.mark,
            )
        }
    }
}

@Composable
private fun SurahBanner(name: String, count: Int, meccan: Boolean) {
    Box(
        Modifier.fillMaxWidth().padding(vertical = 4.dp)
            .background(
                androidx.compose.ui.graphics.Brush.horizontalGradient(listOf(DarkGreen, Emerald, DarkGreen)),
                RoundedCornerShape(14.dp),
            )
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(name, fontFamily = QuranFont, fontSize = 24.sp, color = Color.White)
            Text("${if (meccan) "مكية" else "مدنية"} • ${count.ar()} آية", fontSize = 11.sp, color = Color.White.copy(alpha = 0.8f))
        }
    }
}

@Composable
private fun AyahParagraph(
    segment: List<Ayah>,
    st: Settings,
    currentKey: String?,
    selectedKey: String?,
    root: LayoutCoordinates?,
    onTap: (Ayah) -> Unit,
    onPositions: (Map<String, Float>) -> Unit,
) {
    val colors = LocalPageColors.current
    val tap by rememberUpdatedState(onTap)
    val starts = remember(segment) { IntArray(segment.size) }
    val text = remember(segment, currentKey, selectedKey, st.bookmarks, colors) {
        buildAnnotatedString {
            segment.forEachIndexed { idx, a ->
                starts[idx] = length
                val bg = when (a.key) {
                    currentKey -> colors.highlight
                    selectedKey -> colors.selected
                    else -> Color.Transparent
                }
                withStyle(SpanStyle(background = bg)) {
                    append(a.text)
                    append(' ')
                    withStyle(SpanStyle(color = if (a.key in st.bookmarks) Color(0xFFC9A227) else colors.mark)) {
                        append(AYAH_MARK + a.number.ar())
                    }
                }
                append(' ')
            }
        }
    }
    var layout by remember { mutableStateOf<TextLayoutResult?>(null) }
    Text(
        text,
        Modifier.fillMaxWidth().pointerInput(segment) {
            detectTapGestures { pos ->
                val l = layout ?: return@detectTapGestures
                val off = l.getOffsetForPosition(pos)
                val idx = starts.indexOfLast { it <= off }
                if (idx >= 0) tap(segment[idx])
            }
        }.onGloballyPositioned { c ->
            val l = layout ?: return@onGloballyPositioned
            val r = root ?: return@onGloballyPositioned
            val base = r.localPositionOf(c, androidx.compose.ui.geometry.Offset.Zero).y
            onPositions(segment.indices.associate { segment[it].key to base + l.getLineTop(l.getLineForOffset(starts[it])) })
        },
        style = TextStyle(
            fontFamily = QuranFont,
            fontSize = st.fontSize.sp,
            lineHeight = (st.fontSize * 2.05f).sp,
            textAlign = TextAlign.Justify,
            textDirection = TextDirection.Rtl,
            color = colors.text,
        ),
        onTextLayout = { layout = it },
    )
}

@Composable
private fun PlayerBar(vm: AppViewModel, q: Quran, st: Settings, playing: PlayingState, target: Ayah) {
    Surface(color = MaterialTheme.colorScheme.primaryContainer, shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp), shadowElevation = 8.dp) {
        Column(Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 12.dp, vertical = 8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f).padding(horizontal = 8.dp)) {
                    Text(
                        if (playing.active && playing.ayah == 0) "${q.surah(target.surah).name} • البسملة"
                        else "${q.surah(target.surah).name} • الآية ${target.number.ar()}",
                        style = MaterialTheme.typography.titleSmall,
                    )
                    Text(st.reciter.nameAr, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = { vm.toggleBookmark(target.key) }) {
                    Icon(if (target.key in st.bookmarks) Icons.Rounded.Bookmark else Icons.Rounded.BookmarkBorder, "علامة")
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically) {
                AssistChip(
                    onClick = {
                        val opts = listOf(1, 2, 3, 5, 0)
                        vm.setRepeat(opts[(opts.indexOf(st.repeat).coerceAtLeast(0) + 1) % opts.size])
                    },
                    label = { Text(if (st.repeat <= 0) "∞" else "×${st.repeat.ar()}") },
                    leadingIcon = { Icon(Icons.Rounded.Repeat, "تكرار الآية", Modifier.size(18.dp)) },
                    colors = AssistChipDefaults.assistChipColors(),
                )
                IconButton(onClick = { vm.step(target.surah, target.number, -1) }) {
                    Icon(Icons.Rounded.SkipPrevious, "الآية السابقة", Modifier.graphicsLayer(scaleX = -1f))
                }
                FilledIconButton(
                    onClick = { vm.togglePlay(target.surah, target.number) },
                    modifier = Modifier.size(56.dp),
                    shape = CircleShape,
                    colors = IconButtonDefaults.filledIconButtonColors(containerColor = MaterialTheme.colorScheme.primary),
                ) {
                    when {
                        playing.buffering -> CircularProgressIndicator(Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp)
                        playing.isPlaying -> Icon(Icons.Rounded.Pause, "إيقاف مؤقت", Modifier.size(32.dp))
                        else -> Icon(Icons.Rounded.PlayArrow, "تشغيل", Modifier.size(32.dp))
                    }
                }
                IconButton(onClick = { vm.step(target.surah, target.number, 1) }) {
                    Icon(Icons.Rounded.SkipNext, "الآية التالية", Modifier.graphicsLayer(scaleX = -1f))
                }
                TextButton(onClick = {
                    val opts = listOf(0.75f, 1f, 1.25f, 1.5f, 2f)
                    vm.setSpeed(opts[(opts.indexOf(st.speed).coerceAtLeast(0) + 1) % opts.size])
                }) { Text("${st.speed}x") }
            }
        }
    }
}
