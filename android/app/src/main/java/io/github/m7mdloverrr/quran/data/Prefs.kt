package io.github.m7mdloverrr.quran.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
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
        )
    }

    suspend fun <T> set(key: Preferences.Key<T>, value: T) {
        store.edit { it[key] = value }
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
