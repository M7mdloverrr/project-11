package io.github.m7mdloverrr.quran.tasmee

import android.content.Context
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Where in the whole Quran a stretch of recitation was found: [start] is the first word fully heard, within surah [surah]. */
class Location(val surah: Int, val start: Int, val anchorBack: Int)

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
) {
    private var prev = FloatArray(text.size + 1)
    private var cur = FloatArray(text.size + 1)
    private var st = IntArray(text.size + 1)
    private var cs = IntArray(text.size + 1)

    @Synchronized
    fun locate(hyp: String): Location? {
        if (hyp.length < TAIL) return null
        val tail = hyp.substring(hyp.length - TAIL)
        val t = IntArray(TAIL) { alphabet[tail[it]] ?: (alphabet.size) }
        val ins = FloatArray(TAIL) { if (phonetic) Phon.ins(tail, it) else 0.75f }
        val n = text.size
        prev.fill(0f)
        for (j in 0..n) st[j] = j
        for (i in 0 until TAIL) {
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
        for (j in 1..n) if ((j < best - 2 * TAIL || j > best + 2 * TAIL) && prev[j] < second) second = prev[j]
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
        return Location(wordSurah[g], wordIndex[g], TAIL - back)
    }

    private fun wordAt(c: Int): Int {
        var lo = 0; var hi = wordStart.size - 1
        while (lo < hi) { val mid = (lo + hi + 1) ushr 1; if (wordStart[mid] <= c) lo = mid else hi = mid - 1 }
        return lo
    }

    companion object {
        const val TAIL = 30
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

        private fun build(all: List<List<TWord>>, phonetic: Boolean): Locator {
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
            return Locator(text, del, starts.toIntArray(), ss.toIntArray(), wi.toIntArray(), phonetic, alphabet, sub)
        }
    }
}
