package io.github.m7mdloverrr.quran.tasmee

import android.app.Application
import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import androidx.datastore.preferences.core.Preferences
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class TWord(val surah: Int, val ayah: Int, val text: String, val key: String, val ayahEnd: Boolean)

enum class Phase { Setup, Listening, Mistake, Done }

/** KFGQPC Hafs words with their normalized matching keys, one key per displayed word. */
object TasmeeText {
    @Volatile private var qpc: List<List<String>>? = null
    @Volatile private var keys: List<List<String>>? = null
    private val letter = Regex("[\u0621-\u064A\u0671]")

    private fun read(context: Context, asset: String): List<List<String>> {
        val arr = org.json.JSONObject(context.assets.open(asset).bufferedReader().readText()).getJSONArray("s")
        return List(arr.length()) { si -> arr.getJSONArray(si).let { sa -> List(sa.length()) { sa.getString(it) } } }
    }

    suspend fun words(context: Context, surah: Int, from: Int, to: Int): List<TWord> = withContext(Dispatchers.IO) {
        val q = qpc ?: read(context, "script_qpc.json").also { qpc = it }
        val k = keys ?: read(context, "tasmee_keys.json").also { keys = it }
        val out = ArrayList<TWord>()
        for (a in from..to) {
            val tokens = ArrayList<String>()
            for (t in q[surah - 1][a - 1].split(' ').filter { it.isNotBlank() }) {
                if (letter.containsMatchIn(t) || tokens.isEmpty()) tokens.add(t) else tokens[tokens.size - 1] = tokens.last() + " " + t
            }
            val ks = k[surah - 1][a - 1].split(' ')
            tokens.forEachIndexed { i, t ->
                out.add(TWord(surah, a, t, ks.getOrNull(i)?.takeIf { ks.size == tokens.size } ?: ArabicNorm.norm(t), i == tokens.size - 1))
            }
        }
        out
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class TasmeeViewModel(app: Application) : AndroidViewModel(app) {
    private val prefs = TasmeePrefs(app)
    val settings: StateFlow<TasmeeSettings?> = prefs.settings.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    var phase by mutableStateOf(Phase.Setup); private set
    var words by mutableStateOf<List<TWord>>(emptyList()); private set
    val marks = mutableStateListOf<WordResult?>()
    var pointer by mutableIntStateOf(0); private set
    var tentative by mutableStateOf<List<WordResult>>(emptyList()); private set
    var level by mutableFloatStateOf(0f); private set
    var decoding by mutableStateOf(false); private set
    var modelReady by mutableStateOf(false); private set
    var error by mutableStateOf<String?>(null)
    val hinted = mutableStateListOf<Int>()
    var hintShown by mutableIntStateOf(-1); private set
    var mistakeAt by mutableIntStateOf(-1); private set
    var startedAt by mutableLongStateOf(0L); private set
    var elapsedMs by mutableLongStateOf(0L); private set
    var range by mutableStateOf(Triple(1, 1, 1)); private set

    val revealed: Int get() = pointer + tentative.size

    private var recognizer: QuranRecognizer? = null
    private val decoder = Dispatchers.Default.limitedParallelism(1)
    private var job: Job? = null
    private val busy = AtomicBoolean(false)
    @Volatile private var segment = 0
    @Volatile private var finalized = 0

    fun <T> setPref(key: Preferences.Key<T>, v: T) = viewModelScope.launch { prefs.set(key, v) }

    fun prepare() {
        if (recognizer != null || modelReady) return
        viewModelScope.launch(decoder) {
            val r = runCatching { QuranRecognizer(getApplication()) }
            withContext(Dispatchers.Main) {
                r.onSuccess { recognizer = it; modelReady = true }
                    .onFailure { error = "تعذّر تحميل المصحح الصوتي على هذا الجهاز." }
            }
        }
    }

    fun start(surah: Int, from: Int, to: Int) {
        viewModelScope.launch {
            prefs.saveRange(surah, from, to)
            range = Triple(surah, from, to)
            words = TasmeeText.words(getApplication(), surah, from, to)
            marks.clear()
            repeat(words.size) { marks.add(null) }
            hinted.clear()
            pointer = 0
            tentative = emptyList()
            mistakeAt = -1
            hintShown = -1
            startedAt = System.currentTimeMillis()
            elapsedMs = 0
            phase = Phase.Listening
            listen()
        }
    }

    fun restart() {
        val (s, f, t) = range
        stopListening()
        start(s, f, t)
    }

    private fun listen() {
        job?.cancel()
        val st = settings.value ?: return
        val pauseMs = (st.pauseSec * 1000).toInt()
        segment++
        finalized = segment - 1
        job = viewModelScope.launch(Dispatchers.Default) {
            val source = TasmeeDebug.wav?.let { WavSource(it) } ?: MicSource()
            val buf = ArrayList<FloatArray>()
            val pre = ArrayDeque<FloatArray>()
            var floor = 0.01f
            var inSpeech = false
            var voicedRun = 0
            var silence = 0
            var lastPartial = 0
            try {
                source.frames().collect { f ->
                    var sum = 0f
                    for (x in f) sum += x * x
                    val rms = sqrt(sum / f.size)
                    level = min(1f, rms * 10f)
                    floor = if (rms < floor) floor * 0.9f + rms * 0.1f else floor * 0.998f + rms * 0.002f
                    val voiced = rms > max(0.008f, floor * 2.5f)
                    if (!inSpeech) {
                        pre.addLast(f)
                        if (pre.size > 12) pre.removeFirst()
                        voicedRun = if (voiced) voicedRun + 1 else 0
                        if (voicedRun >= 3) {
                            inSpeech = true
                            buf.addAll(pre)
                            pre.clear()
                            silence = 0
                            lastPartial = 0
                        }
                        return@collect
                    }
                    buf.add(f)
                    silence = if (voiced) 0 else silence + FRAME_MS
                    val dur = buf.size * FRAME_MS
                    if (silence >= pauseMs || dur >= 24_000) {
                        submit(concat(buf), true, segment)
                        segment++
                        buf.clear()
                        inSpeech = false
                        voicedRun = 0
                    } else if (dur - lastPartial >= 1200 && !busy.get()) {
                        lastPartial = dur
                        submit(concat(buf), false, segment)
                    }
                }
            } catch (e: IllegalStateException) {
                withContext(Dispatchers.Main) { error = "تعذّر تشغيل الميكروفون."; finish() }
            }
        }
    }

    private fun concat(list: List<FloatArray>): FloatArray {
        val out = FloatArray(list.sumOf { it.size })
        var o = 0
        for (a in list) { a.copyInto(out, o); o += a.size }
        return out
    }

    private fun submit(audio: FloatArray, final: Boolean, seg: Int) {
        if (!final && !busy.compareAndSet(false, true)) return
        viewModelScope.launch(decoder) {
            if (final) busy.set(true)
            withContext(Dispatchers.Main) { decoding = true }
            val text = runCatching { recognizer?.transcribe(audio) }.getOrNull().orEmpty()
            busy.set(false)
            withContext(Dispatchers.Main) {
                decoding = false
                apply(text, final, seg)
            }
        }
    }

    private fun apply(text: String, final: Boolean, seg: Int) {
        if (phase != Phase.Listening || seg <= finalized) return
        val st = settings.value ?: return
        val raw = text.split(Regex("\\s+")).filter { ArabicNorm.norm(it).isNotEmpty() }
        val keys = words.map { it.key }
        if (!final) {
            val r = raw.dropLast(1)
            tentative = align(keys, pointer, r.map(ArabicNorm::norm), st.threshold, r)
            return
        }
        finalized = seg
        tentative = emptyList()
        var res = align(keys, pointer, raw.map(ArabicNorm::norm), st.threshold, raw)
        val first = res.indexOfFirst { it.mark != Mark.Correct }
        if (st.onMistake == 1 && first >= 0) res = res.take(first + 1)
        for (r in res) { marks[pointer] = r; pointer++ }
        if (first >= 0 && st.vibrate) vibrate()
        if (st.onMistake == 1 && first >= 0) {
            mistakeAt = pointer - 1
            stopListening()
            phase = Phase.Mistake
        } else if (pointer >= words.size) finish()
    }

    private fun vibrate() {
        val v = ContextCompat.getSystemService(getApplication(), Vibrator::class.java) ?: return
        runCatching { v.vibrate(VibrationEffect.createOneShot(70, VibrationEffect.DEFAULT_AMPLITUDE)) }
    }

    fun hint() {
        val i = revealed
        if (i >= words.size || phase != Phase.Listening) return
        hintShown = i
        if (i !in hinted) hinted.add(i)
        viewModelScope.launch { delay(2500); if (hintShown == i) hintShown = -1 }
    }

    fun continueAfterMistake() {
        mistakeAt = -1
        if (pointer >= words.size) finish() else { phase = Phase.Listening; listen() }
    }

    fun retryMistake() {
        val i = mistakeAt
        if (i < 0) return
        for (k in i until pointer) marks[k] = null
        pointer = i
        mistakeAt = -1
        phase = Phase.Listening
        listen()
    }

    private fun stopListening() {
        job?.cancel()
        job = null
        tentative = emptyList()
        level = 0f
    }

    fun finish() {
        stopListening()
        hintShown = -1
        elapsedMs = System.currentTimeMillis() - startedAt
        phase = Phase.Done
    }

    fun backToSetup() {
        stopListening()
        phase = Phase.Setup
    }

    override fun onCleared() {
        job?.cancel()
        val r = recognizer
        recognizer = null
        if (r != null) CoroutineScope(decoder).launch { r.release() }
    }
}
