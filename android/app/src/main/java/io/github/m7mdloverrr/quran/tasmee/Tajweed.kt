package io.github.m7mdloverrr.quran.tasmee

/**
 * Test-only tajweed check. The live model writes ghunnah/madd lengths from the text it expects, so instead the
 * time spent before the held sound's token is compared with the reciter's median time per token.
 */
object Tajweed {
    class Timing(val tokens: Array<String>, val times: FloatArray) {
        val ends: IntArray by lazy { var acc = 0; IntArray(tokens.size) { acc += Phon.norm(tokens[it]).length; acc } }
        val median: Float by lazy {
            if (times.size < 4) 0f else FloatArray(times.size - 1) { times[it + 1] - times[it] }.sorted()[(times.size - 1) / 2]
        }
    }

    private const val HARAKAT = "\u064e\u064f\u0650\u0652"
    const val GHUNNAH_MIN = 1.6f
    const val MADD_MIN = 2.0f

    /** [span]: the heard sounds of this word in the cumulative hypothesis. Returns a short note when a hold is too short. */
    fun check(phon: String, span: IntRange, t: Timing, ayahEnd: Boolean): String? {
        if (t.median <= 0f || t.tokens.size != t.times.size) return null
        var i = 0
        while (i < phon.length) {
            val c = phon[i]
            var j = i
            while (j < phon.length && phon[j] == c) j++
            val kind = when {
                c in "نم" && j - i >= 3 -> 0
                c in "اوي" && j - i >= 3 && !ayahEnd -> 1
                else -> -1
            }
            if (kind >= 0) {
                val k = tokenFor(c, span, t)
                if (k > 0) {
                    val r = (t.times[k] - t.times[k - 1]) / t.median
                    if (r < if (kind == 0) GHUNNAH_MIN else MADD_MIN) return if (kind == 0) "غنة قصيرة" else "مد قصير"
                }
            }
            i = j
        }
        return null
    }

    private fun tokenFor(c: Char, span: IntRange, t: Timing): Int {
        for (k in t.tokens.indices) {
            val start = if (k == 0) 0 else t.ends[k - 1]
            if (t.ends[k] <= span.first) continue
            if (start > span.last) break
            val core = Phon.norm(t.tokens[k]).trimEnd { it in HARAKAT }
            if (core.length >= 2 && core.all { it == c }) return k
        }
        return -1
    }
}
