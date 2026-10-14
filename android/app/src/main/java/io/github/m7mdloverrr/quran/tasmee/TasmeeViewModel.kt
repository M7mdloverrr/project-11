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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.cancelAndJoin
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

class TWord(val surah: Int, val ayah: Int, val text: String, val key: String, val ayahEnd: Boolean, val phon: String = "")

enum class Phase { Setup, Listening, Mistake, Done }

private val space = Regex("\\s+")

/** KFGQPC Hafs words with their normalized matching keys, one key per displayed word. */
object TasmeeText {
    @Volatile private var qpc: List<List<String>>? = null
    @Volatile private var keys: List<List<String>>? = null
    @Volatile private var phon: List<List<String>>? = null
    private val letter = Regex("[\u0621-\u064A\u0671]")

    private fun read(context: Context, asset: String): List<List<String>> {
        val arr = org.json.JSONObject(context.assets.open(asset).bufferedReader().readText()).getJSONArray("s")
        return List(arr.length()) { si -> arr.getJSONArray(si).let { sa -> List(sa.length()) { sa.getString(it) } } }
    }

    suspend fun words(context: Context, surah: Int, from: Int, to: Int): List<TWord> = withContext(Dispatchers.IO) {
        val q = qpc ?: read(context, "script_qpc.json").also { qpc = it }
        val k = keys ?: read(context, "tasmee_keys.json").also { keys = it }
        val ph = phon ?: read(context, "tasmee_phonemes.json").also { phon = it }
        val out = ArrayList<TWord>()
        for (a in from..to) {
            val tokens = ArrayList<String>()
            for (t in q[surah - 1][a - 1].split(' ').filter { it.isNotBlank() }) {
                if (letter.containsMatchIn(t) || tokens.isEmpty()) tokens.add(t) else tokens[tokens.size - 1] = tokens.last() + " " + t
            }
            val ks = k[surah - 1][a - 1].split(' ')
            val ps = ph[surah - 1][a - 1].split(' ')
            tokens.forEachIndexed { i, t ->
                val p = ps.getOrNull(i)?.takeIf { ps.size == tokens.size && it != "-" }.orEmpty()
                out.add(TWord(surah, a, t, ks.getOrNull(i)?.takeIf { ks.size == tokens.size } ?: ArabicNorm.norm(t), i == tokens.size - 1, p))
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
    /** True when the whole surah is shown and the reciter is followed through it. */
    var follow by mutableStateOf(false); private set
    var words by mutableStateOf<List<TWord>>(emptyList()); private set
    val marks = mutableStateListOf<WordResult?>()
    var pointer by mutableIntStateOf(0); private set
    var tentative by mutableStateOf<List<WordResult>>(emptyList()); private set
    var level by mutableFloatStateOf(0f); private set
    /** Download state of an optional model that powers [engine]. */
    inner class Download(val model: ModelStore.Model, val engine: Int, private val name: String) {
        var ready by mutableStateOf(false); internal set
        var progress by mutableStateOf<Float?>(null); private set
        private var job: Job? = null

        fun start() {
            if (job?.isActive == true) return
            job = viewModelScope.launch {
                progress = 0f
                val r = runCatching { ModelStore.download(getApplication(), model) { progress = it } }
                progress = null
                ready = ModelStore.ready(getApplication(), model)
                r.onSuccess { setEngine(engine) }.onFailure {
                    if (it !is kotlinx.coroutines.CancellationException) error = "تعذّر تنزيل $name. تحقق من الإنترنت وحاول مجدداً."
                }
            }
        }

        fun cancel() { job?.cancel() }

        fun delete() {
            viewModelScope.launch {
                if (prefs.settings.first().engine == engine) setEngine(1)
                withContext(decoder) {
                    if (engine == 0) { recognizer?.release(); recognizer = null }
                    else if (loaded == engine) { live?.release(); live = null }
                }
                ModelStore.delete(getApplication(), model)
                ready = false
            }
        }
    }

    val whisper = Download(ModelStore.whisper, 0, "Whisper")
    val fast = Download(ModelStore.fastConformer, 2, "FastConformer")
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
    private var live: Streamer? = null
    private var tracker: PhonemeTracker? = null
    private var trackBase = 0
    private var loaded = -1
    private val isLive: Boolean get() = loaded == 1 || loaded == 2
    private val decoder = Dispatchers.Default.limitedParallelism(1)
    private var job: Job? = null
    private val busy = AtomicBoolean(false)
    private var cap = Capture()
    private var generation = 0
    private var tent: Map<Int, Mark> = emptyMap()
    private var stopping = false
    private var jumpSeen = -1
    private var jumpAge = 0

    /** Rolling audio window of the current utterance, owned by one listening job. */
    private class Capture {
        val win = ArrayDeque<FloatArray>()
        @Volatile var speech = false
        @Volatile var cut = false
    }

    fun <T> setPref(key: Preferences.Key<T>, v: T) = viewModelScope.launch { prefs.set(key, v) }

    fun prepare() {
        if (modelReady) return
        viewModelScope.launch {
            withContext(Dispatchers.IO) { for (d in listOf(whisper, fast)) d.ready = ModelStore.ready(getApplication(), d.model) }
            var engine = prefs.settings.first().engine
            if ((engine == 0 && !whisper.ready) || (engine == 2 && !fast.ready)) { engine = 1; prefs.set(TasmeePrefs.Keys.engine, 1) }
            if (modelReady && loaded == engine) return@launch
            val r = withContext(decoder) {
                runCatching {
                    if (engine == 1) { if (live == null) live = LiveRecognizer(getApplication()) }
                    else if (engine == 2) { if (live == null) live = FastConformerRecognizer(getApplication()) }
                    else if (recognizer == null) recognizer = QuranRecognizer(getApplication())
                }
            }
            r.onSuccess { loaded = engine; modelReady = true }
                .onFailure { error = "تعذّر تحميل المصحح الصوتي على هذا الجهاز." }
        }
    }

    /** Switches the listening AI; the other model is released to save memory. */
    fun setEngine(engine: Int) {
        if (engine == loaded) return
        stopListening()
        modelReady = false
        viewModelScope.launch {
            prefs.set(TasmeePrefs.Keys.engine, engine)
            withContext(decoder) {
                if (engine != 0) { recognizer?.release(); recognizer = null }
                live?.release(); live = null
            }
            loaded = -1
            prepare()
        }
    }

    fun start(surah: Int, from: Int, to: Int, follow: Boolean = false) {
        this.follow = follow
        viewModelScope.launch {
            if (!follow) prefs.saveRange(surah, from, to)
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
        start(s, f, t, follow)
    }

    private fun listen() {
        job?.cancel()
        val st = settings.value ?: return
        if (isLive) { listenLive(st); return }
        val pauseMs = (st.pauseSec * 1000).toInt()
        generation++
        tent = emptyMap()
        stopping = false
        jumpSeen = -1
        val c = Capture().also { cap = it }
        job = viewModelScope.launch(Dispatchers.Default) {
            val source = TasmeeDebug.wav?.let { WavSource(it) } ?: MicSource()
            val pre = ArrayDeque<FloatArray>()
            var floor = 0.01f
            var voicedRun = 0
            var silence = 0
            var sinceDecode = 0
            try {
                source.frames().collect { f ->
                    var sum = 0f
                    for (x in f) sum += x * x
                    val rms = sqrt(sum / f.size)
                    level = min(1f, rms * 10f)
                    floor = if (rms < floor) floor * 0.9f + rms * 0.1f else floor * 0.998f + rms * 0.002f
                    val voiced = rms > max(0.008f, floor * 2.5f)
                    if (!c.speech) {
                        pre.addLast(f)
                        if (pre.size > 12) pre.removeFirst()
                        voicedRun = if (voiced) voicedRun + 1 else 0
                        if (voicedRun >= 3) {
                            c.win.clear()
                            c.win.addAll(pre)
                            pre.clear()
                            c.cut = false
                            c.speech = true
                            silence = 0
                            sinceDecode = 0
                        }
                        return@collect
                    }
                    c.win.addLast(f)
                    if (c.win.size > WINDOW_FRAMES) { c.win.removeFirst(); c.cut = true }
                    silence = if (voiced) 0 else silence + FRAME_MS
                    sinceDecode += FRAME_MS
                    if (busy.get()) return@collect
                    val final = silence >= pauseMs
                    if (final || sinceDecode >= STRIDE_MS) {
                        sinceDecode = 0
                        submit(concat(c.win), final, c.cut)
                        if (final) { c.speech = false; voicedRun = 0; c.win.clear() }
                    }
                }
            } catch (e: IllegalStateException) {
                withContext(Dispatchers.Main) { error = "تعذّر تشغيل الميكروفون."; finish() }
            }
        }
    }

    private fun listenLive(st: TasmeeSettings) {
        generation++
        stopping = false
        val base = pointer
        trackBase = base
        val phonetic = live?.phonetic != false
        val tr = PhonemeTracker(words.drop(base).map { if (phonetic) it.phon else it.key }, st.limit).also { tracker = it }
        val gen = generation
        job = viewModelScope.launch(decoder) {
            val rec = live ?: return@launch
            rec.reset()
            val source = TasmeeDebug.wav?.let { WavSource(it) } ?: MicSource()
            var last = ""
            try {
                source.frames().collect { f ->
                    var sum = 0f
                    for (x in f) sum += x * x
                    level = min(1f, sqrt(sum / f.size) * 10f)
                    val h = norm(rec, rec.accept(f))
                    if (h == last) return@collect
                    last = h
                    val outs = tr.update(h, false)
                    val t = tr.tentative
                    withContext(Dispatchers.Main) { if (gen == generation) applyLive(outs, t, base) }
                }
            } catch (e: IllegalStateException) {
                withContext(Dispatchers.Main) { error = "تعذّر تشغيل الميكروفون."; finish() }
            }
        }
    }

    private fun norm(r: Streamer, t: String) = if (r.phonetic) Phon.norm(t) else ArabicNorm.norm(t)

    private fun applyLive(outs: List<PhonemeTracker.Out>, tent: Int, base: Int) {
        if (phase != Phase.Listening) return
        val st = settings.value ?: return
        var mistake = false
        for (o in outs) {
            val i = base + o.index
            if (i < pointer || i >= words.size) continue
            marks[i] = WordResult(o.mark)
            pointer = i + 1
            if (o.mark != Mark.Correct) { mistake = true; if (st.onMistake == 1) break }
        }
        tentative = if (mistake && st.onMistake == 1) emptyList()
        else List(min(tent, words.size - pointer)) { WordResult(Mark.Correct, partial = true) }
        if (mistake && st.vibrate) vibrate()
        if (mistake && st.onMistake == 1) {
            mistakeAt = pointer - 1
            stopListening()
            phase = Phase.Mistake
        } else if (pointer >= words.size) finish()
    }

    private fun concat(list: Collection<FloatArray>): FloatArray {
        val out = FloatArray(list.sumOf { it.size })
        var o = 0
        for (a in list) { a.copyInto(out, o); o += a.size }
        return out
    }

    private fun submit(audio: FloatArray, final: Boolean, cut: Boolean, then: (() -> Unit)? = null) {
        busy.set(true)
        val gen = generation
        viewModelScope.launch(decoder) {
            withContext(Dispatchers.Main) { decoding = true }
            val text = runCatching { recognizer?.transcribe(audio) }.getOrNull().orEmpty()
            withContext(Dispatchers.Main) {
                decoding = false
                if (gen == generation) apply(text, final, cut)
                busy.set(false)
                then?.invoke()
            }
        }
    }

    private fun apply(text: String, final: Boolean, cut: Boolean) {
        if (phase != Phase.Listening) return
        val st = settings.value ?: return
        val raw = text.split(space).filter { ArabicNorm.norm(it).isNotEmpty() }
        val hyp = raw.map(ArabicNorm::norm)
        val keys = words.map { it.key }
        var res = alignWindow(keys, pointer, hyp, st.threshold, raw, final)
        // Skipped words or verses: when the recitation clearly continues further ahead, mark the gap missed and follow it.
        val skippedFrom = pointer
        val jump = relocate(keys, pointer, hyp, st.threshold)
        val matched = res.count { it.result.mark == Mark.Correct && !it.result.partial && it.hyp >= 0 }
        var jumped = false
        if (jump != null && jump.start > pointer && jump.length >= matched + 2) {
            if (final || jump.length >= 4 || (jumpSeen >= 0 && jump.start in jumpSeen - 4..jumpSeen + 20)) {
                for (k in pointer until jump.start) marks[k] = WordResult(Mark.Missed)
                pointer = jump.start
                tent = emptyMap()
                jumpSeen = -1
                jumped = true
                res = alignWindow(keys, pointer, hyp, st.threshold, raw, final)
            } else { jumpSeen = jump.start; jumpAge = 0 }
        } else if (jumpSeen >= 0 && ++jumpAge > 3) jumpSeen = -1
        if (jumped && st.onMistake == 1) {
            if (st.vibrate) vibrate()
            tentative = emptyList()
            mistakeAt = skippedFrom
            stopListening()
            phase = Phase.Mistake
            return
        }
        val lead = res.count { it.hyp == LEAD }
        // Words heard in the previous window, or cut off at the start of a full window, were recited.
        val fixed = res.map { h ->
            if (h.result.mark == Mark.Missed && (tent[h.index] == Mark.Correct || (h.hyp == LEAD && cut && lead <= 3)))
                Hit(h.index, WordResult(Mark.Correct), h.hyp) else h
        }
        // The last recognized word may still be cut off, so partial results only commit up to the last matched word before it.
        val last = hyp.size - 1
        val end = if (final) fixed.indexOfLast { it.result.mark != Mark.Missed }
        else fixed.indexOfLast { it.result.mark == Mark.Correct && it.hyp >= 0 && it.hyp != last }
        var take = fixed.take(end + 1)
        val first = take.indexOfFirst { it.result.mark != Mark.Correct }
        if (st.onMistake == 1 && first >= 0) take = take.take(first + 1)
        for (h in take) { marks[h.index] = h.result; pointer = h.index + 1 }
        val rest = fixed.drop(take.size).filter { it.index >= pointer }
        val heard = tent.filterKeys { it >= pointer }.toMutableMap()
        for (h in rest) if (h.result.mark == Mark.Correct && !h.result.partial) heard[h.index] = Mark.Correct
        if (final) while (heard[pointer] == Mark.Correct) { marks[pointer] = WordResult(Mark.Correct); pointer++ }
        tent = heard
        val shown = ArrayList<WordResult>()
        for (h in rest) { if (h.index < pointer) continue; if (h.index != pointer + shown.size || h.result.mark != Mark.Correct) break; shown.add(h.result) }
        tentative = shown
        if ((first >= 0 || jumped) && st.vibrate) vibrate()
        if (st.onMistake == 1 && first >= 0) {
            mistakeAt = pointer - 1
            stopListening()
            phase = Phase.Mistake
        } else if (pointer >= words.size) finish()
    }

    /** Stop button: decodes the audio still in the window before showing the summary. */
    fun stop() {
        if (phase != Phase.Listening || stopping) { if (!stopping) finish(); return }
        stopping = true
        val j = job
        job = null
        val c = cap
        viewModelScope.launch {
            j?.cancelAndJoin()
            level = 0f
            if (isLive) {
                val tr = tracker
                val outs = withContext(decoder) { live?.let { r -> tr?.update(norm(r, r.finish()), true) } }.orEmpty()
                if (phase == Phase.Listening) { applyLive(outs, 0, trackBase); if (phase == Phase.Listening) finish() }
                return@launch
            }
            val audio = if (c.speech && c.win.isNotEmpty()) concat(c.win) else null
            while (busy.get()) delay(30)
            if (audio == null || recognizer == null || phase != Phase.Listening) finish()
            else submit(audio, true, c.cut) { if (phase == Phase.Listening) finish() }
        }
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
        stopping = false
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
        follow = false
    }

    override fun onCleared() {
        job?.cancel()
        val r = recognizer
        val l = live
        recognizer = null
        live = null
        CoroutineScope(decoder).launch { r?.release(); l?.release() }
    }
}
