package io.github.m7mdloverrr.quran.data

import android.content.Context
import androidx.core.text.HtmlCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class Tafsir(val nameAr: String, val quranComId: Int? = null, val alquranCloud: String? = null)

object Tafsirs {
    val all = listOf(
        Tafsir("التفسير الميسر"),
        Tafsir("تفسير الجلالين", alquranCloud = "ar.jalalayn"),
        Tafsir("تفسير السعدي", quranComId = 91),
        Tafsir("تفسير ابن كثير", quranComId = 14),
        Tafsir("تفسير الطبري", quranComId = 15),
        Tafsir("تفسير القرطبي", quranComId = 90),
        Tafsir("تفسير البغوي", quranComId = 94),
        Tafsir("التفسير الوسيط (طنطاوي)", quranComId = 93),
    )

    @Volatile private var muyassar: List<List<String>>? = null

    suspend fun text(context: Context, index: Int, surah: Int, ayah: Int): String = withContext(Dispatchers.IO) {
        val t = all.getOrElse(index) { all[0] }
        if (t.quranComId == null && t.alquranCloud == null) return@withContext muyassar(context)[surah - 1][ayah - 1]
        val file = File(context.filesDir, "tafsir/$index/${surah}_$ayah.txt")
        if (file.exists()) return@withContext file.readText()
        val url = if (t.alquranCloud != null) "https://api.alquran.cloud/v1/ayah/$surah:$ayah/${t.alquranCloud}"
        else "https://api.quran.com/api/v4/tafsirs/${t.quranComId}/by_ayah/$surah:$ayah"
        val conn = URL(url).openConnection() as HttpURLConnection
        val body = try {
            conn.connectTimeout = 10_000
            conn.readTimeout = 20_000
            conn.inputStream.bufferedReader().readText()
        } finally {
            conn.disconnect()
        }
        val json = JSONObject(body)
        val raw = if (t.alquranCloud != null) json.getJSONObject("data").getString("text")
        else json.getJSONObject("tafsir").getString("text")
        val text = HtmlCompat.fromHtml(raw, HtmlCompat.FROM_HTML_MODE_LEGACY).toString().trim()
        if (text.isNotEmpty()) {
            file.parentFile?.mkdirs()
            file.writeText(text)
        }
        text
    }

    private fun muyassar(context: Context): List<List<String>> = muyassar ?: synchronized(this) {
        muyassar ?: run {
            val s = JSONObject(context.assets.open("tafsir_muyassar.json").bufferedReader().readText()).getJSONArray("s")
            List(s.length()) { i -> s.getJSONArray(i).let { a -> List(a.length()) { a.getString(it) } } }
        }.also { muyassar = it }
    }
}
