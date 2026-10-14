package io.github.m7mdloverrr.quran.tasmee

import kotlin.math.max
import kotlin.math.min

object ArabicNorm {
    private val marks = Regex("[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED\u0640]")
    private val space = Regex("\\s+")

    fun norm(t: String): String {
        val s = marks.replace(t.replace('\u0670', 'ا'), "")
        val sb = StringBuilder(s.length)
        for (c in s) {
            val m = when (c) {
                'ٱ', 'أ', 'إ', 'آ' -> 'ا'
                'ة' -> 'ه'
                'ى', 'ئ' -> 'ي'
                'ؤ' -> 'و'
                'ء' -> continue
                else -> c
            }
            if (m in '\u0621'..'\u064A') sb.append(m)
        }
        return sb.toString()
    }

    fun words(t: String): List<String> = t.split(space).map(::norm).filter { it.isNotEmpty() }

    private fun skeleton(s: String) = s.filter { it != 'ا' && it != 'و' && it != 'ي' }

    private fun lev(a: String, b: String): Int {
        var prev = IntArray(b.length + 1) { it }
        var cur = IntArray(b.length + 1)
        for (i in 1..a.length) {
            cur[0] = i
            for (j in 1..b.length) {
                cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + if (a[i - 1] == b[j - 1]) 0 else 1)
            }
            val t = prev; prev = cur; cur = t
        }
        return prev[b.length]
    }

    private fun ratio(a: String, b: String): Float =
        if (a == b) 1f else if (a.isEmpty() || b.isEmpty()) 0f else 1f - lev(a, b).toFloat() / max(a.length, b.length)

    /** 0..1 similarity of two normalized words, tolerant to long-vowel spelling differences. */
    fun similarity(a: String, b: String): Float {
        if (a == b) return 1f
        val sa = skeleton(a)
        val sb = skeleton(b)
        val sk = if (sa.isNotEmpty() && sa == sb) 0.95f else ratio(sa, sb) * 0.9f
        return max(ratio(a, b), sk)
    }
}

enum class Mark { Correct, Wrong, Missed }

class WordResult(val mark: Mark, val heard: String? = null)

/**
 * Aligns recognized words to the expected words starting at [from].
 * Returns one result per expected word that the recitation covered (a prefix of expected[from..]).
 */
fun align(expected: List<String>, from: Int, hyp: List<String>, threshold: Float, raw: List<String> = hyp): List<WordResult> {
    val n = hyp.size
    if (n == 0 || from >= expected.size) return emptyList()
    val w = min(expected.size - from, n + 6 + n / 2)
    val inf = Float.MAX_VALUE / 4
    val dp = Array(n + 1) { FloatArray(w + 1) { inf } }
    val op = Array(n + 1) { IntArray(w + 1) }
    dp[0][0] = 0f
    for (i in 0..n) for (j in 0..w) {
        val c = dp[i][j]
        if (c >= inf) continue
        if (j < w) {
            val e = expected[from + j]
            if (i < n) {
                val s = ArabicNorm.similarity(hyp[i], e)
                val cost = if (s >= threshold) 0f else if (s >= 0.4f) 1f else 1.6f
                relax(dp, op, i + 1, j + 1, c + cost, 1)
            }
            if (i + 1 < n && ArabicNorm.similarity(hyp[i] + hyp[i + 1], e) >= threshold) relax(dp, op, i + 2, j + 1, c, 2)
            relax(dp, op, i, j + 1, c + 1f, 3)
        }
        if (i < n) relax(dp, op, i + 1, j, c + if (j == 0) 0.4f else 1f, 4)
    }
    var bj = 0
    for (j in 0..w) if (dp[n][j] <= dp[n][bj]) bj = j
    val out = ArrayList<WordResult>()
    var i = n
    var j = bj
    while (i > 0 || j > 0) {
        when (op[i][j]) {
            1 -> {
                val s = ArabicNorm.similarity(hyp[i - 1], expected[from + j - 1])
                out.add(if (s >= threshold) WordResult(Mark.Correct) else WordResult(Mark.Wrong, raw[i - 1]))
                i--; j--
            }
            2 -> { out.add(WordResult(Mark.Correct)); i -= 2; j-- }
            3 -> { out.add(WordResult(Mark.Missed)); j-- }
            else -> i--
        }
    }
    out.reverse()
    return out
}

private fun relax(dp: Array<FloatArray>, op: Array<IntArray>, i: Int, j: Int, v: Float, o: Int) {
    if (v < dp[i][j]) { dp[i][j] = v; op[i][j] = o }
}
