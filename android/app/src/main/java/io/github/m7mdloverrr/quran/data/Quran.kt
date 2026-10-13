package io.github.m7mdloverrr.quran.data

import android.content.Context
import android.util.JsonReader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStreamReader
import java.util.Locale

class Ayah(
    val surah: Int,
    val number: Int,
    val text: String,
    val juz: Int,
    val page: Int,
    val hizbQuarter: Int,
    val sajda: Boolean,
) {
    val key get() = "$surah:$number"
}

class Surah(
    val number: Int,
    val name: String,
    val englishName: String,
    val translation: String,
    val revelation: String,
    val ayahs: List<Ayah>,
) {
    val startPage get() = ayahs.first().page
    val isMeccan get() = revelation == "Meccan"
    val hasBasmala get() = number != 1 && number != 9
}

class Quran(val basmala: String, val surahs: List<Surah>) {
    private val all = surahs.flatMap { it.ayahs }
    val pages: List<List<Ayah>> = all.groupBy { it.page }.toSortedMap().values.toList()
    val juzStart: List<Ayah> = all.groupBy { it.juz }.toSortedMap().values.map { it.first() }
    fun surah(n: Int) = surahs[n - 1]
    fun ayah(s: Int, a: Int) = surahs[s - 1].ayahs[a.coerceIn(1, surahs[s - 1].ayahs.size) - 1]
    fun ayahOrNull(key: String): Ayah? {
        val p = key.split(":")
        val s = p.getOrNull(0)?.toIntOrNull() ?: return null
        val a = p.getOrNull(1)?.toIntOrNull() ?: return null
        return surahs.getOrNull(s - 1)?.ayahs?.getOrNull(a - 1)
    }
}

object QuranRepository {
    @Volatile private var cached: Quran? = null

    suspend fun load(context: Context): Quran = cached ?: withContext(Dispatchers.IO) {
        synchronized(this@QuranRepository) { cached ?: parse(context).also { cached = it } }
    }

    private fun parse(context: Context): Quran =
        JsonReader(InputStreamReader(context.assets.open("quran.json"), Charsets.UTF_8)).use { r ->
            var basmala = ""
            val surahs = ArrayList<Surah>(114)
            r.beginObject()
            while (r.hasNext()) when (r.nextName()) {
                "basmala" -> basmala = r.nextString()
                "surahs" -> {
                    r.beginArray()
                    while (r.hasNext()) surahs += readSurah(r)
                    r.endArray()
                }
                else -> r.skipValue()
            }
            r.endObject()
            Quran(basmala, surahs)
        }

    private fun readSurah(r: JsonReader): Surah {
        var n = 0
        var name = ""
        var en = ""
        var tr = ""
        var type = ""
        val ayahs = ArrayList<Ayah>()
        r.beginObject()
        while (r.hasNext()) when (r.nextName()) {
            "n" -> n = r.nextInt()
            "name" -> name = r.nextString()
            "en" -> en = r.nextString()
            "tr" -> tr = r.nextString()
            "type" -> type = r.nextString()
            "ayahs" -> {
                r.beginArray()
                while (r.hasNext()) {
                    r.beginArray()
                    val text = r.nextString()
                    val juz = r.nextInt()
                    val page = r.nextInt()
                    val hq = r.nextInt()
                    val sajda = r.nextInt() == 1
                    r.endArray()
                    ayahs += Ayah(n, ayahs.size + 1, text, juz, page, hq, sajda)
                }
                r.endArray()
            }
            else -> r.skipValue()
        }
        r.endObject()
        return Surah(n, name, en, tr, type, ayahs)
    }
}

class Reciter(val id: String, val nameAr: String, val nameEn: String, val folder: String) {
    fun url(surah: Int, ayah: Int) =
        String.format(Locale.US, "https://everyayah.com/data/%s/%03d%03d.mp3", folder, surah, ayah)
}

object Reciters {
    val all = listOf(
        Reciter("maher", "ماهر المعيقلي", "Maher Al-Muaiqly", "MaherAlMuaiqly128kbps"),
        Reciter("alafasy", "مشاري العفاسي", "Mishary Alafasy", "Alafasy_128kbps"),
        Reciter("sudais", "عبد الرحمن السديس", "Abdul Rahman Al-Sudais", "Abdurrahmaan_As-Sudais_192kbps"),
        Reciter("basit", "عبد الباسط عبد الصمد", "Abdul Basit Abdul Samad", "Abdul_Basit_Murattal_192kbps"),
        Reciter("minshawi", "محمد صديق المنشاوي", "Muhammad Siddiq Al-Minshawi", "Minshawy_Murattal_128kbps"),
    )

    fun byId(id: String?) = all.firstOrNull { it.id == id } ?: all[0]
}

fun Int.ar(): String = toString().map { if (it.isDigit()) (it - '0' + 0x0660).toChar() else it }.joinToString("")

object GermanRepository {
    @Volatile private var cached: List<List<String>>? = null

    suspend fun load(context: Context): List<List<String>> = cached ?: withContext(Dispatchers.IO) {
        synchronized(this@GermanRepository) { cached ?: parse(context).also { cached = it } }
    }

    private fun parse(context: Context): List<List<String>> =
        JsonReader(InputStreamReader(context.assets.open("de_bubenheim.json"), Charsets.UTF_8)).use { r ->
            val out = ArrayList<List<String>>(114)
            r.beginObject()
            while (r.hasNext()) {
                if (r.nextName() == "s") {
                    r.beginArray()
                    while (r.hasNext()) {
                        val ayahs = ArrayList<String>()
                        r.beginArray()
                        while (r.hasNext()) ayahs.add(r.nextString())
                        r.endArray()
                        out.add(ayahs)
                    }
                    r.endArray()
                } else r.skipValue()
            }
            r.endObject()
            out
        }
}
