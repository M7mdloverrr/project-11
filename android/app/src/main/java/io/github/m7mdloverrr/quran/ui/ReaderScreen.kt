package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.*

import io.github.m7mdloverrr.quran.data.Scripts
import io.github.m7mdloverrr.quran.data.shown
import io.github.m7mdloverrr.quran.data.shownBasmala

import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.staticCompositionLocalOf
import io.github.m7mdloverrr.quran.data.Prefs
import io.github.m7mdloverrr.quran.data.Tafsirs

import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import io.github.m7mdloverrr.quran.data.GermanRepository
import androidx.compose.ui.platform.LocalView
import androidx.activity.compose.LocalActivity
import androidx.activity.compose.BackHandler
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
    val curl = remember { CurlState((startPage - 1).coerceIn(0, 603)) }
    var selected by remember { mutableStateOf<Ayah?>(null) }
    var navSheet by remember { mutableStateOf(false) }
    var tafsirAyah by remember { mutableStateOf<Ayah?>(null) }
    val onLongPress = remember { { a: Ayah -> tafsirAyah = a } }
    val positions = remember { HashMap<String, Float>() }
    val snackbar = remember { SnackbarHostState() }
    val page by remember(st.pageFlip) { derivedStateOf { if (st.pageFlip) curl.index + 1 else listState.firstVisibleItemIndex + 1 } }
    val pageFirst = q.pages[page - 1].first()
    val ctx = LocalContext.current
    val german by produceState<List<List<String>>?>(null, st.germanMode != 0) {
        if (st.germanMode != 0) value = GermanRepository.load(ctx)
    }

    val view = LocalView.current
    DisposableEffect(st.keepScreenOn) {
        view.keepScreenOn = st.keepScreenOn
        onDispose { view.keepScreenOn = false }
    }
    val activity = LocalActivity.current
    val keepPlaying by rememberUpdatedState(st.backgroundPlay)
    DisposableEffect(Unit) {
        onDispose { if (!keepPlaying && activity?.isChangingConfigurations != true) vm.stop() }
    }

    LaunchedEffect(listState, st.pageFlip) {
        snapshotFlow { if (st.pageFlip) curl.index + 1 else listState.firstVisibleItemIndex + 1 }.distinctUntilChanged().debounce(600).collect { vm.savePage(it) }
    }
    LaunchedEffect(playing.surah, playing.ayah) {
        if (playing.active && st.follow) {
            if (st.pageFlip) curl.turnTo(q.ayah(playing.surah, playing.ayah.coerceAtLeast(1)).page - 1, q.pages.size)
            else followAyah(q, playing, listState, positions)
        }
    }
    LaunchedEffect(message) {
        val m = message ?: return@LaunchedEffect
        val r = snackbar.showSnackbar(m.text, actionLabel = if (m.retry) TR("إعادة المحاولة", "Erneut versuchen") else null, duration = SnackbarDuration.Long)
        if (r == SnackbarResult.ActionPerformed) vm.retry()
        vm.consumeMessage(m.id)
    }

    val target: Ayah? = if (playing.active) q.ayah(playing.surah, playing.ayah.coerceAtLeast(1)) else selected
    val currentKey = if (playing.active) "${playing.surah}:${playing.ayah}" else null

    var full by remember { mutableStateOf(false) }
    FullScreenEffect(full)
    BackHandler(full) { full = false }
    Scaffold(
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            if (full) ExitFullScreenBar { full = false } else TopAppBar(
                title = {
                    Column {
                        Text(q.surah(pageFirst.surah).title, fontFamily = NameFont, fontSize = 22.sp)
                        Text(TR("الجزء ${pageFirst.juz.ar()} • الصفحة ${page.ar()}", "Teil ${pageFirst.juz.ar()} • Seite ${page.ar()}"), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, TR("رجوع", "Zurück")) } },
                actions = {
                    IconButton(onClick = { vm.setFontSize(st.fontSize - 2) }, enabled = st.fontSize > 18) { Icon(Icons.Rounded.TextDecrease, TR("تصغير الخط", "Schrift verkleinern")) }
                    IconButton(onClick = { vm.setFontSize(st.fontSize + 2) }, enabled = st.fontSize < 44) { Icon(Icons.Rounded.TextIncrease, TR("تكبير الخط", "Schrift vergrößern")) }
                    FullScreenAction { full = true }
                    IconButton(onClick = { navSheet = true }) { Icon(Icons.AutoMirrored.Rounded.MenuBook, TR("الفهرس", "Inhalt")) }
                },
            )
        },
        bottomBar = {
            AnimatedVisibility(target != null, enter = slideInVertically { it }, exit = slideOutVertically { it }) {
                target?.let {
                    val de = if (st.germanMode == 1 && !(playing.active && playing.ayah == 0)) german?.getOrNull(it.surah - 1)?.getOrNull(it.number - 1) else null
                    PlayerBar(vm, q, st, playing, it, de)
                }
            }
        },
    ) { pad ->
        CompositionLocalProvider(LocalAyahLongPress provides onLongPress) {
        val pageAt: @Composable (Int, Boolean) -> Unit = { i, fill -> CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
            QuranPage(
                q, i + 1, q.pages[i], st, currentKey, selected?.key.takeIf { !playing.active }, if (st.germanMode == 2) german else null,
                onTap = { a ->
                    selected = a
                    vm.play(a.surah, a.number)
                },
                onPositions = { if (!fill) positions.putAll(it) },
                fill = fill,
            )
        } }
        if (st.pageFlip) {
            LaunchedEffect(Unit) { curl.index = listState.firstVisibleItemIndex }
            CurlPager(
                curl, q.pages.size,
                Modifier.fillMaxSize().padding(pad).padding(horizontal = 10.dp, vertical = 6.dp),
                true,
                LocalPageColors.current.page,
            ) { i -> pageAt(i, true) }
        } else {
            LaunchedEffect(Unit) { if (listState.firstVisibleItemIndex != curl.index) listState.scrollToItem(curl.index) }
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize().padding(pad),
                contentPadding = PaddingValues(vertical = 8.dp),
            ) {
                items(q.pages.size, key = { it + 1 }) { i -> pageAt(i, false) }
            }
        }
        }
    }

    tafsirAyah?.let { a ->
        ModalBottomSheet(onDismissRequest = { tafsirAyah = null }) { TafsirSheet(vm, q, a, st) }
    }

    if (navSheet) {
        ModalBottomSheet(onDismissRequest = { navSheet = false }) {
            var tab by remember { mutableIntStateOf(0) }
            var pageDialog by remember { mutableStateOf(false) }
            val go: (Int) -> Unit = { p -> navSheet = false; listStateScrollRequest(listState, p) }
            PrimaryTabRow(selectedTabIndex = tab) {
                listOf(TR("السور", "Suren"), TR("الأجزاء", "Teile"), TR("صفحة", "Seite")).forEachIndexed { idx, t ->
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
            if (st.pageFlip) curl.index = p - 1 else listState.scrollToItem(p - 1)
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
    split: List<List<String>>?,
    onTap: (Ayah) -> Unit,
    onPositions: (Map<String, Float>) -> Unit,
    fill: Boolean = false,
) {
    val colors = LocalPageColors.current
    var root by remember { mutableStateOf<LayoutCoordinates?>(null) }
    Surface(
        (if (fill) Modifier.fillMaxSize() else Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp)).onGloballyPositioned { root = it },
        shape = RoundedCornerShape(18.dp),
        color = colors.page,
        shadowElevation = 1.dp,
    ) {
        Column((if (fill) Modifier.verticalScroll(rememberScrollState()) else Modifier).padding(horizontal = 16.dp, vertical = 14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(q.surah(ayahs.first().surah).name, fontFamily = QuranFont, fontSize = 14.sp, color = colors.mark)
                Text(TR("الجزء ${ayahs.first().juz.ar()}", "Teil ${ayahs.first().juz.ar()}"), fontSize = 12.sp, color = colors.mark)
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
                            q.shownBasmala,
                            Modifier.fillMaxWidth()
                                .background(if (hl) colors.highlight else Color.Transparent, RoundedCornerShape(8.dp))
                                .onGloballyPositioned { c -> root?.let { r -> onPositions(mapOf("$s:0" to r.localPositionOf(c, androidx.compose.ui.geometry.Offset.Zero).y)) } },
                            fontFamily = AyahFont, fontSize = (st.fontSize * 0.95f).sp, color = colors.text, textAlign = TextAlign.Center,
                        )
                    }
                }
                if (split != null || st.tafsirUnder) segment.forEach { a ->
                    AyahParagraph(listOf(a), st, currentKey, selectedKey, root, onTap, onPositions)
                    if (split != null) GermanText(split.getOrNull(a.surah - 1)?.getOrNull(a.number - 1).orEmpty())
                    if (st.tafsirUnder) TafsirText(a, st.tafsir)
                } else AyahParagraph(segment, st, currentKey, selectedKey, root, onTap, onPositions)
                i = j
            }
            Text(
                pageNo.arq(),
                Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center, fontSize = 13.sp, color = colors.mark,
            )
        }
    }
}

@Composable
private fun TafsirText(a: Ayah, index: Int) {
    val ctx = LocalContext.current
    val colors = LocalPageColors.current
    val text by produceState<String?>(null, a.key, index) {
        value = runCatching { Tafsirs.text(ctx, index, a.surah, a.number) }.getOrDefault("")
    }
    val t = text?.takeIf { it.isNotBlank() } ?: return
    Text(
        t,
        Modifier.fillMaxWidth().padding(bottom = 6.dp).background(colors.selected, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp, vertical = 6.dp),
        fontSize = 15.sp, lineHeight = 25.sp, color = colors.text.copy(alpha = 0.8f),
    )
}

@Composable
private fun GermanText(text: String, modifier: Modifier = Modifier) {
    val colors = LocalPageColors.current
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Text(text, modifier.fillMaxWidth().padding(bottom = 6.dp), fontSize = 15.sp, lineHeight = 21.sp, color = colors.text.copy(alpha = 0.78f))
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
            Text("${if (meccan) "مكية" else "مدنية"} • ${count.arq()} آية", fontSize = 11.sp, color = Color.White.copy(alpha = 0.8f))
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
    val longPress by rememberUpdatedState(LocalAyahLongPress.current)
    val starts = remember(segment) { IntArray(segment.size) }
    val text = remember(segment, currentKey, selectedKey, st.bookmarks, colors, Scripts.texts) {
        buildAnnotatedString {
            segment.forEachIndexed { idx, a ->
                starts[idx] = length
                val bg = when (a.key) {
                    currentKey -> colors.highlight
                    selectedKey -> colors.selected
                    else -> Color.Transparent
                }
                withStyle(SpanStyle(background = bg)) {
                    append(a.shown)
                    append(' ')
                    withStyle(SpanStyle(color = if (a.key in st.bookmarks) Color(0xFFC9A227) else colors.mark)) {
                        append((if (Scripts.index == 0) "" else AYAH_MARK) + a.number.arq())
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
            fun ayahAt(pos: androidx.compose.ui.geometry.Offset): Ayah? {
                val l = layout ?: return null
                val off = l.getOffsetForPosition(pos)
                return segment.getOrNull(starts.indexOfLast { it <= off })
            }
            detectTapGestures(onLongPress = { pos -> ayahAt(pos)?.let(longPress) }) { pos -> ayahAt(pos)?.let(tap) }
        }.onGloballyPositioned { c ->
            val l = layout ?: return@onGloballyPositioned
            val r = root ?: return@onGloballyPositioned
            val base = r.localPositionOf(c, androidx.compose.ui.geometry.Offset.Zero).y
            onPositions(segment.indices.associate { segment[it].key to base + l.getLineTop(l.getLineForOffset(starts[it])) })
        },
        style = TextStyle(
            fontFamily = AyahFont,
            fontSize = st.fontSize.sp,
            lineHeight = (st.fontSize * st.lineSpacing).sp,
            textAlign = TextAlign.Justify,
            textDirection = TextDirection.Rtl,
            color = colors.text,
        ),
        onTextLayout = { layout = it },
    )
}

@Composable
private fun PlayerBar(vm: AppViewModel, q: Quran, st: Settings, playing: PlayingState, target: Ayah, german: String?) {
    Surface(color = MaterialTheme.colorScheme.primaryContainer, shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp), shadowElevation = 8.dp) {
        Column(Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 12.dp, vertical = 8.dp)) {
            if (german != null) {
                Surface(color = LocalPageColors.current.page, shape = RoundedCornerShape(14.dp), modifier = Modifier.padding(bottom = 8.dp)) {
                    GermanText(german, Modifier.heightIn(max = 150.dp).verticalScroll(rememberScrollState()).padding(horizontal = 12.dp, vertical = 8.dp))
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f).padding(horizontal = 8.dp)) {
                    Text(
                        if (playing.active && playing.ayah == 0) "${q.surah(target.surah).title} • ${TR("البسملة", "Basmala")}"
                        else "${q.surah(target.surah).title} • ${TR("الآية", "Vers")} ${target.number.ar()}",
                        style = MaterialTheme.typography.titleSmall,
                    )
                    Text(st.reciter.label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = { vm.toggleBookmark(target.key) }) {
                    Icon(if (target.key in st.bookmarks) Icons.Rounded.Bookmark else Icons.Rounded.BookmarkBorder, TR("علامة", "Lesezeichen"))
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically) {
                AssistChip(
                    onClick = {
                        val opts = listOf(1, 2, 3, 5, 0)
                        vm.setRepeat(opts[(opts.indexOf(st.repeat).coerceAtLeast(0) + 1) % opts.size])
                    },
                    label = { Text(if (st.repeat <= 0) "∞" else "×${st.repeat.ar()}") },
                    leadingIcon = { Icon(Icons.Rounded.Repeat, TR("تكرار الآية", "Vers wiederholen"), Modifier.size(18.dp)) },
                    colors = AssistChipDefaults.assistChipColors(),
                )
                IconButton(onClick = { vm.step(target.surah, target.number, -1) }) {
                    Icon(Icons.Rounded.SkipPrevious, TR("الآية السابقة", "Vorheriger Vers"), Modifier.graphicsLayer(scaleX = -1f))
                }
                FilledIconButton(
                    onClick = { vm.togglePlay(target.surah, target.number) },
                    modifier = Modifier.size(56.dp),
                    shape = CircleShape,
                    colors = IconButtonDefaults.filledIconButtonColors(containerColor = MaterialTheme.colorScheme.primary),
                ) {
                    when {
                        playing.buffering -> CircularProgressIndicator(Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp)
                        playing.isPlaying -> Icon(Icons.Rounded.Pause, TR("إيقاف مؤقت", "Pause"), Modifier.size(32.dp))
                        else -> Icon(Icons.Rounded.PlayArrow, TR("تشغيل", "Abspielen"), Modifier.size(32.dp))
                    }
                }
                IconButton(onClick = { vm.step(target.surah, target.number, 1) }) {
                    Icon(Icons.Rounded.SkipNext, TR("الآية التالية", "Nächster Vers"), Modifier.graphicsLayer(scaleX = -1f))
                }
                TextButton(onClick = {
                    val opts = listOf(0.75f, 1f, 1.25f, 1.5f, 2f)
                    vm.setSpeed(opts[(opts.indexOf(st.speed).coerceAtLeast(0) + 1) % opts.size])
                }) { Text("${st.speed}x") }
            }
        }
    }
}

private val LocalAyahLongPress = staticCompositionLocalOf<(Ayah) -> Unit> { {} }

@Composable
private fun TafsirSheet(vm: AppViewModel, q: Quran, a: Ayah, st: Settings) {
    val ctx = LocalContext.current
    var retry by remember { mutableIntStateOf(0) }
    val result by produceState<Result<String>?>(null, a.key, st.tafsir, retry) {
        value = null
        value = runCatching { Tafsirs.text(ctx, st.tafsir, a.surah, a.number) }
    }
    Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 24.dp)) {
        Text("${q.surah(a.surah).title} • ${TR("الآية", "Vers")} ${a.number.ar()}", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
        Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(vertical = 8.dp)) {
            Tafsirs.all.forEachIndexed { i, t ->
                FilterChip(st.tafsir == i, { vm.setPref(Prefs.Keys.tafsir, i) }, { Text(t.nameAr) }, Modifier.padding(end = 6.dp))
            }
        }
        Column(Modifier.fillMaxWidth().heightIn(max = 520.dp).verticalScroll(rememberScrollState())) {
            Text(a.shown, fontFamily = AyahFont, fontSize = 22.sp, lineHeight = 40.sp, color = MaterialTheme.colorScheme.onSurface)
            val r = result
            when {
                r == null -> CircularProgressIndicator(Modifier.padding(24.dp).align(Alignment.CenterHorizontally))
                r.isFailure -> {
                    Text(TR("تعذّر تحميل التفسير. تحقق من الاتصال بالإنترنت.", "Tafsir konnte nicht geladen werden. Bitte Internetverbindung prüfen."), Modifier.padding(top = 16.dp), color = MaterialTheme.colorScheme.error)
                    OutlinedButton({ retry++ }, Modifier.padding(top = 8.dp)) { Text(TR("إعادة المحاولة", "Erneut versuchen")) }
                }
                else -> Text(
                    r.getOrThrow().ifBlank { TR("تفسير هذه الآية مذكور مع الآيات المجاورة.", "Die Erklärung dieses Verses steht bei den benachbarten Versen.") },
                    Modifier.padding(top = 12.dp), style = MaterialTheme.typography.bodyLarge, lineHeight = 30.sp,
                )
            }
        }
    }
}
