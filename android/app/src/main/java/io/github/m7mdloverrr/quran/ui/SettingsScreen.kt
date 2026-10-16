package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.Scripts
import io.github.m7mdloverrr.quran.data.shownBasmala

import io.github.m7mdloverrr.quran.data.Tafsirs

import io.github.m7mdloverrr.quran.data.Prefs
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.data.Reciters
import io.github.m7mdloverrr.quran.data.ar

@Composable
fun Section(title: String, content: @Composable () -> Unit) {
    Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(bottom = 6.dp))
        Surface(shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainer) {
            Column(Modifier.fillMaxWidth().padding(12.dp)) { content() }
        }
    }
}

@Composable
fun SwitchRow(text: String, value: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onChange(!value) }.padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(text, Modifier.weight(1f))
        Switch(value, onChange)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(vm: AppViewModel, onBack: () -> Unit) {
    val settings by vm.settings.collectAsStateWithLifecycle()
    val quran by vm.quran.collectAsStateWithLifecycle()
    val st = settings ?: return Loading()
    val uri = LocalUriHandler.current
    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text("الإعدادات") },
            navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "رجوع") } },
        )
    }) { pad ->
        Column(Modifier.padding(pad).verticalScroll(rememberScrollState())) {
            Section("القارئ") {
                Reciters.all.forEach { r ->
                    Row(
                        Modifier.fillMaxWidth().clickable { vm.setReciter(r) }.padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = st.reciter.id == r.id, onClick = { vm.setReciter(r) })
                        Column {
                            Text(r.nameAr, style = MaterialTheme.typography.bodyLarge)
                            Text(r.nameEn, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
            Section("المظهر") {
                val labels = listOf("تلقائي", "فاتح", "داكن")
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    labels.forEachIndexed { i, l ->
                        SegmentedButton(st.theme == i, { vm.setTheme(i) }, SegmentedButtonDefaults.itemShape(i, labels.size)) { Text(l) }
                    }
                }
            }
            Section("حجم خط المصحف") {
                var size by remember(st.fontSize) { mutableFloatStateOf(st.fontSize) }
                Slider(size, { size = it }, valueRange = 18f..44f, steps = 12, onValueChangeFinished = { vm.setFontSize(size) })
                Surface(color = LocalPageColors.current.page, shape = MaterialTheme.shapes.medium) {
                    Text(
                        quran?.shownBasmala ?: "",
                        Modifier.fillMaxWidth().padding(vertical = 8.dp), fontFamily = AyahFont, fontSize = size.sp, textAlign = TextAlign.Center,
                        color = LocalPageColors.current.text,
                    )
                }
            }
            Section("رسم المصحف") {
                Scripts.all.forEachIndexed { i, sc ->
                    Row(Modifier.fillMaxWidth().clickable { vm.setPref(Prefs.Keys.script, i) }, verticalAlignment = Alignment.CenterVertically) {
                        RadioButton(selected = st.script == i, onClick = { vm.setPref(Prefs.Keys.script, i) })
                        Text(sc.nameAr, style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }
            if (ScriptFonts.getOrNull(st.script) == null) Section("خط المصحف") {
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    QuranFonts.forEachIndexed { i, (name, family) ->
                        SegmentedButton(st.quranFont == i, { vm.setPref(Prefs.Keys.quranFont, i) }, SegmentedButtonDefaults.itemShape(i, QuranFonts.size)) {
                            Text(name, fontFamily = family, fontSize = 13.sp, maxLines = 1)
                        }
                    }
                }
            }
            Section("وضوح خلفية التطبيق") {
                var a by remember(st.bgAlpha) { mutableFloatStateOf(st.bgAlpha) }
                Slider(a, { a = it }, valueRange = 0f..0.7f, onValueChangeFinished = { vm.setPref(Prefs.Keys.bgAlpha, a) })
            }
            Section("القراءة") {
                Text("لون صفحة المصحف", style = MaterialTheme.typography.bodyMedium)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    PageStyleNames.forEachIndexed { i, l ->
                        SegmentedButton(st.pageStyle == i, { vm.setPref(Prefs.Keys.pageStyle, i) }, SegmentedButtonDefaults.itemShape(i, PageStyleNames.size)) { Text(l, fontSize = 11.sp, maxLines = 1) }
                    }
                }
                Text("تباعد الأسطر", style = MaterialTheme.typography.bodyMedium)
                val spacings = listOf(1.7f to "ضيق", 2.05f to "عادي", 2.4f to "واسع")
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    spacings.forEachIndexed { i, (v, l) ->
                        SegmentedButton(st.lineSpacing == v, { vm.setPref(Prefs.Keys.lineSpacing, v) }, SegmentedButtonDefaults.itemShape(i, spacings.size)) { Text(l) }
                    }
                }
                SwitchRow("إبقاء الشاشة مضاءة أثناء القراءة", st.keepScreenOn) { vm.setPref(Prefs.Keys.keepScreenOn, it) }
                SwitchRow("متابعة الآية المتلوة تلقائيًا", st.follow) { vm.setPref(Prefs.Keys.follow, it) }
            }
            Section("التفسير (اضغط مطولًا على الآية)") {
                Tafsirs.all.forEachIndexed { i, t ->
                    Row(
                        Modifier.fillMaxWidth().clickable { vm.setPref(Prefs.Keys.tafsir, i) },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = st.tafsir == i, onClick = { vm.setPref(Prefs.Keys.tafsir, i) })
                        Text(t.nameAr + if (i == 0) " • بدون إنترنت" else "", style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }
            Section("الترجمة الألمانية (Deutsch)") {
                val modes = listOf("إيقاف", "فقاعة", "تحت كل آية")
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    modes.forEachIndexed { i, l ->
                        SegmentedButton(st.germanMode == i, { vm.setPref(Prefs.Keys.germanMode, i) }, SegmentedButtonDefaults.itemShape(i, modes.size)) { Text(l, fontSize = 12.sp, maxLines = 1) }
                    }
                }
                Text(
                    "فقاعة: تظهر الترجمة عند الضغط على الآية • تحت كل آية: عرض مقسوم عربي / ألماني",
                    Modifier.padding(top = 6.dp), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Section("التلاوة") {
                Text("سرعة التلاوة", style = MaterialTheme.typography.bodyMedium)
                val speeds = listOf(0.75f, 1f, 1.25f, 1.5f, 2f)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    speeds.forEachIndexed { i, v ->
                        SegmentedButton(st.speed == v, { vm.setSpeed(v) }, SegmentedButtonDefaults.itemShape(i, speeds.size)) { Text("${v}x", fontSize = 12.sp) }
                    }
                }
                Text("تكرار كل آية", style = MaterialTheme.typography.bodyMedium)
                val reps = listOf(1, 2, 3, 5, 0)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                    reps.forEachIndexed { i, v ->
                        SegmentedButton(st.repeat == v, { vm.setRepeat(v) }, SegmentedButtonDefaults.itemShape(i, reps.size)) { Text(if (v == 0) "∞" else v.ar()) }
                    }
                }
                SwitchRow("متابعة التشغيل إلى السورة التالية", st.continuous) { vm.setContinuous(it) }
                SwitchRow("استمرار التلاوة بعد الخروج من صفحة المصحف", st.backgroundPlay) { vm.setPref(Prefs.Keys.backgroundPlay, it) }
            }
            Section("عن التطبيق") {
                Text("المطور: محمد صالح المحمد", style = MaterialTheme.typography.bodyMedium)
                Text("Entwickler: Mouhamad Almuhamad", style = MaterialTheme.typography.bodyMedium)
            }
            Section("المصادر") {
                Text(
                    "نص القرآن الكريم: مشروع تنزيل (Tanzil Project) — رسم عثماني، منقول حرفيًا دون أي تعديل. " +
                        "Tanzil Quran Text, Copyright (C) 2007-2021 Tanzil Project, CC BY 3.0.",
                    style = MaterialTheme.typography.bodySmall,
                )
                Text("tanzil.net", Modifier.clickable { uri.openUri("https://tanzil.net/") }.padding(vertical = 4.dp), color = MaterialTheme.colorScheme.primary)
                Text("التلاوات (آية بآية): EveryAyah.com", style = MaterialTheme.typography.bodySmall)
                Text("everyayah.com", Modifier.clickable { uri.openUri("https://everyayah.com/") }.padding(vertical = 4.dp), color = MaterialTheme.colorScheme.primary)
                Text("خط المصحف: Amiri Quran (SIL Open Font License)", style = MaterialTheme.typography.bodySmall)
                Text("Deutsche Übersetzung: A. S. F. Bubenheim & N. Elyas (via Tanzil.net)", style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
