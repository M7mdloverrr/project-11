package io.github.m7mdloverrr.quran.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings as AndroidSettings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Stop
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RangeSlider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.ar
import io.github.m7mdloverrr.quran.tasmee.Mark
import io.github.m7mdloverrr.quran.tasmee.Phase
import io.github.m7mdloverrr.quran.tasmee.TWord
import io.github.m7mdloverrr.quran.tasmee.TasmeePrefs
import io.github.m7mdloverrr.quran.tasmee.TasmeeSettings
import io.github.m7mdloverrr.quran.tasmee.TasmeeViewModel
import io.github.m7mdloverrr.quran.tasmee.WordResult
import kotlinx.coroutines.delay

private val WrongRed = Color(0xFFD32F2F)
private val MissedAmber = Color(0xFFE08A00)
private val QpcFont get() = ScriptFonts[0]!!

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TasmeeScreen(app: AppViewModel, onBack: () -> Unit) {
    val vm: TasmeeViewModel = viewModel()
    val quran by app.quran.collectAsStateWithLifecycle()
    val main by app.settings.collectAsStateWithLifecycle()
    val ts by vm.settings.collectAsStateWithLifecycle()
    val ctx = LocalContext.current
    var showSettings by remember { mutableStateOf(false) }
    var denied by remember { mutableStateOf(false) }
    var pending by remember { mutableStateOf<Triple<Int, Int, Int>?>(null) }
    val mic = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok ->
        val p = pending
        if (ok && p != null) vm.start(p.first, p.second, p.third) else if (!ok) denied = true
    }
    LaunchedEffect(Unit) { vm.prepare() }
    val view = LocalView.current
    DisposableEffect(vm.phase) {
        view.keepScreenOn = vm.phase == Phase.Listening || vm.phase == Phase.Mistake
        onDispose { view.keepScreenOn = false }
    }
    BackHandler(vm.phase != Phase.Setup) { vm.backToSetup() }
    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text("التسميع") },
            navigationIcon = {
                IconButton(onClick = { if (vm.phase != Phase.Setup) vm.backToSetup() else onBack() }) {
                    Icon(Icons.AutoMirrored.Rounded.ArrowBack, "رجوع")
                }
            },
            actions = { IconButton(onClick = { showSettings = true }) { Icon(Icons.Rounded.Tune, "إعدادات التسميع") } },
        )
    }) { pad ->
        val q = quran
        val st = ts
        if (q == null || st == null) {
            Box(Modifier.padding(pad)) { Loading() }
            return@Scaffold
        }
        Box(Modifier.padding(pad).fillMaxSize()) {
            if (vm.phase == Phase.Setup) {
                SetupPane(q, st, main?.lastSurah ?: 0, vm.modelReady) { s, f, t ->
                    if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                        vm.start(s, f, t)
                    } else {
                        pending = Triple(s, f, t)
                        mic.launch(Manifest.permission.RECORD_AUDIO)
                    }
                }
            } else SessionPane(q, st, vm)
        }
    }
    val s = ts
    if (showSettings && s != null) TasmeeSettingsSheet(vm, s) { showSettings = false }
    if (vm.phase == Phase.Mistake && vm.mistakeAt >= 0) {
        val w = vm.words.getOrNull(vm.mistakeAt)
        val r = vm.marks.getOrNull(vm.mistakeAt)
        if (w != null) AlertDialog(
            onDismissRequest = {},
            title = { Text(if (r?.mark == Mark.Missed) "فاتتك كلمة" else "خطأ في التلاوة") },
            text = {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Text("الصواب", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(w.text, fontFamily = QpcFont, fontSize = 34.sp, color = MaterialTheme.colorScheme.primary, textAlign = TextAlign.Center)
                    r?.heard?.let {
                        Spacer(Modifier.height(8.dp))
                        Text("سمعتُ: $it", style = MaterialTheme.typography.bodyMedium, color = WrongRed)
                    }
                    Text("الآية ${w.ayah.ar()}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            },
            confirmButton = { Button(onClick = vm::continueAfterMistake) { Text("تابع") } },
            dismissButton = { TextButton(onClick = vm::retryMistake) { Text("أعد من هذه الكلمة") } },
        )
    }
    if (denied) AlertDialog(
        onDismissRequest = { denied = false },
        title = { Text("إذن الميكروفون") },
        text = { Text("يحتاج التسميع إلى الميكروفون ليستمع إلى تلاوتك. الصوت يُعالج على هاتفك فقط ولا يُرسل إلى أي مكان.") },
        confirmButton = {
            TextButton(onClick = {
                denied = false
                ctx.startActivity(Intent(AndroidSettings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", ctx.packageName, null)))
            }) { Text("فتح الإعدادات") }
        },
        dismissButton = { TextButton(onClick = { denied = false }) { Text("إلغاء") } },
    )
    vm.error?.let { e ->
        AlertDialog(onDismissRequest = { vm.error = null }, text = { Text(e) }, confirmButton = { TextButton(onClick = { vm.error = null }) { Text("حسناً") } })
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SetupPane(q: Quran, st: TasmeeSettings, lastSurah: Int, ready: Boolean, onStart: (Int, Int, Int) -> Unit) {
    var surah by remember { mutableIntStateOf((if (st.surah > 0) st.surah else lastSurah).coerceIn(1, 114)) }
    val count = q.surah(surah).ayahs.size
    var from by remember(surah) { mutableFloatStateOf(if (surah == st.surah) st.from.coerceIn(1, count).toFloat() else 1f) }
    var to by remember(surah) { mutableFloatStateOf(if (surah == st.surah && st.to > 0) st.to.coerceIn(1, count).toFloat() else minOf(count, if (count <= 20) count else 10).toFloat()) }
    var pick by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Surface(shape = MaterialTheme.shapes.extraLarge, color = MaterialTheme.colorScheme.primaryContainer) {
            Column(Modifier.fillMaxWidth().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(64.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary), contentAlignment = Alignment.Center) {
                    Icon(Icons.Rounded.Mic, null, tint = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.size(34.dp))
                }
                Spacer(Modifier.height(10.dp))
                Text("سمِّع حفظك", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimaryContainer)
                Text(
                    "الآيات مخفية. ابدأ التلاوة وستظهر كل كلمة عند قراءتها، وتُعلَّم الأخطاء والكلمات الفائتة.",
                    style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }
        Text("المقطع", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
        Surface(onClick = { pick = true }, shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainerHigh) {
            Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("سورة ${q.surah(surah).name}", fontFamily = QuranFont, fontSize = 24.sp)
                    Text("${count.ar()} آية • اضغط لاختيار سورة أخرى", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text(surah.ar(), style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
            }
        }
        Surface(shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainer) {
            Column(Modifier.fillMaxWidth().padding(16.dp)) {
                Text("من الآية ${from.toInt().ar()} إلى الآية ${to.toInt().ar()}", style = MaterialTheme.typography.titleMedium)
                if (count > 1) RangeSlider(
                    value = from..to,
                    onValueChange = { from = it.start.toInt().toFloat(); to = it.endInclusive.toInt().toFloat() },
                    valueRange = 1f..count.toFloat(),
                    steps = (count - 2).coerceAtLeast(0),
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (ready) Icon(Icons.Rounded.CheckCircle, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
            else CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp)
            Text(
                if (ready) "المصحح الصوتي جاهز • يعمل دون إنترنت" else "جارٍ تجهيز المصحح الصوتي…",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Button(
            onClick = { onStart(surah, from.toInt(), to.toInt()) }, enabled = ready,
            modifier = Modifier.fillMaxWidth().height(56.dp),
        ) {
            Icon(Icons.Rounded.Mic, null)
            Spacer(Modifier.width(8.dp))
            Text("ابدأ التسميع", style = MaterialTheme.typography.titleMedium)
        }
    }
    if (pick) SurahPicker(q, { pick = false }) { surah = it; pick = false }
}

@Composable
private fun SurahPicker(q: Quran, onDismiss: () -> Unit, onPick: (Int) -> Unit) {
    var query by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("اختر السورة") },
        text = {
            Column {
                OutlinedTextField(query, { query = it }, singleLine = true, label = { Text("بحث") }, modifier = Modifier.fillMaxWidth())
                val list = q.surahs.filter { query.isBlank() || it.name.contains(query.trim()) || it.number.toString() == query.trim() || it.englishName.contains(query.trim(), true) }
                LazyColumn(Modifier.heightIn(max = 420.dp)) {
                    items(list, key = { it.number }) { s ->
                        Row(Modifier.fillMaxWidth().clickable { onPick(s.number) }.padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(s.number.ar(), Modifier.width(40.dp), color = MaterialTheme.colorScheme.primary)
                            Text(s.name, fontFamily = QuranFont, fontSize = 20.sp, modifier = Modifier.weight(1f))
                            Text("${s.ayahs.size.ar()} آية", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("إغلاق") } },
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SessionPane(q: Quran, st: TasmeeSettings, vm: TasmeeViewModel) {
    val words = vm.words
    val (surah, from, to) = vm.range
    val page = LocalPageColors.current
    val done = vm.phase == Phase.Done
    var revealAll by remember(done) { mutableStateOf(false) }
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(vm.phase) { while (vm.phase == Phase.Listening) { now = System.currentTimeMillis(); delay(500) } }
    val elapsed = if (done) vm.elapsedMs else now - vm.startedAt
    Column(Modifier.fillMaxSize()) {
        Column(Modifier.padding(horizontal = 16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("سورة ${q.surah(surah).name}", fontFamily = QuranFont, fontSize = 22.sp, modifier = Modifier.weight(1f))
                Text("الآيات ${from.ar()}–${to.ar()} • ${clock(elapsed)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            val progress by animateFloatAsState(if (words.isEmpty()) 0f else vm.pointer.toFloat() / words.size, tween(400), label = "p")
            LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).clip(CircleShape))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Legend(page.text, "صحيحة")
                Legend(WrongRed, "خطأ")
                Legend(MissedAmber, "فائتة")
            }
        }
        val scroll = rememberScrollState()
        LaunchedEffect(vm.revealed, done) { scroll.animateScrollTo(if (done) 0 else scroll.maxValue) }
        Column(Modifier.weight(1f).fillMaxWidth().verticalScroll(scroll).padding(12.dp)) {
            Surface(color = page.page, shape = MaterialTheme.shapes.large, modifier = Modifier.fillMaxWidth().heightIn(min = 220.dp)) {
                Box(Modifier.padding(16.dp)) {
                    val shown = if (revealAll) words.size else vm.revealed
                    if (shown == 0 && vm.phase == Phase.Listening) {
                        Text(
                            "ابدأ التلاوة… ستظهر الكلمات هنا",
                            Modifier.fillMaxWidth().padding(top = 70.dp), textAlign = TextAlign.Center,
                            color = page.text.copy(alpha = 0.35f), style = MaterialTheme.typography.titleMedium,
                        )
                    }
                    FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(7.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        for (i in 0 until shown) {
                            val committed = i < vm.pointer
                            val r = if (committed) vm.marks.getOrNull(i) else vm.tentative.getOrNull(i - vm.pointer)
                            WordView(words[i], r, !committed && !revealAll, i in vm.hinted, st, page.text)
                        }
                        val next = vm.revealed
                        if (!done && next < words.size && (vm.hintShown == next || st.hint == 2)) {
                            Text(words[next].text, fontFamily = QpcFont, fontSize = st.fontSize.sp, color = page.text.copy(alpha = 0.22f))
                        }
                    }
                }
            }
            if (done) Summary(vm, onRevealAll = { revealAll = true }, revealed = revealAll)
        }
        if (!done) Controls(vm, st)
    }
}

@Composable
private fun Legend(c: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(9.dp).clip(CircleShape).background(c))
        Spacer(Modifier.width(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun WordView(w: TWord, r: WordResult?, tentative: Boolean, hinted: Boolean, st: TasmeeSettings, ink: Color) {
    val anim = remember { Animatable(0f) }
    LaunchedEffect(Unit) { anim.animateTo(1f, tween(650, easing = FastOutSlowInEasing)) }
    val target = when {
        r == null -> ink.copy(alpha = 0.45f)
        r.mark == Mark.Wrong -> WrongRed
        r.mark == Mark.Missed -> MissedAmber
        hinted -> MaterialTheme.colorScheme.primary
        else -> ink
    }
    val color by animateColorAsState(target, tween(350), label = "c")
    val density = LocalDensity.current
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .graphicsLayer {
                alpha = anim.value * if (tentative) 0.7f else 1f
                translationY = (1f - anim.value) * with(density) { 10.dp.toPx() }
            }
            .blur(((1f - anim.value) * 6f).dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                w.text, fontFamily = QpcFont, fontSize = st.fontSize.sp, color = color,
                textDecoration = if (r?.mark == Mark.Missed) TextDecoration.Underline else null,
            )
            if (w.ayahEnd) {
                Spacer(Modifier.width(4.dp))
                Text(w.ayah.ar(), fontFamily = QpcFont, fontSize = st.fontSize.sp, color = MaterialTheme.colorScheme.primary)
            }
        }
        if (st.showHeard && r?.mark == Mark.Wrong && !r.heard.isNullOrBlank()) {
            Text(r.heard, fontSize = 12.sp, color = WrongRed.copy(alpha = 0.8f), textDecoration = TextDecoration.LineThrough)
        }
    }
}

@Composable
private fun Controls(vm: TasmeeViewModel, st: TasmeeSettings) {
    val pulse = rememberInfiniteTransition(label = "pulse")
    val wave by pulse.animateFloat(1f, 1.18f, infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "w")
    val lvl by animateFloatAsState(vm.level, tween(120), label = "l")
    Surface(color = MaterialTheme.colorScheme.surfaceContainer, shape = MaterialTheme.shapes.extraLarge, modifier = Modifier.fillMaxWidth().padding(12.dp)) {
        Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    when {
                        vm.phase == Phase.Mistake -> "متوقف عند خطأ"
                        vm.decoding -> "أستمع وأصحّح…"
                        else -> "أستمع إليك…"
                    },
                    style = MaterialTheme.typography.titleSmall,
                )
                Text("${vm.pointer.ar()} من ${vm.words.size.ar()} كلمة", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (st.hint == 1) {
                FilledTonalButton(onClick = vm::hint) {
                    Icon(Icons.Rounded.Lightbulb, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("تلميح")
                }
                Spacer(Modifier.width(12.dp))
            }
            Box(contentAlignment = Alignment.Center) {
                Box(
                    Modifier.size(64.dp).scale(if (vm.phase == Phase.Listening) wave + lvl * 0.35f else 1f).clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)),
                )
                Surface(onClick = vm::finish, shape = CircleShape, color = MaterialTheme.colorScheme.primary, modifier = Modifier.size(54.dp)) {
                    Box(contentAlignment = Alignment.Center) { Icon(Icons.Rounded.Stop, "إنهاء", tint = MaterialTheme.colorScheme.onPrimary) }
                }
            }
        }
    }
}

@Composable
private fun Summary(vm: TasmeeViewModel, onRevealAll: () -> Unit, revealed: Boolean) {
    val res = vm.marks.take(vm.pointer)
    val correct = res.count { it?.mark == Mark.Correct }
    val wrong = res.count { it?.mark == Mark.Wrong }
    val missed = res.count { it?.mark == Mark.Missed }
    val pct = if (res.isEmpty()) 0 else correct * 100 / res.size
    Spacer(Modifier.height(12.dp))
    Surface(shape = MaterialTheme.shapes.extraLarge, color = MaterialTheme.colorScheme.surfaceContainer) {
        Column(Modifier.fillMaxWidth().padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("نتيجة التسميع", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(12.dp))
            Box(contentAlignment = Alignment.Center) {
                val a by animateFloatAsState(pct / 100f, tween(900), label = "pct")
                CircularProgressIndicator(progress = { a }, modifier = Modifier.size(96.dp), strokeWidth = 8.dp, trackColor = MaterialTheme.colorScheme.surfaceContainerHighest)
                Text("${pct.ar()}٪", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                Stat(correct, "صحيحة", MaterialTheme.colorScheme.primary)
                Stat(wrong, "أخطاء", WrongRed)
                Stat(missed, "فائتة", MissedAmber)
                Stat(vm.hinted.size, "تلميحات", MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(
                "${vm.pointer.ar()} من ${vm.words.size.ar()} كلمة • ${clock(vm.elapsedMs)}",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 8.dp),
            )
            val mistakes = res.withIndex().filter { it.value != null && it.value!!.mark != Mark.Correct }
            if (mistakes.isNotEmpty()) {
                HorizontalDivider(Modifier.padding(vertical = 12.dp))
                Text("الأخطاء", style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth())
                mistakes.forEach { (i, r) ->
                    val w = vm.words[i]
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("آية ${w.ayah.ar()}", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.width(64.dp))
                        Text(w.text, fontFamily = QpcFont, fontSize = 22.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.weight(1f))
                        Text(
                            if (r!!.mark == Mark.Missed) "لم تُقرأ" else "قرأت: ${r.heard.orEmpty()}",
                            style = MaterialTheme.typography.bodySmall, color = if (r.mark == Mark.Missed) MissedAmber else WrongRed,
                        )
                    }
                }
            }
            Spacer(Modifier.height(14.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = vm::restart) {
                    Icon(Icons.Rounded.Refresh, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("إعادة")
                }
                OutlinedButton(onClick = vm::backToSetup) { Text("مقطع آخر") }
            }
            if (vm.pointer < vm.words.size && !revealed) TextButton(onClick = onRevealAll) { Text("إظهار بقية المقطع") }
        }
    }
}

@Composable
private fun Stat(n: Int, label: String, c: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(n.ar(), style = MaterialTheme.typography.titleLarge, color = c, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

private fun clock(ms: Long): String {
    val s = (ms / 1000).coerceAtLeast(0)
    return "${(s / 60).toInt().ar()}:${(s % 60).toInt().toString().padStart(2, '0').map { (it - '0' + 0x0660).toChar() }.joinToString("")}"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TasmeeSettingsSheet(vm: TasmeeViewModel, st: TasmeeSettings, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
            Text("إعدادات التسميع", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(horizontal = 20.dp))
            Choice("دقة التصحيح", listOf("متساهل", "متوسط", "دقيق"), st.strictness) { vm.setPref(TasmeePrefs.Keys.strictness, it) }
            Choice("عند الخطأ", listOf("تابع وعلّم الخطأ", "توقف للتصحيح"), st.onMistake) { vm.setPref(TasmeePrefs.Keys.onMistake, it) }
            Choice("التلميح", listOf("بدون", "زر تلميح", "الكلمة التالية باهتة"), st.hint) { vm.setPref(TasmeePrefs.Keys.hint, it) }
            Section("مدة السكوت قبل التصحيح: ${"%.1f".format(st.pauseSec)} ث") {
                var v by remember(st.pauseSec) { mutableFloatStateOf(st.pauseSec) }
                Slider(v, { v = it }, valueRange = 0.5f..2f, steps = 14, onValueChangeFinished = { vm.setPref(TasmeePrefs.Keys.pauseSec, v) })
                Text("المدة التي ينتظرها التطبيق بعد توقفك قبل أن يثبّت التصحيح.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Section("حجم الخط") {
                var v by remember(st.fontSize) { mutableFloatStateOf(st.fontSize) }
                Slider(v, { v = it }, valueRange = 22f..44f, steps = 10, onValueChangeFinished = { vm.setPref(TasmeePrefs.Keys.fontSize, v) })
                Surface(color = LocalPageColors.current.page, shape = MaterialTheme.shapes.medium) {
                    Text("ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ", Modifier.fillMaxWidth().padding(8.dp), fontFamily = QpcFont, fontSize = v.sp, textAlign = TextAlign.Center, color = LocalPageColors.current.text)
                }
            }
            Section("خيارات") {
                SwitchRow("اهتزاز عند الخطأ", st.vibrate) { vm.setPref(TasmeePrefs.Keys.vibrate, it) }
                SwitchRow("إظهار ما سمعه التطبيق تحت الكلمة الخاطئة", st.showHeard) { vm.setPref(TasmeePrefs.Keys.showHeard, it) }
            }
        }
    }
}

@Composable
private fun Choice(title: String, labels: List<String>, value: Int, onChange: (Int) -> Unit) {
    Section(title) {
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            labels.forEachIndexed { i, l ->
                SegmentedButton(value == i, { onChange(i) }, SegmentedButtonDefaults.itemShape(i, labels.size)) { Text(l, maxLines = 1, fontSize = 13.sp) }
            }
        }
    }
}
