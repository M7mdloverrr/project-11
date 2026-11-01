package io.github.m7mdloverrr.quran.tasmee

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

private val Context.tasmeeStore by preferencesDataStore("tasmee")

data class TasmeeSettings(
    val strictness: Int,
    val onMistake: Int,
    val hint: Int,
    val pauseSec: Float,
    val fontSize: Float,
    val vibrate: Boolean,
    val showHeard: Boolean,
    val engine: Int,
    val surah: Int,
    val from: Int,
    val to: Int,
    /** Verse dividers: 0 with number, 1 without number, 2 hidden. */
    val ayahMark: Int,
    val autoStart: Boolean,
    val autoHidden: Boolean,
) {
    /** Phoneme-cost limit for the live engine. */
    val limit: Float get() = when (strictness) { 0 -> 0.45f; 2 -> 0.25f; else -> 0.35f }
    val threshold: Float get() = when (strictness) { 0 -> 0.6f; 2 -> 0.9f; else -> 0.75f }
}

class TasmeePrefs(context: Context) {
    private val store = context.applicationContext.tasmeeStore

    object Keys {
        val strictness = intPreferencesKey("strictness")
        val onMistake = intPreferencesKey("on_mistake")
        val hint = intPreferencesKey("hint")
        val pauseSec = floatPreferencesKey("pause_sec")
        val fontSize = floatPreferencesKey("font_size")
        val vibrate = booleanPreferencesKey("vibrate")
        val showHeard = booleanPreferencesKey("show_heard")
        val engine = intPreferencesKey("engine")
        val surah = intPreferencesKey("surah")
        val from = intPreferencesKey("from")
        val to = intPreferencesKey("to")
        val ayahMark = intPreferencesKey("ayah_mark")
        val autoStart = booleanPreferencesKey("auto_start")
        val autoHidden = booleanPreferencesKey("auto_hidden")
    }

    val settings: Flow<TasmeeSettings> = store.data.catch { emit(emptyPreferences()) }.map { p ->
        TasmeeSettings(
            strictness = p[Keys.strictness] ?: 1,
            onMistake = p[Keys.onMistake] ?: 0,
            hint = p[Keys.hint] ?: 1,
            pauseSec = p[Keys.pauseSec] ?: 0.8f,
            fontSize = p[Keys.fontSize] ?: 30f,
            vibrate = p[Keys.vibrate] ?: true,
            showHeard = p[Keys.showHeard] ?: true,
            engine = p[Keys.engine] ?: 1,
            surah = p[Keys.surah] ?: 0,
            from = p[Keys.from] ?: 1,
            to = p[Keys.to] ?: 0,
            ayahMark = p[Keys.ayahMark] ?: 0,
            autoStart = p[Keys.autoStart] ?: true,
            autoHidden = p[Keys.autoHidden] ?: false,
        )
    }

    suspend fun <T> set(key: Preferences.Key<T>, value: T) {
        store.edit { it[key] = value }
    }

    suspend fun saveRange(surah: Int, from: Int, to: Int) {
        store.edit {
            it[Keys.surah] = surah
            it[Keys.from] = from
            it[Keys.to] = to
        }
    }
}
