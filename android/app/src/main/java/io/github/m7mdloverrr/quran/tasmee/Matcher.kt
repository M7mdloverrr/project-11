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

/** [partial]: the word is still being said and so far matches the start of the expected word. */
class WordResult(val mark: Mark, val heard: String? = null, val partial: Boolean = false, val tajweed: String? = null)

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

/** [hyp] is the hypothesis word index, -1 for a skipped word, [LEAD] for a word skipped before the window's first word. */
class Hit(val index: Int, val result: WordResult, val hyp: Int)

const val LEAD = -2

private fun isPrefix(h: String, e: String, ok: Boolean) = ok && h.length >= 3 && h.length < e.length && e.startsWith(h)

/**
 * Aligns a rolling-window hypothesis against expected words around [from].
 * The window may begin a few words before [from] (already committed) or after it (audio that scrolled out),
 * and its last word may be cut off. Returns hits for expected indices >= [from].
 */
fun alignWindow(
    expected: List<String>, from: Int, hyp: List<String>, threshold: Float,
    raw: List<String>, final: Boolean, back: Int = 6,
): List<Hit> {
    val n = hyp.size
    if (n == 0 || from >= expected.size) return emptyList()
    val s0 = max(0, from - back)
    val c0 = from - s0
    val w = min(expected.size - s0, c0 + n + 12)
    val inf = Float.MAX_VALUE / 4
    val dp = Array(n + 1) { FloatArray(w + 1) { inf } }
    val op = Array(n + 1) { IntArray(w + 1) }
    for (j in 0..c0) dp[0][j] = 0f
    val mergeTh = max(threshold, 0.9f)
    for (i in 0..n) for (j in 0..w) {
        val c = dp[i][j]
        if (c >= inf) continue
        if (j < w) {
            val e = expected[s0 + j]
            if (i < n) {
                var s = ArabicNorm.similarity(hyp[i], e)
                if (s < threshold && isPrefix(hyp[i], e, !final && i == n - 1)) s = 1f
                relax(dp, op, i + 1, j + 1, c + if (s >= threshold) 0f else if (s >= 0.4f) 1f else 1.6f, 1)
                if (i + 1 < n && ArabicNorm.similarity(hyp[i] + hyp[i + 1], e) >= mergeTh) relax(dp, op, i + 2, j + 1, c + 0.1f, 2)
            }
            relax(dp, op, i, j + 1, c + if (j < c0) 0f else if (i == 0) 0.35f else 1f, 3)
        }
        if (i < n) {
            val skip = when {
                i == n - 1 && j > c0 -> if (final) 0.5f else 0f
                i == 0 -> 0.3f
                j < c0 -> 0.6f
                else -> 1f
            }
            relax(dp, op, i + 1, j, c + skip, 4)
        }
    }
    // Prefer reaching new words: identical words just before [from] (a repeated phrase) should not swallow the window.
    fun score(j: Int) = dp[n][j] - if (j > c0) 0.4f else 0f
    var bj = 0
    for (j in 0..w) if (score(j) <= score(bj)) bj = j
    val out = ArrayList<Hit>()
    var i = n
    var j = bj
    while (i > 0 || j > 0) {
        if (i == 0 && j <= c0) break
        when (op[i][j]) {
            1 -> {
                val e = expected[s0 + j - 1]
                val s = ArabicNorm.similarity(hyp[i - 1], e)
                val r = when {
                    s >= threshold -> WordResult(Mark.Correct)
                    isPrefix(hyp[i - 1], e, !final && i == n) -> WordResult(Mark.Correct, partial = true)
                    else -> WordResult(Mark.Wrong, raw[i - 1])
                }
                out.add(Hit(s0 + j - 1, r, i - 1))
                i--; j--
            }
            2 -> { out.add(Hit(s0 + j - 1, WordResult(Mark.Correct), i - 2)); i -= 2; j-- }
            3 -> { out.add(Hit(s0 + j - 1, WordResult(Mark.Missed), if (i == 0) LEAD else -1)); j-- }
            else -> i--
        }
    }
    out.reverse()
    return out.filter { it.index >= from }
}

/** A far-ahead continuation of the recitation: [start] is the first matched expected index, [length] the matched words. */
class Jump(val start: Int, val length: Int)

/**
 * Finds where [hyp] continues after skipped words or verses: the longest in-order chain of matched words
 * (small gaps allowed) that ends near the end of [hyp], searched in expected[from, from + span).
 */
fun relocate(expected: List<String>, from: Int, hyp: List<String>, threshold: Float, span: Int = 400): Jump? {
    val n = hyp.size
    val m = min(expected.size, from + span) - from
    if (n < 3 || m <= 0) return null
    val len = Array(n) { IntArray(m) }
    val start = Array(n) { IntArray(m) }
    val chars = Array(n) { IntArray(m) }
    var best: Jump? = null
    for (i in 0 until n) for (j in 0 until m) {
        val e = expected[from + j]
        if (ArabicNorm.similarity(hyp[i], e) < threshold && !isPrefix(hyp[i], e, i == n - 1)) continue
        var b = 0
        var bs = j
        var bc = 0
        for (pi in max(0, i - 2) until i) for (pj in max(0, j - 3) until j) {
            if (len[pi][pj] > b) { b = len[pi][pj]; bs = start[pi][pj]; bc = chars[pi][pj] }
        }
        len[i][j] = b + 1
        start[i][j] = bs
        chars[i][j] = bc + e.length
        val l = len[i][j]
        if (i >= n - 3 && l >= 3 && chars[i][j] >= 9) {
            val cur = best
            if (cur == null || l > cur.length || (l == cur.length && from + bs < cur.start)) best = Jump(from + bs, l)
        }
    }
    return best
}
