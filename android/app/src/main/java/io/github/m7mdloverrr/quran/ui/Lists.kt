package io.github.m7mdloverrr.quran.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.Surah
import io.github.m7mdloverrr.quran.data.ar

@Composable
fun NumberBadge(n: Int, modifier: Modifier = Modifier) {
    Box(modifier.size(42.dp), contentAlignment = Alignment.Center) {
        Box(Modifier.size(30.dp).rotate(45f).border(1.5.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(7.dp)))
        Box(Modifier.size(30.dp).border(1.5.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.45f), RoundedCornerShape(7.dp)))
        Text(n.ar(), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
    }
}

@Composable
fun SurahRow(surah: Surah, onClick: () -> Unit, trailing: @Composable () -> Unit = {
    Text("ص ${surah.startPage.ar()}", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
}) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        NumberBadge(surah.number)
        Column(Modifier.weight(1f)) {
            Text(surah.name, fontFamily = QuranFont, fontSize = 21.sp, color = MaterialTheme.colorScheme.onSurface)
            Text(
                "${if (surah.isMeccan) "مكية" else "مدنية"} • ${surah.ayahs.size.ar()} آية • ${surah.englishName}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        trailing()
    }
}

@Composable
fun SurahList(quran: Quran, onOpen: (Surah) -> Unit) {
    LazyColumn(contentPadding = PaddingValues(bottom = 24.dp)) { surahItems(quran, onOpen) }
}

fun LazyListScope.surahItems(quran: Quran, onOpen: (Surah) -> Unit) {
    items(quran.surahs, key = { "s${it.number}" }) { s ->
        SurahRow(s, { onOpen(s) })
        HorizontalDivider(Modifier.padding(start = 72.dp), color = MaterialTheme.colorScheme.outlineVariant)
    }
}

@Composable
fun JuzList(quran: Quran, onOpenPage: (Int) -> Unit) {
    LazyColumn(contentPadding = PaddingValues(bottom = 24.dp)) { juzItems(quran, onOpenPage) }
}

fun LazyListScope.juzItems(quran: Quran, onOpenPage: (Int) -> Unit) {
    items(quran.juzStart.size, key = { "j$it" }) { i ->
        val a = quran.juzStart[i]
        Row(
            Modifier.fillMaxWidth().clickable { onOpenPage(a.page) }.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            NumberBadge(i + 1)
            Column(Modifier.weight(1f)) {
                Text("الجزء ${(i + 1).ar()}", style = MaterialTheme.typography.titleMedium)
                Text(
                    a.text.split(" ").take(5).joinToString(" "),
                    fontFamily = QuranFont, fontSize = 16.sp, maxLines = 1,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    "${quran.surah(a.surah).name} • الآية ${a.number.ar()}",
                    style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text("ص ${a.page.ar()}", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        HorizontalDivider(Modifier.padding(start = 72.dp), color = MaterialTheme.colorScheme.outlineVariant)
    }
}
