package io.github.m7mdloverrr.quran.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore("settings")

data class Settings(
    val reciter: Reciter,
    val fontSize: Float,
    val theme: Int,
    val speed: Float,
    val repeat: Int,
    val continuous: Boolean,
    val lastPage: Int,
    val lastSurah: Int,
    val lastAyah: Int,
    val bookmarks: Set<String>,
    val downloaded: Set<String>,
    val pageStyle: Int,
    val lineSpacing: Float,
    val keepScreenOn: Boolean,
    val follow: Boolean,
    val backgroundPlay: Boolean,
    val lat: Double?,
    val lon: Double?,
    val city: String,
    val prayerMethod: Int,
    val madhab: Int,
    val prayerAlerts: Boolean,
    val germanMode: Int,
    val bgAlpha: Float,
    val tafsir: Int,
    val quranFont: Int,
    val script: Int,
)

class Prefs(context: Context) {
    private val store = context.applicationContext.dataStore

    object Keys {
        val reciter = stringPreferencesKey("reciter")
        val fontSize = floatPreferencesKey("font_size")
        val theme = intPreferencesKey("theme")
        val speed = floatPreferencesKey("speed")
        val repeat = intPreferencesKey("repeat")
        val continuous = booleanPreferencesKey("continuous")
        val lastPage = intPreferencesKey("last_page")
        val lastSurah = intPreferencesKey("last_surah")
        val lastAyah = intPreferencesKey("last_ayah")
        val bookmarks = stringSetPreferencesKey("bookmarks")
        val downloaded = stringSetPreferencesKey("downloaded")
        val pageStyle = intPreferencesKey("page_style")
        val lineSpacing = floatPreferencesKey("line_spacing")
        val keepScreenOn = booleanPreferencesKey("keep_screen_on")
        val follow = booleanPreferencesKey("follow")
        val backgroundPlay = booleanPreferencesKey("background_play")
        val lat = doublePreferencesKey("lat")
        val lon = doublePreferencesKey("lon")
        val city = stringPreferencesKey("city")
        val prayerMethod = intPreferencesKey("prayer_method")
        val madhab = intPreferencesKey("madhab")
        val prayerAlerts = booleanPreferencesKey("prayer_alerts")
        val germanMode = intPreferencesKey("german_mode")
        val bgAlpha = floatPreferencesKey("bg_alpha")
        val tafsir = intPreferencesKey("tafsir")
        val quranFont = intPreferencesKey("quran_font")
        val script = intPreferencesKey("script")
    }

    val settings: Flow<Settings> = store.data.catch { emit(emptyPreferences()) }.map { p ->
        Settings(
            reciter = Reciters.byId(p[Keys.reciter]),
            fontSize = p[Keys.fontSize] ?: 26f,
            theme = p[Keys.theme] ?: 0,
            speed = p[Keys.speed] ?: 1f,
            repeat = p[Keys.repeat] ?: 1,
            continuous = p[Keys.continuous] ?: true,
            lastPage = p[Keys.lastPage] ?: 0,
            lastSurah = p[Keys.lastSurah] ?: 0,
            lastAyah = p[Keys.lastAyah] ?: 0,
            bookmarks = p[Keys.bookmarks] ?: emptySet(),
            downloaded = p[Keys.downloaded] ?: emptySet(),
            pageStyle = p[Keys.pageStyle] ?: 0,
            lineSpacing = p[Keys.lineSpacing] ?: 2.05f,
            keepScreenOn = p[Keys.keepScreenOn] ?: true,
            follow = p[Keys.follow] ?: true,
            backgroundPlay = p[Keys.backgroundPlay] ?: false,
            lat = p[Keys.lat],
            lon = p[Keys.lon],
            city = p[Keys.city] ?: "",
            prayerMethod = p[Keys.prayerMethod] ?: 0,
            madhab = p[Keys.madhab] ?: 0,
            prayerAlerts = p[Keys.prayerAlerts] ?: true,
            germanMode = p[Keys.germanMode] ?: 0,
            bgAlpha = p[Keys.bgAlpha] ?: 0.3f,
            tafsir = p[Keys.tafsir] ?: 0,
            quranFont = p[Keys.quranFont] ?: 0,
            script = p[Keys.script] ?: 0,
        )
    }

    suspend fun <T> set(key: Preferences.Key<T>, value: T) {
        store.edit { it[key] = value }
    }

    suspend fun saveLocation(lat: Double, lon: Double, city: String) {
        store.edit {
            it[Keys.lat] = lat
            it[Keys.lon] = lon
            it[Keys.city] = city
        }
    }

    suspend fun saveLastRead(surah: Int, ayah: Int, page: Int) {
        store.edit {
            it[Keys.lastSurah] = surah
            it[Keys.lastAyah] = ayah
            it[Keys.lastPage] = page
        }
    }

    suspend fun toggle(key: Preferences.Key<Set<String>>, value: String, on: Boolean? = null) {
        store.edit {
            val cur = it[key] ?: emptySet()
            val add = on ?: (value !in cur)
            it[key] = if (add) cur + value else cur - value
        }
    }

    suspend fun removeDownloads(reciterId: String) {
        store.edit { p -> p[Keys.downloaded] = (p[Keys.downloaded] ?: emptySet()).filterNot { it.startsWith("$reciterId:") }.toSet() }
    }
}
