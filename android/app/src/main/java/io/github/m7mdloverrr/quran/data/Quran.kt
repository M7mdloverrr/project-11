package io.github.m7mdloverrr.quran.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf

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

/** Verse-file reciters use EveryAyah; reciters with [surahBase] stream whole-surah files clipped by [timing]. */
class Reciter(
    val id: String,
    val nameAr: String,
    val nameEn: String,
    val folder: String,
    val surahBase: String? = null,
    val timing: String? = null,
) {
    fun url(surah: Int, ayah: Int) =
        if (surahBase != null) String.format(Locale.US, "%s%03d.mp3", surahBase, surah)
        else String.format(Locale.US, "https://everyayah.com/data/%s/%03d%03d.mp3", folder, surah, ayah)
}

object Reciters {
    val all = listOf(
        Reciter("maher", "ماهر المعيقلي", "Maher Al-Muaiqly", "MaherAlMuaiqly128kbps"),
        Reciter("alafasy", "مشاري العفاسي", "Mishary Alafasy", "Alafasy_128kbps"),
        Reciter("sudais", "عبد الرحمن السديس", "Abdul Rahman Al-Sudais", "Abdurrahmaan_As-Sudais_192kbps"),
        Reciter("basit", "عبد الباسط عبد الصمد", "Abdul Basit Abdul Samad", "Abdul_Basit_Murattal_192kbps"),
        Reciter("minshawi", "محمد صديق المنشاوي", "Muhammad Siddiq Al-Minshawi", "Minshawy_Murattal_128kbps"),
        Reciter("husary", "محمود خليل الحصري", "Mahmoud Khalil Al-Husary", "Husary_128kbps"),
        Reciter("husary_mj", "الحصري (مجوّد)", "Al-Husary (Mujawwad)", "Husary_Mujawwad_64kbps"),
        Reciter("minshawi_mj", "المنشاوي (مجوّد)", "Al-Minshawi (Mujawwad)", "Minshawy_Mujawwad_192kbps"),
        Reciter("ajamy", "أحمد العجمي", "Ahmed Al-Ajamy", "Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net"),
        Reciter("shuraim", "سعود الشريم", "Saud Al-Shuraim", "Saood_ash-Shuraym_128kbps"),
        Reciter("ghamdi", "سعد الغامدي", "Saad Al-Ghamdi", "Ghamadi_40kbps"),
        Reciter("dossari", "ياسر الدوسري", "Yasser Al-Dossari", "Yasser_Ad-Dussary_128kbps"),
        Reciter("hudhaify", "علي الحذيفي", "Ali Al-Hudhaify", "Hudhaify_128kbps"),
        Reciter("shatri", "أبو بكر الشاطري", "Abu Bakr Al-Shatri", "Abu_Bakr_Ash-Shaatree_128kbps"),
        Reciter("ayyoub", "محمد أيوب", "Muhammad Ayyoub", "Muhammad_Ayyoub_128kbps"),
        Reciter("qatami", "ناصر القطامي", "Nasser Al-Qatami", "Nasser_Alqatami_128kbps"),
        Reciter("jaber", "علي جابر", "Ali Jaber", "Ali_Jaber_64kbps"),
        Reciter("abbad", "فارس عباد", "Fares Abbad", "Fares_Abbad_64kbps"),
        Reciter("basfar", "عبد الله بصفر", "Abdullah Basfar", "Abdullah_Basfar_192kbps"),
        Reciter("budair", "صلاح البدير", "Salah Al-Budair", "Salah_Al_Budair_128kbps"),
        Reciter("rifai", "هاني الرفاعي", "Hani Ar-Rifai", "Hani_Rifai_192kbps"),
        Reciter(
            "sufi_hafs", "عبد الرشيد صوفي (حفص عن عاصم)", "Abdul Rashid Sufi (Hafs)", "abdulrasheed-sufi/r3",
            "https://cdn.mp3quran.net/audio/abdulrasheed-sufi/r3/", "timing_sufi_hafs.json",
        ),
        Reciter(
            "mousa_hafs", "عبدالله الموسى", "Abdullah Al-Mousa", "abdullah-mousa/r1",
            "https://cdn.mp3quran.net/audio/abdullah-mousa/r1/", "timing_mousa_hafs.json",
        ),
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


class QuranScript(val nameAr: String, val asset: String?)

object Scripts {
    val all = listOf(
        QuranScript("الرسم العثماني • مجمع الملك فهد", "script_qpc.json"),
        QuranScript("الرسم العثماني • تنزيل", null),
        QuranScript("الرسم الإملائي", "script_imlaei.json"),
        QuranScript("الرسم الهندي/الباكستاني", "script_indopak.json"),
    )
    var index by mutableIntStateOf(0)
        private set
    var texts by mutableStateOf<List<List<String>>?>(null)
        private set
    private val cache = HashMap<Int, List<List<String>>>()

    suspend fun select(context: Context, i: Int) {
        val asset = all.getOrNull(i)?.asset
        texts = asset?.let { a ->
            cache[i] ?: withContext(Dispatchers.IO) {
                val arr = org.json.JSONObject(context.assets.open(a).bufferedReader().readText()).getJSONArray("s")
                List(arr.length()) { si -> arr.getJSONArray(si).let { sa -> List(sa.length()) { sa.getString(it) } } }
            }.also { cache[i] = it }
        }
        index = i
    }
}

val Ayah.shown: String get() = Scripts.texts?.getOrNull(surah - 1)?.getOrNull(number - 1) ?: text
val Quran.shownBasmala: String get() = Scripts.texts?.getOrNull(0)?.getOrNull(0) ?: basmala

/** Start/end (ms) of each ayah inside a whole-surah recording, from bundled mp3quran.net timing data. */
object AyahTimings {
    private val cache = HashMap<String, List<LongArray>>()

    fun clip(context: Context, reciter: Reciter, surah: Int, ayah: Int): Pair<Long, Long>? {
        val asset = reciter.timing ?: return null
        val all = synchronized(cache) {
            cache.getOrPut(asset) {
                val arr = org.json.JSONObject(context.assets.open(asset).bufferedReader().readText()).getJSONArray("s")
                List(arr.length()) { i -> arr.getJSONArray(i).let { a -> LongArray(a.length()) { a.getLong(it) } } }
            }
        }
        val t = all.getOrNull(surah - 1) ?: return null
        val i = (ayah - 1) * 2
        return if (i < 0 || i + 1 >= t.size) null else t[i] to t[i + 1]
    }
}
