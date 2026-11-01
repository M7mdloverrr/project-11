package io.github.m7mdloverrr.quran.ui

import android.app.Application
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.OptIn
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.Reciter
import io.github.m7mdloverrr.quran.data.Reciters
import io.github.m7mdloverrr.quran.data.ar
import io.github.m7mdloverrr.quran.studio.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import kotlin.math.roundToInt

@OptIn(UnstableApi::class)
class StudioViewModel(app: Application) : AndroidViewModel(app) {
    val audioPlayer: ExoPlayer = ExoPlayer.Builder(app).build()
    val bgPlayer: ExoPlayer = ExoPlayer.Builder(app).build().apply { volume = 0f; repeatMode = Player.REPEAT_MODE_ONE }
    var surah by mutableIntStateOf(1)
    var from by mutableIntStateOf(1)
    var to by mutableIntStateOf(7)
    var reciter by mutableStateOf<Reciter?>(null)
    var bgIndex by mutableIntStateOf(0)
    var custom by mutableStateOf<Uri?>(null)
    var style by mutableStateOf(StudioStyle())
    var aspect by mutableStateOf(Aspect.Portrait)
    var hd by mutableStateOf(false)
    var status by mutableStateOf<String?>(null)
    var progress by mutableFloatStateOf(-1f)
    var busy by mutableStateOf(false)
    var exporting by mutableStateOf(false)
    var result by mutableStateOf<Uri?>(null)
    var playingIndex by mutableIntStateOf(-1)
    private var job: Job? = null
    private var transformer: Transformer? = null
    private val outDir = File(app.cacheDir, "studio/out")

    init {
        outDir.deleteRecursively()
        audioPlayer.addListener(object : Player.Listener {
            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                if (audioPlayer.mediaItemCount > 0) playingIndex = audioPlayer.currentMediaItemIndex
            }
            override fun onPlaybackStateChanged(state: Int) {
                if (state == Player.STATE_ENDED) playingIndex = -1
            }
        })
        setBackground()
    }

    fun setBackground() {
        bgPlayer.setMediaItem(MediaItem.fromUri(custom ?: Backgrounds[bgIndex].uri))
        bgPlayer.prepare()
        bgPlayer.play()
    }

    fun stopPreview() {
        audioPlayer.stop()
        audioPlayer.clearMediaItems()
        playingIndex = -1
    }

    private suspend fun clips(q: Quran): List<VerseClip> {
        val ayahs = q.surah(surah).ayahs.subList(from - 1, to)
        status = "تجهيز التلاوة…"
        progress = 0f
        return prepareAudio(getApplication(), reciter!!, ayahs) { progress = it }
    }

    private fun errorText(e: Exception) = when (e) {
        is AudioMissing -> "تلاوة الآية ${e.ayah.number.ar()} غير متوفرة لهذا القارئ. اختر قارئًا آخر."
        is IOException -> "تعذّر تنزيل التلاوة. تحقّق من الاتصال ثم أعد المحاولة."
        else -> "حدث خطأ: ${e.message}"
    }

    fun preview(q: Quran) {
        cancel(silent = true)
        job = viewModelScope.launch {
            busy = true
            try {
                val c = clips(q)
                audioPlayer.setMediaItems(c.map { MediaItem.fromUri(Uri.fromFile(it.file)) })
                audioPlayer.prepare()
                audioPlayer.play()
                playingIndex = 0
                status = null
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                status = errorText(e)
            } finally {
                busy = false
                progress = -1f
            }
        }
    }

    fun export(q: Quran) {
        cancel(silent = true)
        result = null
        job = viewModelScope.launch {
            busy = true
            try {
                val c = clips(q)
                val s = q.surah(surah)
                val (w, h) = aspect.size(if (hd) 1080 else 720)
                outDir.mkdirs()
                val out = File(outDir, "quran_${System.currentTimeMillis()}.mp4")
                val renderer = VerseRenderer(getApplication(), style, s.name, reciter!!.nameAr)
                status = "جارٍ إنشاء الفيديو…"
                exporting = true
                progress = 0f
                transformer = startExport(getApplication(), c, custom ?: Backgrounds[bgIndex].uri, w, h, renderer, out,
                    onDone = {
                        transformer = null
                        viewModelScope.launch {
                            try {
                                val name = "Quran_${s.number}_${from}-${to}_${System.currentTimeMillis() / 1000}.mp4"
                                result = withContext(Dispatchers.IO) { saveToGallery(getApplication(), out, name) }
                                status = "تم حفظ الفيديو في المعرض (Movies/Quran)"
                            } catch (e: Exception) {
                                status = "تعذّر حفظ الفيديو: ${e.message}"
                            } finally {
                                out.delete()
                                finish()
                            }
                        }
                    },
                    onError = {
                        transformer = null
                        out.delete()
                        status = "تعذّر التصدير (${it.errorCodeName}). أعد المحاولة."
                        finish()
                    },
                )
                val holder = ProgressHolder()
                while (transformer != null) {
                    if (transformer?.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) progress = holder.progress / 100f
                    delay(300)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                status = errorText(e)
                finish()
            }
        }
    }

    private fun finish() {
        busy = false
        exporting = false
        progress = -1f
    }

    fun cancel(silent: Boolean = false) {
        job?.cancel()
        transformer?.cancel()
        transformer = null
        outDir.listFiles()?.forEach { it.delete() }
        stopPreview()
        if (busy && !silent) status = "تم الإلغاء"
        finish()
    }

    override fun onCleared() {
        cancel(silent = true)
        audioPlayer.release()
        bgPlayer.release()
    }
}

@OptIn(UnstableApi::class)
@kotlin.OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun StudioScreen(app: AppViewModel, back: () -> Unit) {
    val vm: StudioViewModel = viewModel()
    val q = app.quran.collectAsState().value ?: return
    val st = app.settings.collectAsState().value ?: return
    val ctx = LocalContext.current
    LaunchedEffect(Unit) {
        app.stop()
        if (vm.reciter == null) vm.reciter = st.reciter
    }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) { vm.custom = uri; vm.setBackground() }
    }
    val view = LocalView.current
    DisposableEffect(vm.busy) {
        view.keepScreenOn = vm.busy
        onDispose { view.keepScreenOn = false }
    }
    var pickSurah by remember { mutableStateOf(false) }
    val surah = q.surah(vm.surah)
    val count = surah.ayahs.size
    fun changed() { vm.stopPreview(); vm.result = null }

    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text("استوديو الفيديو") },
            navigationIcon = { IconButton(back) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "رجوع") } },
        )
    }) { pad ->
        Column(
            Modifier.padding(pad).verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            val ratio = vm.aspect.w.toFloat() / vm.aspect.h
            val idx = vm.playingIndex.coerceAtLeast(0)
            val ayah = surah.ayahs[(vm.from - 1 + idx).coerceAtMost(vm.to - 1)]
            val renderer = remember(vm.style, vm.surah, vm.reciter) { VerseRenderer(ctx, vm.style, surah.name, vm.reciter?.nameAr ?: "") }
            val (pw, ph) = vm.aspect.size(540)
            val bmp = remember(renderer, ayah, vm.aspect) { renderer.render(pw, ph, ayah).asImageBitmap() }
            Box(
                Modifier.fillMaxWidth(if (ratio < 1f) 0.62f else 1f).align(Alignment.CenterHorizontally)
                    .aspectRatio(ratio).clip(RoundedCornerShape(16.dp)).background(Color.Black),
            ) {
                AndroidView({
                    PlayerView(it).apply {
                        useController = false
                        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                        player = vm.bgPlayer
                    }
                }, Modifier.matchParentSize())
                Box(Modifier.matchParentSize().background(Color.Black.copy(alpha = vm.style.dim)))
                Image(bmp, null, Modifier.matchParentSize(), contentScale = ContentScale.FillBounds)
            }

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                if (vm.playingIndex >= 0) {
                    OutlinedButton({ vm.stopPreview() }, Modifier.weight(1f)) { Icon(Icons.Rounded.Stop, null); Spacer(Modifier.width(6.dp)); Text("إيقاف") }
                } else {
                    OutlinedButton({ vm.preview(q) }, Modifier.weight(1f), enabled = !vm.busy) { Icon(Icons.Rounded.PlayArrow, null); Spacer(Modifier.width(6.dp)); Text("معاينة") }
                }
                Button({ vm.export(q) }, Modifier.weight(1f), enabled = !vm.busy) { Icon(Icons.Rounded.Movie, null); Spacer(Modifier.width(6.dp)); Text("تصدير MP4") }
            }
            if (vm.busy || vm.status != null) {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        vm.status?.let { Text(it, fontWeight = FontWeight.Medium) }
                        if (vm.progress >= 0f) {
                            LinearProgressIndicator({ vm.progress }, Modifier.fillMaxWidth())
                            Text("${(vm.progress * 100).roundToInt().ar()}٪", fontSize = 12.sp)
                        }
                        if (vm.exporting) Text("أبقِ التطبيق مفتوحًا حتى ينتهي التصدير.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        if (vm.busy) TextButton({ vm.cancel() }) { Text("إلغاء") }
                        vm.result?.let { uri ->
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Button({
                                    val i = Intent(Intent.ACTION_SEND).setType("video/mp4").putExtra(Intent.EXTRA_STREAM, uri)
                                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    ctx.startActivity(Intent.createChooser(i, "مشاركة الفيديو"))
                                }) { Icon(Icons.Rounded.Share, null); Spacer(Modifier.width(6.dp)); Text("مشاركة") }
                                OutlinedButton({
                                    ctx.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "video/mp4").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                }) { Text("تشغيل") }
                            }
                        }
                    }
                }
            }

            StudioSection("الآيات") {
                OutlinedButton({ pickSurah = true }, Modifier.fillMaxWidth(), enabled = !vm.busy) { Text("${surah.number.ar()}. ${surah.name}") }
                Text("من الآية ${vm.from.ar()} إلى الآية ${vm.to.ar()} (${(vm.to - vm.from + 1).ar()} آية)")
                RangeSlider(
                    value = vm.from.toFloat()..vm.to.toFloat(),
                    onValueChange = { r -> vm.from = r.start.roundToInt(); vm.to = r.endInclusive.roundToInt().coerceAtLeast(vm.from); changed() },
                    valueRange = 1f..count.toFloat(),
                    enabled = !vm.busy,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Stepper("من", vm.from, 1, vm.to, !vm.busy) { vm.from = it; changed() }
                    Stepper("إلى", vm.to, vm.from, count, !vm.busy) { vm.to = it; changed() }
                }
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    AssistChip({ vm.to = vm.from; changed() }, { Text("آية واحدة") }, enabled = !vm.busy)
                    AssistChip({ vm.from = 1; vm.to = count; changed() }, { Text("السورة كاملة") }, enabled = !vm.busy)
                }
            }

            StudioSection("القارئ") {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Reciters.all.forEach { r ->
                        FilterChip(vm.reciter?.id == r.id, { vm.reciter = r; changed() }, { Text(r.nameAr) }, enabled = !vm.busy)
                    }
                }
            }

            StudioSection("الخلفية") {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(Backgrounds.size) { i ->
                        val b = Backgrounds[i]
                        val sel = vm.custom == null && vm.bgIndex == i
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Image(
                                painterResource(b.thumb), b.nameAr,
                                Modifier.size(96.dp, 64.dp).clip(RoundedCornerShape(10.dp))
                                    .border(if (sel) 3.dp else 0.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(10.dp))
                                    .clickable(enabled = !vm.busy) { vm.custom = null; vm.bgIndex = i; vm.setBackground(); vm.result = null },
                                contentScale = ContentScale.Crop,
                            )
                            Text(b.nameAr, fontSize = 12.sp)
                        }
                    }
                    item {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Box(
                                Modifier.size(96.dp, 64.dp).clip(RoundedCornerShape(10.dp))
                                    .background(MaterialTheme.colorScheme.secondaryContainer)
                                    .border(if (vm.custom != null) 3.dp else 0.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(10.dp))
                                    .clickable(enabled = !vm.busy) { picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.VideoOnly)) },
                                contentAlignment = Alignment.Center,
                            ) { Icon(Icons.Rounded.VideoLibrary, null) }
                            Text("من الهاتف", fontSize = 12.sp)
                        }
                    }
                }
            }

            StudioSection("النص") {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("خط المصحف", "نسخ").forEachIndexed { i, t -> FilterChip(vm.style.font == i, { vm.style = vm.style.copy(font = i) }, { Text(t) }) }
                }
                Text("حجم الخط")
                Slider(vm.style.size, { vm.style = vm.style.copy(size = it) }, valueRange = 0.6f..1.6f)
                Text("اللون")
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    TextColors.forEach { c ->
                        Box(
                            Modifier.size(36.dp).clip(CircleShape).background(Color(c))
                                .border(if (vm.style.color == c) 3.dp else 1.dp, MaterialTheme.colorScheme.primary, CircleShape)
                                .clickable { vm.style = vm.style.copy(color = c) },
                        )
                    }
                }
                Text("الموضع")
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("أعلى", "وسط", "أسفل").forEachIndexed { i, t -> FilterChip(vm.style.position == i, { vm.style = vm.style.copy(position = i) }, { Text(t) }) }
                }
                SwitchRow("ظل للنص", vm.style.shadow) { vm.style = vm.style.copy(shadow = it) }
                Text("تعتيم الخلفية")
                Slider(vm.style.dim, { vm.style = vm.style.copy(dim = it) }, valueRange = 0f..0.75f)
            }

            StudioSection("الإخراج") {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Aspect.entries.forEach { a -> FilterChip(vm.aspect == a, { vm.aspect = a; vm.result = null }, { Text(a.label) }, enabled = !vm.busy) }
                }
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(!vm.hd, { vm.hd = false }, { Text("720p") }, enabled = !vm.busy)
                    FilterChip(vm.hd, { vm.hd = true }, { Text("1080p") }, enabled = !vm.busy)
                }
            }

            Text(
                "مصادر الخلفيات: " + Backgrounds.joinToString(" • ") { "${it.nameAr}: ${it.credit}" } + ". التلاوات: EveryAyah.com",
                fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }

    if (pickSurah) {
        AlertDialog(
            onDismissRequest = { pickSurah = false },
            confirmButton = { TextButton({ pickSurah = false }) { Text("إغلاق") } },
            title = { Text("اختر السورة") },
            text = {
                LazyColumn(Modifier.heightIn(max = 420.dp)) {
                    items(q.surahs) { s ->
                        Text(
                            "${s.number.ar()}. ${s.name}",
                            Modifier.fillMaxWidth().clickable {
                                vm.surah = s.number; vm.from = 1; vm.to = minOf(s.ayahs.size, 7); changed(); pickSurah = false
                            }.padding(vertical = 10.dp),
                        )
                    }
                }
            },
        )
    }
}

@Composable
private fun StudioSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
            content()
        }
    }
}

@Composable
private fun Stepper(label: String, value: Int, min: Int, max: Int, enabled: Boolean, onChange: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label)
        IconButton({ onChange((value - 1).coerceAtLeast(min)) }, enabled = enabled && value > min) { Icon(Icons.Rounded.Remove, "−") }
        Text(value.ar(), fontWeight = FontWeight.Bold)
        IconButton({ onChange((value + 1).coerceAtMost(max)) }, enabled = enabled && value < max) { Icon(Icons.Rounded.Add, "+") }
    }
}
