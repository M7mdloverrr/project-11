package io.github.m7mdloverrr.quran.ui

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.audio.DownloadWorker
import io.github.m7mdloverrr.quran.data.Reciters
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DownloadsScreen(vm: AppViewModel, onBack: () -> Unit) {
    val settings by vm.settings.collectAsStateWithLifecycle()
    val quran by vm.quran.collectAsStateWithLifecycle()
    val downloads by vm.downloads.collectAsStateWithLifecycle()
    val bytes by vm.cacheBytes.collectAsStateWithLifecycle()
    val st = settings
    val q = quran
    var reciterId by remember { mutableStateOf<String?>(null) }
    var confirmDelete by remember { mutableStateOf(false) }
    LaunchedEffect(downloads.size, st?.downloaded) { vm.refreshCacheSize() }
    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text("التحميل للاستماع دون اتصال") },
            navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, "رجوع") } },
        )
    }) { pad ->
        if (st == null || q == null) return@Scaffold Loading()
        val reciter = Reciters.byId(reciterId ?: st.reciter.id)
        val doneCount = q.surahs.count { "${reciter.id}:${it.number}" in st.downloaded }
        LazyColumn(Modifier.padding(pad), contentPadding = PaddingValues(bottom = 24.dp)) {
            item {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Reciters.all.forEach { r ->
                            FilterChip(selected = r.id == reciter.id, onClick = { reciterId = r.id }, label = { Text(r.nameAr) })
                        }
                    }
                    Text(
                        "تم تحميل $doneCount من 114 سورة • المساحة المستخدمة: ${String.format(Locale.US, "%.1f", bytes / 1_048_576.0)} ميجابايت",
                        style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        "الآيات التي تستمع إليها تُحفظ تلقائيًا أيضًا للاستماع لاحقًا دون اتصال.",
                        style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { vm.downloadAll(reciter) }, enabled = doneCount < 114) { Text("تحميل المصحف كاملًا") }
                        OutlinedButton(onClick = { confirmDelete = true }) { Text("حذف التحميلات") }
                    }
                }
            }
            items(q.surahs, key = { it.number }) { s ->
                val key = "${reciter.id}:${s.number}"
                val job = downloads[DownloadWorker.name(reciter.id, s.number)]
                SurahRow(s, onClick = { if (key !in st.downloaded && job == null) vm.download(reciter, s) }) {
                    when {
                        key in st.downloaded -> Icon(Icons.Rounded.CheckCircle, "تم التحميل", tint = MaterialTheme.colorScheme.primary)
                        job != null && job.running -> CircularProgressIndicator(progress = { job.progress }, modifier = Modifier.size(28.dp))
                        job != null -> CircularProgressIndicator(Modifier.size(28.dp), strokeWidth = 2.dp)
                        else -> IconButton(onClick = { vm.download(reciter, s) }) { Icon(Icons.Rounded.Download, "تحميل") }
                    }
                }
                HorizontalDivider(Modifier.padding(start = 72.dp), color = MaterialTheme.colorScheme.outlineVariant)
            }
        }
        if (confirmDelete) {
            AlertDialog(
                onDismissRequest = { confirmDelete = false },
                icon = { Icon(Icons.Rounded.Delete, null) },
                title = { Text("حذف تلاوات ${reciter.nameAr}؟") },
                text = { Text("سيتم حذف جميع الملفات المحفوظة لهذا القارئ من جهازك.") },
                confirmButton = { TextButton(onClick = { confirmDelete = false; vm.deleteDownloads(reciter) }) { Text("حذف") } },
                dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("إلغاء") } },
            )
        }
    }
}
