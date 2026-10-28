package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.*

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings as AndroidSettings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateRectAsState
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.zIndex
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.boundsInParent
import androidx.compose.ui.layout.onGloballyPositioned
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
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.automirrored.rounded.MenuBook
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
private val MissedRed = Color(0xFFC62828)
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
    var pendingFollow by remember { mutableStateOf(false) }
    val mic = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok ->
        val p = pending
        if (ok && p != null) vm.start(p.first, p.second, p.third, pendingFollow) else if (!ok) denied = true
    }
    fun go(s: Int, f: Int, t: Int, follow: Boolean) {
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            vm.start(s, f, t, follow)
        } else {
            pending = Triple(s, f, t)
            pendingFollow = follow
            mic.launch(Manifest.permission.RECORD_AUDIO)
        }
    }
    LaunchedEffect(Unit) { vm.prepare() }
    var autoDone by androidx.compose.runtime.saveable.rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(vm.modelReady, ts?.autoStart) {
        if (!autoDone && vm.modelReady && ts?.autoStart == true && vm.phase == Phase.Setup) { autoDone = true; go(0, 0, 0, ts?.autoHidden != true) }
    }
    val view = LocalView.current
    DisposableEffect(vm.phase) {
        view.keepScreenOn = vm.phase == Phase.Listening || vm.phase == Phase.Mistake
        onDispose { view.keepScreenOn = false }
    }
    BackHandler(vm.phase != Phase.Setup) { vm.backToSetup() }
    var full by remember { mutableStateOf(false) }
    FullScreenEffect(full)
    BackHandler(full) { full = false }
    Scaffold(containerColor = Color.Transparent, topBar = {
        if (full) ExitFullScreenBar { full = false } else TopAppBar(
            title = { Text(TR("التسميع", "Tasmee")) },
            navigationIcon = {
                IconButton(onClick = { if (vm.phase != Phase.Setup) vm.backToSetup() else onBack() }) {
                    Icon(Icons.AutoMirrored.Rounded.ArrowBack, TR("رجوع", "Zurück"))
                }
            },
            actions = { FullScreenAction { full = true }; IconButton(onClick = { showSettings = true }) { Icon(Icons.Rounded.Tune, TR("إعدادات التسميع", "Tasmee-Einstellungen")) } },
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
                SetupPane(
                    q, st, main?.lastSurah ?: 0, vm.modelReady,
                    onFollow = { sura -> go(sura, 1, q.surah(sura).ayahs.size, true) },
                    onAuto = { go(0, 0, 0, !st.autoHidden) },
                ) { s, f, t -> go(s, f, t, false) }
            } else if (vm.follow) FollowPane(q, st, vm) else SessionPane(q, st, vm)
        }
    }
    val s = ts
    if (showSettings && s != null) TasmeeSettingsSheet(vm, s) { showSettings = false }
    if (vm.phase == Phase.Mistake && vm.mistakeAt >= 0) {
        val w = vm.words.getOrNull(vm.mistakeAt)
        val r = vm.marks.getOrNull(vm.mistakeAt)
        if (w != null) AlertDialog(
            onDismissRequest = {},
            title = { Text(if (r?.mark == Mark.Missed) TR("فاتتك كلمة", "Wort ausgelassen") else TR("خطأ في التلاوة", "Rezitationsfehler")) },
            text = {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Text(TR("الصواب", "Richtig"), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(w.text, fontFamily = QpcFont, fontSize = 34.sp, color = MaterialTheme.colorScheme.primary, textAlign = TextAlign.Center)
                    r?.heard?.let {
                        Spacer(Modifier.height(8.dp))
                        Text(TR("سمعتُ: $it", "Gehört: $it"), style = MaterialTheme.typography.bodyMedium, color = WrongRed)
                    }
                    Text(TR("الآية ${w.ayah.ar()}", "Vers ${w.ayah.ar()}"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            },
            confirmButton = { Button(onClick = vm::continueAfterMistake) { Text(TR("تابع", "Weiter")) } },
            dismissButton = { TextButton(onClick = vm::retryMistake) { Text(TR("أعد من هذه الكلمة", "Ab diesem Wort wiederholen")) } },
        )
    }
    if (denied) AlertDialog(
        onDismissRequest = { denied = false },
        title = { Text(TR("إذن الميكروفون", "Mikrofonberechtigung")) },
        text = { Text(TR("يحتاج التسميع إلى الميكروفون ليستمع إلى تلاوتك. الصوت يُعالج على هاتفك فقط ولا يُرسل إلى أي مكان.", "Tasmee braucht das Mikrofon, um deine Rezitation zu hören. Der Ton wird nur auf deinem Handy verarbeitet und nirgendwohin gesendet.")) },
        confirmButton = {
            TextButton(onClick = {
                denied = false
                ctx.startActivity(Intent(AndroidSettings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", ctx.packageName, null)))
            }) { Text(TR("فتح الإعدادات", "Einstellungen öffnen")) }
        },
        dismissButton = { TextButton(onClick = { denied = false }) { Text(TR("إلغاء", "Abbrechen")) } },
    )
    vm.error?.let { e ->
        AlertDialog(onDismissRequest = { vm.error = null }, text = { Text(e) }, confirmButton = { TextButton(onClick = { vm.error = null }) { Text(TR("حسناً", "OK")) } })
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SetupPane(q: Quran, st: TasmeeSettings, lastSurah: Int, ready: Boolean, onFollow: (Int) -> Unit, onAuto: () -> Unit, onStart: (Int, Int, Int) -> Unit) {
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
                Text(TR("سمِّع حفظك", "Sag deinen Hifz auf"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimaryContainer)
                Text(
                    TR("الآيات مخفية. ابدأ التلاوة وستظهر كل كلمة عند قراءتها، وتُعلَّم الأخطاء والكلمات الفائتة.", "Die Verse sind verborgen. Beginne zu rezitieren – jedes Wort erscheint, wenn du es liest; Fehler und ausgelassene Wörter werden markiert."),
                    style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }
        Button(onClick = onAuto, enabled = ready, modifier = Modifier.appear(0).fillMaxWidth().height(64.dp)) {
            Icon(Icons.Rounded.Mic, null)
            Spacer(Modifier.width(8.dp))
            Column {
                Text(TR("تسميع تلقائي", "Automatisches Tasmee"), style = MaterialTheme.typography.titleMedium)
                Text(TR("اقرأ من أي سورة وسيعرفها التطبيق", "Rezitiere aus einer beliebigen Sure – die App erkennt sie"), style = MaterialTheme.typography.bodySmall)
            }
        }
        Text(TR("المقطع", "Abschnitt"), style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
        Surface(onClick = { pick = true }, shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainerHigh) {
            Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(q.surah(surah).title, fontFamily = NameFont, fontSize = 24.sp)
                    Text(TR("${count.ar()} آية • اضغط لاختيار سورة أخرى", "${count.ar()} Verse • tippen, um eine andere Sure zu wählen"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text(surah.ar(), style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
            }
        }
        Surface(shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainer) {
            Column(Modifier.fillMaxWidth().padding(16.dp)) {
                Text(TR("من الآية ${from.toInt().ar()} إلى الآية ${to.toInt().ar()}", "Vers ${from.toInt().ar()} bis ${to.toInt().ar()}"), style = MaterialTheme.typography.titleMedium)
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
                if (ready) TR("المصحح الصوتي جاهز • يعمل دون إنترنت", "Sprachkorrektur bereit • funktioniert offline") else TR("جارٍ تجهيز المصحح الصوتي…", "Sprachkorrektur wird vorbereitet…"),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Button(
            onClick = { onStart(surah, from.toInt(), to.toInt()) }, enabled = ready,
            modifier = Modifier.fillMaxWidth().height(56.dp),
        ) {
            Icon(Icons.Rounded.Mic, null)
            Spacer(Modifier.width(8.dp))
            Text(TR("ابدأ التسميع", "Tasmee starten"), style = MaterialTheme.typography.titleMedium)
        }
        OutlinedButton(onClick = { onFollow(surah) }, enabled = ready, modifier = Modifier.fillMaxWidth().height(56.dp)) {
            Icon(Icons.AutoMirrored.Rounded.MenuBook, null)
            Spacer(Modifier.width(8.dp))
            Text(TR("تسميع والسورة ظاهرة", "Tasmee mit sichtbarer Sure"), style = MaterialTheme.typography.titleMedium)
        }
        Text(
            TR("تُعرض السورة كاملة، وتُظلَّل الآية التي تقرؤها بالأخضر ويتحرك مربع أخضر مع كل كلمة.", "Die ganze Sure wird angezeigt; der Vers, den du liest, wird grün markiert und ein grünes Kästchen folgt jedem Wort."),
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth(),
        )
    }
    if (pick) SurahPicker(q, { pick = false }) { surah = it; pick = false }
}

@Composable
private fun SurahPicker(q: Quran, onDismiss: () -> Unit, onPick: (Int) -> Unit) {
    var query by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(TR("اختر السورة", "Sure wählen")) },
        text = {
            Column {
                OutlinedTextField(query, { query = it }, singleLine = true, label = { Text(TR("بحث", "Suchen")) }, modifier = Modifier.fillMaxWidth())
                val list = q.surahs.filter { query.isBlank() || it.name.contains(query.trim()) || it.number.toString() == query.trim() || it.englishName.contains(query.trim(), true) || it.title.contains(query.trim(), true) }
                LazyColumn(Modifier.heightIn(max = 420.dp)) {
                    items(list, key = { it.number }) { s ->
                        Row(Modifier.fillMaxWidth().clickable { onPick(s.number) }.padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(s.number.ar(), Modifier.width(40.dp), color = MaterialTheme.colorScheme.primary)
                            Text(s.title, fontFamily = NameFont, fontSize = 20.sp, modifier = Modifier.weight(1f))
                            Text(TR("${s.ayahs.size.ar()} آية", "${s.ayahs.size.ar()} Verse"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(TR("إغلاق", "Schließen")) } },
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
                Text(if (surah == 0) TR("جارٍ تحديد السورة…", "Sure wird erkannt…") else q.surah(surah).title, fontFamily = NameFont, fontSize = 22.sp, modifier = Modifier.weight(1f))
                Text((if (surah == 0) "" else TR("الآيات ${from.ar()}–${to.ar()} • ", "Verse ${from.ar()}–${to.ar()} • ")) + clock(elapsed), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            val progress by animateFloatAsState(if (words.isEmpty()) 0f else vm.pointer.toFloat() / words.size, tween(400), label = "p")
            LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).clip(CircleShape))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Legend(page.text, TR("صحيحة", "Richtig"))
                Legend(WrongRed, TR("خطأ", "Fehler"))
                Legend(MissedRed, TR("فائتة", "Ausgelassen"))
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
                            if (vm.locating) TR("ابدأ التلاوة من أي سورة… ستظهر الكلمات هنا", "Rezitiere aus einer beliebigen Sure… die Wörter erscheinen hier") else TR("ابدأ التلاوة… ستظهر الكلمات هنا", "Beginne zu rezitieren… die Wörter erscheinen hier"),
                            Modifier.fillMaxWidth().padding(top = 70.dp), textAlign = TextAlign.Center,
                            color = page.text.copy(alpha = 0.35f), style = MaterialTheme.typography.titleMedium,
                        )
                    }
                    RtlFlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(7.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
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

private val FollowGreen = Color(0xFF3FA66B)

/** Word indices of [words] grouped by Mushaf page (Madani 604-page division). */
private fun mushafPages(q: Quran, words: List<TWord>): List<Pair<Int, List<Int>>> =
    words.indices.groupBy { q.ayah(words[it].surah, words[it].ayah).page }.toList()

@Composable
private fun FollowPane(q: Quran, st: TasmeeSettings, vm: TasmeeViewModel) {
    val words = vm.words
    val done = vm.phase == Phase.Done
    if (words.isEmpty()) {
        Column(Modifier.fillMaxSize()) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                if (done) Column(Modifier.verticalScroll(rememberScrollState()).padding(12.dp)) { Summary(vm, onRevealAll = {}, revealed = true) }
                else Locating()
            }
            if (!done) Controls(vm, st)
        }
        return
    }
    androidx.compose.runtime.key(words) { FollowPages(q, st, vm, words, done) }
}

@Composable
private fun Locating() {
    val pulse = rememberInfiniteTransition(label = "loc")
    val s by pulse.animateFloat(0.9f, 1.15f, infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "s")
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.appear().padding(24.dp)) {
        Box(Modifier.size(110.dp).scale(s).clip(CircleShape).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)), contentAlignment = Alignment.Center) {
            Icon(Icons.AutoMirrored.Rounded.MenuBook, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(44.dp))
        }
        Spacer(Modifier.height(18.dp))
        Text(TR("ابدأ التلاوة من أي سورة", "Rezitiere aus einer beliebigen Sure"), style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
        Text(
            TR("سأتعرف على السورة والآية بعد بضع كلمات، وأتابعك صفحةً صفحة.", "Nach ein paar Wörtern erkenne ich Sure und Vers und folge dir Seite für Seite."),
            style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FollowPages(q: Quran, st: TasmeeSettings, vm: TasmeeViewModel, words: List<TWord>, done: Boolean) {
    val (surah, _, _) = vm.range
    val page = LocalPageColors.current
    val pages = remember(words) { mushafPages(q, words) }
    val cur = (vm.revealed - 1).coerceIn(0, words.size - 1)
    val curAyah = words[cur].ayah
    val curPage = pages.indexOfFirst { cur in it.second }.coerceAtLeast(0)
    val curl = remember { CurlState(curPage) }
    LaunchedEffect(curPage, done) { if (!done) curl.turnTo(curPage, pages.size) }
    val rtl = true
    var showResult by remember(done) { mutableStateOf(done) }
    Column(Modifier.fillMaxSize()) {
        Column(Modifier.padding(horizontal = 16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(q.surah(surah).title, fontFamily = NameFont, fontSize = 22.sp, modifier = Modifier.weight(1f))
                Text(
                    TR("الآية ${curAyah.ar()} • الصفحة ${pages[curl.index.coerceIn(0, pages.size - 1)].first.ar()}", "Vers ${curAyah.ar()} • Seite ${pages[curl.index.coerceIn(0, pages.size - 1)].first.ar()}"),
                    style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            val progress by animateFloatAsState(vm.pointer.toFloat() / words.size, tween(400), label = "p")
            LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).clip(CircleShape))
        }
        CurlPager(curl, pages.size, Modifier.weight(1f).fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp), rtl, page.page) { i ->
            MushafPage(q, vm, words, pages[i], if (!done && i == curPage) cur else -1, st, page)
        }
        if (done) {
            Row(Modifier.fillMaxWidth().padding(12.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = { showResult = true }, modifier = Modifier.weight(1f)) { Text(TR("النتيجة", "Ergebnis")) }
                OutlinedButton(onClick = vm::restart, modifier = Modifier.weight(1f)) { Text(TR("إعادة", "Wiederholen")) }
            }
        } else Controls(vm, st)
    }
    if (done && showResult) {
        ModalBottomSheet(onDismissRequest = { showResult = false }) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 12.dp).padding(bottom = 24.dp)) {
                Summary(vm, onRevealAll = {}, revealed = true)
            }
        }
    }
}

@Composable
private fun MushafPage(q: Quran, vm: TasmeeViewModel, words: List<TWord>, pg: Pair<Int, List<Int>>, cur: Int, st: TasmeeSettings, colors: PageColors) {
    Surface(color = colors.page, shape = MaterialTheme.shapes.medium, shadowElevation = 3.dp, modifier = Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 10.dp, vertical = 12.dp)) {
            val fi = pg.second.first()
            val first = words[fi]
            if (first.ayah == 1 && (fi == 0 || words[fi - 1].ayah != 1)) {
                Text(
                    q.surah(first.surah).name, fontFamily = QuranFont, fontSize = 24.sp, color = colors.text, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().border(1.dp, colors.text.copy(alpha = 0.25f), MaterialTheme.shapes.small).padding(vertical = 4.dp),
                )
                Spacer(Modifier.height(8.dp))
            }
            Passage(vm, words, pg.second, cur, st, colors.text)
            Spacer(Modifier.weight(1f))
            Text(pg.first.ar(), style = MaterialTheme.typography.labelMedium, color = colors.text.copy(alpha = 0.6f), textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(top = 10.dp))
        }
    }
}

@Composable
private fun AyahMark(n: Int, st: TasmeeSettings, ink: Color, modifier: Modifier = Modifier) {
    if (st.ayahMark == 2) return
    Box(
        modifier.padding(horizontal = 3.dp).size((st.fontSize * 1.05f).dp).border(1.2.dp, ink.copy(alpha = 0.55f), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (st.ayahMark == 0) Text(n.arq(), fontSize = (st.fontSize * 0.42f).sp, color = ink.copy(alpha = 0.85f))
    }
}

@Composable
private fun Passage(vm: TasmeeViewModel, words: List<TWord>, idx: List<Int>, cur: Int, st: TasmeeSettings, ink: Color) {
    val bounds = remember { mutableStateMapOf<Int, Rect>() }
    val ayah = if (cur >= 0) words[cur].ayah else -1
    val target = bounds[cur] ?: Rect.Zero
    val box by animateRectAsState(target, tween(260, easing = FastOutSlowInEasing), label = "box")
    val glow by animateFloatAsState(if (cur >= 0) 1f else 0f, tween(350), label = "glow")
    RtlFlowRow(
        Modifier.fillMaxWidth()
            .drawWithContent {
                if (glow > 0f && ayah > 0) {
                    val px = 4.dp.toPx()
                    val lines = idx.filter { words[it].ayah == ayah }.flatMap { listOfNotNull(bounds[it], if (words[it].ayahEnd) bounds[-1 - it] else null) }.groupBy { it.top.toInt() }
                    for (row in lines.values) {
                        val l = row.minOf { it.left } - px; val r = row.maxOf { it.right } + px
                        val t = row.minOf { it.top }; val b = row.maxOf { it.bottom }
                        drawRoundRect(FollowGreen.copy(alpha = 0.09f * glow), Offset(l, t), Size(r - l, b - t), CornerRadius(6.dp.toPx()))
                    }
                    if (target != Rect.Zero) {
                        val pad = Offset(3.dp.toPx(), 1.dp.toPx())
                        drawRoundRect(
                            FollowGreen.copy(alpha = 0.16f * glow), box.topLeft - pad,
                            Size(box.width + pad.x * 2, box.height + pad.y * 2), CornerRadius(6.dp.toPx()),
                        )
                    }
                }
                drawContent()
            },
        horizontalArrangement = Arrangement.Center,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        for (i in idx) {
            val w = words[i]
            val r = if (i < vm.pointer) vm.marks.getOrNull(i) else vm.tentative.getOrNull(i - vm.pointer)
            val c = when (r?.mark) {
                Mark.Wrong -> WrongRed
                Mark.Missed -> MissedRed
                else -> ink
            }
            Column(
                Modifier.onGloballyPositioned { bounds[i] = it.boundsInParent() }.padding(horizontal = 3.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    w.text, fontFamily = QpcFont, fontSize = st.fontSize.sp, color = c,
                    textDecoration = if (r?.mark == Mark.Missed) TextDecoration.Underline else null,
                )
                HeardLabel(r, st)
            }
            if (w.ayahEnd) AyahMark(w.ayah, st, ink, Modifier.align(Alignment.CenterVertically).onGloballyPositioned { bounds[-1 - i] = it.boundsInParent() })
        }
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
        r.mark == Mark.Missed -> MissedRed
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
            if (w.ayahEnd && st.ayahMark == 0) {
                Spacer(Modifier.width(4.dp))
                Text(w.ayah.arq(), fontFamily = QpcFont, fontSize = st.fontSize.sp, color = MaterialTheme.colorScheme.primary)
            } else if (w.ayahEnd && st.ayahMark == 1) AyahMark(w.ayah, st, MaterialTheme.colorScheme.primary)
        }
        HeardLabel(r, st)
    }
}

/** Under a red word: what was recited instead, or that it was skipped. */
@Composable
private fun HeardLabel(r: WordResult?, st: TasmeeSettings) {
    if (!st.showHeard || r == null || r.partial) return
    when (r.mark) {
        Mark.Wrong -> Text(
            if (r.heard.isNullOrBlank()) TR("قرأتَ كلمة أخرى", "Du hast ein anderes Wort gelesen") else TR("قرأتَ: ${r.heard}", "Gelesen: ${r.heard}"),
            fontSize = 12.sp, lineHeight = 16.sp, color = WrongRed.copy(alpha = 0.85f), textAlign = TextAlign.Center,
        )
        Mark.Missed -> Text(TR("فاتتك", "Ausgelassen"), fontSize = 12.sp, lineHeight = 16.sp, color = MissedRed.copy(alpha = 0.85f))
        else -> Unit
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
                        vm.phase == Phase.Mistake -> TR("متوقف عند خطأ", "Bei Fehler angehalten")
                        vm.decoding -> TR("أستمع وأصحّح…", "Ich höre zu und korrigiere…")
                        else -> TR("أستمع إليك…", "Ich höre dir zu…")
                    },
                    style = MaterialTheme.typography.titleSmall,
                )
                Text(TR("${vm.pointer.ar()} من ${vm.words.size.ar()} كلمة", "${vm.pointer.ar()} von ${vm.words.size.ar()} Wörtern"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (st.hint == 1) {
                FilledTonalButton(onClick = vm::hint) {
                    Icon(Icons.Rounded.Lightbulb, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(TR("تلميح", "Hinweis"))
                }
                Spacer(Modifier.width(12.dp))
            }
            Box(contentAlignment = Alignment.Center) {
                Box(
                    Modifier.size(64.dp).scale(if (vm.phase == Phase.Listening) wave + lvl * 0.35f else 1f).clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)),
                )
                Surface(onClick = vm::stop, shape = CircleShape, color = MaterialTheme.colorScheme.primary, modifier = Modifier.size(54.dp)) {
                    Box(contentAlignment = Alignment.Center) { Icon(Icons.Rounded.Stop, TR("إنهاء", "Beenden"), tint = MaterialTheme.colorScheme.onPrimary) }
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
    val judged = res.count { it != null }
    val pct = if (judged == 0) 0 else correct * 100 / judged
    Spacer(Modifier.height(12.dp))
    Box(Modifier.appear()) {
    Surface(shape = MaterialTheme.shapes.extraLarge, color = MaterialTheme.colorScheme.surfaceContainer) {
        Column(Modifier.fillMaxWidth().padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(TR("نتيجة التسميع", "Tasmee-Ergebnis"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(12.dp))
            Box(contentAlignment = Alignment.Center) {
                val a by animateFloatAsState(pct / 100f, tween(900), label = "pct")
                CircularProgressIndicator(progress = { a }, modifier = Modifier.size(96.dp), strokeWidth = 8.dp, trackColor = MaterialTheme.colorScheme.surfaceContainerHighest)
                Text(TR("${pct.ar()}٪", "${pct.ar()} %"), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                Stat(correct, TR("صحيحة", "Richtig"), MaterialTheme.colorScheme.primary)
                Stat(wrong, TR("أخطاء", "Fehler"), WrongRed)
                Stat(missed, TR("فائتة", "Ausgelassen"), MissedRed)
                Stat(vm.hinted.size, TR("تلميحات", "Hinweise"), MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(
                TR("${vm.pointer.ar()} من ${vm.words.size.ar()} كلمة • ${clock(vm.elapsedMs)}", "${vm.pointer.ar()} von ${vm.words.size.ar()} Wörtern • ${clock(vm.elapsedMs)}"),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 8.dp),
            )
            val mistakes = res.withIndex().filter { it.value != null && it.value!!.mark != Mark.Correct }
            if (mistakes.isNotEmpty()) {
                HorizontalDivider(Modifier.padding(vertical = 12.dp))
                Text(TR("الأخطاء", "Fehler"), style = MaterialTheme.typography.titleMedium, modifier = Modifier.fillMaxWidth())
                mistakes.forEach { (i, r) ->
                    val w = vm.words[i]
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(TR("آية ${w.ayah.ar()}", "Vers ${w.ayah.ar()}"), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.width(64.dp))
                        Text(w.text, fontFamily = QpcFont, fontSize = 22.sp, color = MaterialTheme.colorScheme.primary, modifier = Modifier.weight(1f))
                        Text(
                            if (r!!.mark == Mark.Missed) TR("لم تُقرأ", "Nicht gelesen") else TR("قرأت: ${r.heard.orEmpty()}", "Gelesen: ${r.heard.orEmpty()}"),
                            style = MaterialTheme.typography.bodySmall, color = if (r.mark == Mark.Missed) MissedRed else WrongRed,
                        )
                    }
                }
            }
            Spacer(Modifier.height(14.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = vm::restart) {
                    Icon(Icons.Rounded.Refresh, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(TR("إعادة", "Wiederholen"))
                }
                OutlinedButton(onClick = vm::backToSetup) { Text(TR("مقطع آخر", "Anderer Abschnitt")) }
            }
            if (vm.pointer < vm.words.size && !revealed) TextButton(onClick = onRevealAll) { Text(TR("إظهار بقية المقطع", "Rest des Abschnitts zeigen")) }
        }
    }
    if (judged > 0 && pct >= 80) Confetti(Modifier.matchParentSize())
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

@Composable
private fun ModelRow(title: String, size: String, d: TasmeeViewModel.Download) {
    val p = d.progress
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium)
            Text(
                when {
                    p != null -> TR("جارٍ التنزيل… ${(p * 100).toInt().ar()}٪", "Wird geladen… ${(p * 100).toInt().ar()} %")
                    d.ready -> TR("منزّل على الجهاز ويعمل دون إنترنت", "Auf dem Gerät gespeichert, funktioniert offline")
                    else -> TR("غير منزّل • $size مرة واحدة", "Nicht geladen • einmalig $size")
                },
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (p != null) androidx.compose.material3.LinearProgressIndicator(progress = { p }, modifier = Modifier.fillMaxWidth().padding(top = 4.dp))
        }
        Spacer(Modifier.width(8.dp))
        when {
            p != null -> androidx.compose.material3.TextButton(onClick = d::cancel) { Text(TR("إلغاء", "Abbrechen")) }
            d.ready -> androidx.compose.material3.TextButton(onClick = d::delete) { Text(TR("حذف", "Löschen")) }
            else -> FilledTonalButton(onClick = d::start) { Text(TR("تنزيل", "Herunterladen")) }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TasmeeSettingsSheet(vm: TasmeeViewModel, st: TasmeeSettings, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
            Text(TR("إعدادات التسميع", "Tasmee-Einstellungen"), style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(horizontal = 20.dp))
            Choice(TR("المستمع (الذكاء الاصطناعي)", "Zuhörer (KI)"), listOf("Whisper", TR("مباشر ١", "Live 1"), TR("مباشر ٢", "Live 2")), st.engine) {
                when {
                    it == 0 && !vm.whisper.ready -> vm.whisper.start()
                    it == 2 && !vm.fast.ready -> vm.fast.start()
                    else -> vm.setEngine(it)
                }
            }
            ModelRow(TR("مباشر ٢: FastConformer", "Live 2: FastConformer"), TR("١٣٢ م.ب", "132 MB"), vm.fast)
            ModelRow(TR("Whisper (أبطأ)", "Whisper (langsamer)"), TR("٨١ م.ب", "81 MB"), vm.whisper)
            Text(
                if (st.engine == 1) TR("مباشر ١ (مدمج): نموذج Quran-Lab zipformer_p-arabic-v3 يسمع الأصوات لحظة بلحظة على الجهاز (رخصة غير ربحية).", "Live 1 (integriert): Modell Quran-Lab zipformer_p-arabic-v3 hört die Laute in Echtzeit auf dem Gerät (nicht-kommerzielle Lizenz).")
                else if (st.engine == 2) TR("مباشر ٢: نموذج FastConformer للقرآن، يكتب الكلمات كل ثانية تقريباً على الجهاز.", "Live 2: FastConformer-Modell für den Koran, schreibt die Wörter etwa jede Sekunde auf dem Gerät.")
                else TR("Whisper: نموذج tarteel-ai/whisper-base-ar-quran، يصحح بعد نحو ثانية.", "Whisper: Modell tarteel-ai/whisper-base-ar-quran, korrigiert nach etwa einer Sekunde."),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 20.dp),
            )
            Text(
                TR("التصحيح الآلي قد يخطئ ولا يغني عن معلّم متقن.", "Die automatische Korrektur kann sich irren und ersetzt keinen kundigen Lehrer."),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
            )
            Choice(TR("فواصل الآيات", "Verstrenner"), listOf(TR("بالرقم", "Mit Nummer"), TR("بدون رقم", "Ohne Nummer"), TR("مخفية", "Versteckt")), st.ayahMark) { vm.setPref(TasmeePrefs.Keys.ayahMark, it) }
            Choice(TR("دقة التصحيح", "Korrekturstrenge"), listOf(TR("متساهل", "Locker"), TR("متوسط", "Mittel"), TR("دقيق", "Streng")), st.strictness) { vm.setPref(TasmeePrefs.Keys.strictness, it) }
            Choice(TR("عند الخطأ", "Bei Fehler"), listOf(TR("تابع وعلّم الخطأ", "Weiter und markieren"), TR("توقف للتصحيح", "Zum Korrigieren anhalten")), st.onMistake) { vm.setPref(TasmeePrefs.Keys.onMistake, it) }
            Choice(TR("التلميح", "Hinweis"), listOf(TR("بدون", "Ohne"), TR("زر تلميح", "Hinweis-Taste"), TR("الكلمة التالية باهتة", "Nächstes Wort blass")), st.hint) { vm.setPref(TasmeePrefs.Keys.hint, it) }
            if (st.engine == 0) Section(TR("تثبيت آخر كلمة بعد سكوت: ", "Letztes Wort fixieren nach Pause: ") + "${"%.1f".format(st.pauseSec)} " + TR("ث", "s")) {
                var v by remember(st.pauseSec) { mutableFloatStateOf(st.pauseSec) }
                Slider(v, { v = it }, valueRange = 0.5f..2f, steps = 14, onValueChangeFinished = { vm.setPref(TasmeePrefs.Keys.pauseSec, v) })
                Text(TR("المدة التي ينتظرها التطبيق بعد توقفك قبل أن يثبّت التصحيح.", "Wie lange die App nach deiner Pause wartet, bevor sie die Korrektur festlegt."), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Section(TR("حجم الخط", "Schriftgröße")) {
                var v by remember(st.fontSize) { mutableFloatStateOf(st.fontSize) }
                Slider(v, { v = it }, valueRange = 22f..44f, steps = 10, onValueChangeFinished = { vm.setPref(TasmeePrefs.Keys.fontSize, v) })
                Surface(color = LocalPageColors.current.page, shape = MaterialTheme.shapes.medium) {
                    Text("ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ", Modifier.fillMaxWidth().padding(8.dp), fontFamily = QpcFont, fontSize = v.sp, textAlign = TextAlign.Center, color = LocalPageColors.current.text)
                }
            }
            Section(TR("خيارات", "Optionen")) {
                SwitchRow(TR("ابدأ التسميع التلقائي عند فتح الصفحة", "Automatisches Tasmee beim Öffnen starten"), st.autoStart) { vm.setPref(TasmeePrefs.Keys.autoStart, it) }
                SwitchRow(TR("إخفاء الآيات في التسميع التلقائي", "Verse im automatischen Tasmee verbergen"), st.autoHidden) { vm.setPref(TasmeePrefs.Keys.autoHidden, it) }
                SwitchRow(TR("اهتزاز عند الخطأ", "Bei Fehler vibrieren"), st.vibrate) { vm.setPref(TasmeePrefs.Keys.vibrate, it) }
                SwitchRow(TR("إظهار ما قرأتَه تحت الكلمة الخاطئة أو الفائتة", "Gelesenes unter falschen oder ausgelassenen Wörtern anzeigen"), st.showHeard) { vm.setPref(TasmeePrefs.Keys.showHeard, it) }
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

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun RtlFlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    content: @Composable androidx.compose.foundation.layout.FlowRowScope.() -> Unit,
) {
    androidx.compose.runtime.CompositionLocalProvider(androidx.compose.ui.platform.LocalLayoutDirection provides androidx.compose.ui.unit.LayoutDirection.Rtl) {
        FlowRow(modifier, horizontalArrangement, verticalArrangement, content = content)
    }
}
