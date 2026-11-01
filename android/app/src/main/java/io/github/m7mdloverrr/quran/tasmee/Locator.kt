package io.github.m7mdloverrr.quran.tasmee

import android.content.Context
import kotlin.math.min
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Where in the whole Quran a stretch of recitation was found: [start] is the first word fully heard, within surah [surah]. */
class Location(val surah: Int, val start: Int, val anchorBack: Int, val strong: Boolean = false)

/**
 * Finds the recited passage anywhere in the Quran by approximate matching of the last sounds heard
 * against every word (Sellers' algorithm), rejecting passages that occur in several places.
 */
class Locator private constructor(
    private val text: IntArray,
    private val del: FloatArray,
    private val wordStart: IntArray,
    private val wordSurah: IntArray,
    private val wordIndex: IntArray,
    private val phonetic: Boolean,
    private val alphabet: Map<Char, Int>,
    private val subCost: Array<FloatArray>,
    private val basmala: String,
) {
    private var prev = FloatArray(text.size + 1)
    private var cur = FloatArray(text.size + 1)
    private var st = IntArray(text.size + 1)
    private var cs = IntArray(text.size + 1)

    /**
     * Tries the recitation from [from] (its start, or where the reciter was lost) first, also without a leading
     * basmala, then the last sounds heard.
     */
    fun find(hyp: String, from: Int = -1): Location? {
        if (from >= 0) {
            locate(hyp, from)?.let { return it }
            val a = afterBasmala(hyp, from)
            if (a > from) locate(hyp, a)?.let { return it }
        }
        return locate(hyp)
    }

    /** End of a basmala recited at [from], or -1. */
    fun afterBasmala(h: String, from: Int): Int {
        val b = basmala
        if (b.isEmpty() || from < 0 || h.length - from < b.length * 3 / 4) return -1
        val m = min(h.length - from, b.length + 8)
        var prev = FloatArray(m + 1) { it * 0.75f }
        for (i in 1..b.length) {
            val cur = FloatArray(m + 1)
            cur[0] = prev[0] + Phon.del(b, i - 1)
            for (j in 1..m) cur[j] = minOf(prev[j - 1] + Phon.sub(h[from + j - 1], b[i - 1]), prev[j] + Phon.del(b, i - 1), cur[j - 1] + Phon.ins(h, from + j - 1))
            prev = cur
        }
        var bj = 0
        for (j in 0..m) if (prev[j] < prev[bj]) bj = j
        return if (prev[bj] / Phon.eff(b) <= 0.25f) from + bj else -1
    }

    /** Searches the sounds from [from] (up to [PREFIX] of them), or the last [TAIL] sounds when [from] is negative. */
    @Synchronized
    fun locate(hyp: String, from: Int = -1): Location? {
        val qs = if (from >= 0) from else hyp.length - TAIL
        val qe = if (from >= 0) min(hyp.length, from + PREFIX) else hyp.length
        if (qs < 0 || qe - qs < (if (from >= 0) MIN_Q else TAIL)) return null
        val tail = hyp.substring(qs, qe)
        val len = tail.length
        val t = IntArray(len) { alphabet[tail[it]] ?: (alphabet.size) }
        val ins = FloatArray(len) { if (phonetic) Phon.ins(tail, it) else 0.75f }
        val n = text.size
        prev.fill(0f)
        for (j in 0..n) st[j] = j
        for (i in 0 until len) {
            val row = subCost[t[i]]
            val ci = ins[i]
            cur[0] = prev[0] + ci; cs[0] = 0
            for (j in 1..n) {
                val a1 = prev[j - 1] + row[text[j - 1]]
                val a2 = cur[j - 1] + del[j - 1]
                val a3 = prev[j] + ci
                if (a1 <= a2 && a1 <= a3) { cur[j] = a1; cs[j] = st[j - 1] }
                else if (a2 <= a3) { cur[j] = a2; cs[j] = cs[j - 1] }
                else { cur[j] = a3; cs[j] = st[j] }
            }
            val p = prev; prev = cur; cur = p
            val q = st; st = cs; cs = q
        }
        var best = 1
        for (j in 1..n) if (prev[j] < prev[best]) best = j
        var second = Float.MAX_VALUE
        for (j in 1..n) if ((j < best - 2 * len || j > best + 2 * len) && prev[j] < second) second = prev[j]
        val eff = Phon.eff(tail).toFloat()
        val b = prev[best] / eff
        if (b > MAX_COST || second / eff - b < MARGIN) return null
        val sc = st[best]
        var g = wordAt(sc)
        var back = 0
        if (wordStart[g] < sc) {
            if (g + 1 >= wordStart.size || wordStart[g + 1] >= best) return null
            back = wordStart[g + 1] - sc
            g++
        }
        if (wordSurah[g] != wordSurah[wordAt(best - 1)]) return null
        return Location(wordSurah[g], wordIndex[g], hyp.length - (qs + back), len >= 18 && second / eff - b >= 0.2f)
    }

    private fun wordAt(c: Int): Int {
        var lo = 0; var hi = wordStart.size - 1
        while (lo < hi) { val mid = (lo + hi + 1) ushr 1; if (wordStart[mid] <= c) lo = mid else hi = mid - 1 }
        return lo
    }

    companion object {
        const val TAIL = 30
        const val PREFIX = 60
        const val MIN_Q = 14
        private const val MAX_COST = 0.12f
        private const val MARGIN = 0.12f
        private val lock = Mutex()
        @Volatile private var surahs: List<List<TWord>>? = null
        private val built = HashMap<Boolean, Locator>()

        /** The Tasmee words of every surah, in display order. */
        suspend fun surahs(context: Context): List<List<TWord>> = surahs ?: lock.withLock {
            surahs ?: List(114) { s -> TasmeeText.words(context, s + 1, 1, TasmeeText.ayahCount(context, s + 1)) }.also { surahs = it }
        }

        suspend fun get(context: Context, phonetic: Boolean): Locator {
            val all = surahs(context)
            return lock.withLock { built.getOrPut(phonetic) { build(all, phonetic) } }
        }

        internal fun build(all: List<List<TWord>>, phonetic: Boolean): Locator {
            val sb = StringBuilder()
            val starts = ArrayList<Int>(80000); val ss = ArrayList<Int>(80000); val wi = ArrayList<Int>(80000)
            all.forEachIndexed { s, ws ->
                ws.forEachIndexed { i, w -> starts.add(sb.length); ss.add(s + 1); wi.add(i); sb.append(if (phonetic) w.phon else w.key) }
            }
            val str = sb.toString()
            val chars = str.toSortedSet().toList()
            val alphabet = chars.withIndex().associate { it.value to it.index }
            val k = chars.size
            val sub = Array(k + 1) { a -> FloatArray(k) { b -> if (a == k) 1f else if (phonetic) Phon.sub(chars[a], chars[b]) else if (a == b) 0f else 1f } }
            val text = IntArray(str.length) { alphabet.getValue(str[it]) }
            val del = FloatArray(str.length) { if (phonetic) Phon.del(str, it) else if (str[it] in "اوي") 0.5f else 1f }
            val basmala = all[0].filter { it.ayah == 1 }.joinToString("") { if (phonetic) it.phon else it.key }
            return Locator(text, del, starts.toIntArray(), ss.toIntArray(), wi.toIntArray(), phonetic, alphabet, sub, basmala)
        }
    }
}
