package io.github.m7mdloverrr.quran.tasmee

import kotlin.math.max
import kotlin.math.min

/** Phoneme-level tracking for the streaming Quran-Lab zipformer, whose output is a cumulative phoneme string. */
object Phon {
    private val drop = Regex("[\\s\u200e\u200f\u0640\u0686\u06dc\u0619\u06ea]")
    private val hamza = Regex("[أإآٲ]")
    private const val SV = "\u064e\u064f\u0650"
    private const val V = "اوي"
    private val pairs = setOf("اَ", "وُ", "يِ", "تط", "جز", "خغ", "دض", "ذز", "ذظ", "سص", "قك")
    const val CONF = 0.25f

    fun norm(t: String) = hamza.replace(drop.replace(t, ""), "ء")
        .replace('۾', 'م').replace('ں', 'ن').replace('ۥ', 'و').replace('ۦ', 'ي')

    fun sub(a: Char, b: Char): Float {
        if (a == b || (a == 'ة' && (b == 'ه' || b == 'ت')) || (b == 'ة' && (a == 'ه' || a == 'ت'))) return 0f
        if (a in SV && b in SV) return 0.5f
        return if ("$a$b" in pairs || "$b$a" in pairs) CONF else 1f
    }

    fun del(r: CharSequence, j: Int) = if (r[j] == 'ء' || (j > 0 && r[j] == r[j - 1]) || r[j] in SV) CONF else 1f
    fun ins(h: CharSequence, i: Int) = if ((i > 0 && h[i] == h[i - 1]) || h[i] in SV) CONF else 0.75f

    fun eff(w: String): Int {
        var c = 0
        for (i in w.indices) if (w[i] !in SV && !(i > 0 && w[i] == w[i - 1] && w[i] in V)) c++
        return max(1, c)
    }
}

/**
 * Follows a recitation word by word. [words] are normalized phoneme words ("" = a word with no sound, such as ۞).
 * [update] takes the recognizer's whole cumulative normalized hypothesis.
 */
class PhonemeTracker(private val words: List<String>, private val limit: Float, start: Int = 0, private val look: Int = 10) {
    var pointer = 0; private set
    var tentative = 0; private set
    private var anchor = start
    private var jumpSeen = -1

    /** [heard] is the recognized sound string aligned to a wrong word. */
    class Out(val index: Int, val mark: Mark, val heard: String? = null, val span: IntRange? = null)

    private fun verdict(w: String, hi: IntArray, cost: FloatArray, b: Int, e: Int): Mark {
        var c = 0f; var heard = 0; var sup = 0
        for (t in b until e) { c += cost[t]; if (hi[t] >= 0) { heard++; if (cost[t] <= Phon.CONF) sup++ } }
        val ef = Phon.eff(w)
        if (c / ef <= limit && sup >= max(1f, ef * 0.5f)) return Mark.Correct
        return if (heard <= max(1, w.length / 4)) Mark.Missed else Mark.Wrong
    }

    /** Semi-global alignment of [h] against [r]: leading heard sounds are cheap to skip, the reference prefix must be covered. */
    private fun align(r: String, h: CharSequence, hi: IntArray, cost: FloatArray): Int {
        val n = r.length; val m = h.length
        val c = Array(m + 1) { FloatArray(n + 1) }
        val bk = Array(m + 1) { ByteArray(n + 1) }
        for (i in 1..m) c[i][0] = 0.3f * i
        for (j in 1..n) { c[0][j] = c[0][j - 1] + Phon.del(r, j - 1); bk[0][j] = 1 }
        for (i in 1..m) for (j in 1..n) {
            val s = c[i - 1][j - 1] + Phon.sub(h[i - 1], r[j - 1])
            val d = c[i][j - 1] + Phon.del(r, j - 1)
            val x = c[i - 1][j] + Phon.ins(h, i - 1)
            if (s <= d && s <= x) { c[i][j] = s; bk[i][j] = 0 } else if (d <= x) { c[i][j] = d; bk[i][j] = 1 } else { c[i][j] = x; bk[i][j] = 2 }
        }
        var bj = 0
        for (j in 0..n) if (c[m][j] - 0.05f * j <= c[m][bj] - 0.05f * bj) bj = j
        hi.fill(-1); cost.fill(0f)
        var i = m; var j = bj
        while (j > 0) {
            if (i == 0 || bk[i][j] == 1.toByte()) { cost[j - 1] = Phon.del(r, j - 1); j-- }
            else if (bk[i][j] == 0.toByte()) { hi[j - 1] = i - 1; cost[j - 1] = Phon.sub(h[i - 1], r[j - 1]); i--; j-- }
            else i--
        }
        return bj
    }

    fun update(hyp: String, final: Boolean): List<Out> {
        val out = ArrayList<Out>()
        while (pointer < words.size && words[pointer].isEmpty()) out.add(Out(pointer++, Mark.Correct))
        tentative = 0
        if (hyp.length - anchor > 160) anchor = hyp.length - 160
        if (pointer >= words.size || anchor >= hyp.length) return out
        val h = hyp.substring(anchor)
        val ws = words.subList(pointer, min(words.size, pointer + look))
        val r = ws.joinToString("")
        val hi = IntArray(r.length); val cost = FloatArray(r.length)
        val bj = align(r, h, hi, cost)
        var heardTo = 0
        for (t in 0 until bj) if (hi[t] >= 0 && cost[t] <= Phon.CONF) heardTo = t + 1
        var b = 0
        var k = 0
        while (k < ws.size) {
            val w = ws[k]; val e = b + w.length
            var after = 0
            var later = 0
            for (t in e until bj) if (hi[t] >= 0 && cost[t] <= Phon.CONF) { if (t < e + 4) after++ else later++ }
            if (w.isNotEmpty() && !(final && e <= bj && b < heardTo) && after < 2 && later < 8) break
            val mk = if (w.isEmpty()) Mark.Correct else verdict(w, hi, cost, b, e)
            var first = -1
            var last = -1
            for (t in b until e) if (hi[t] >= 0) { if (first < 0) first = hi[t]; last = hi[t] }
            val off = hyp.length - h.length
            out.add(Out(pointer++, mk, if (mk == Mark.Wrong && first >= 0) h.substring(first, last + 1) else null, if (first >= 0) (off + first)..(off + last) else null))
            if (last >= 0) anchor = hyp.length - h.length + last + 1
            b = e; k++
        }
        while (k < ws.size) {
            val w = ws[k]; val e = b + w.length
            if (e > bj || verdict(w, hi, cost, b, e) != Mark.Correct) break
            tentative++; b = e; k++
        }
        if (!final) relocate(hyp, out)
        return out
    }

    /** Skipped words or verses: find the last heard sounds further ahead, mark the gap missed and continue there. */
    private fun relocate(hyp: String, out: MutableList<Out>) {
        val h = hyp.substring(min(anchor, hyp.length))
        val tl = 14
        if (h.length < tl || pointer >= words.size) { jumpSeen = -1; return }
        val ws = words.subList(pointer, min(words.size, pointer + look))
        val r = ws.joinToString("")
        val hi = IntArray(r.length); val cost = FloatArray(r.length)
        val bj = align(r, h, hi, cost)
        var sup = 0
        for (t in 0 until bj) if (hi[t] >= h.length - tl && cost[t] <= Phon.CONF) sup++
        if (sup >= 8) { jumpSeen = -1; return }
        val tail = h.substring(h.length - tl)
        val starts = ArrayList<Int>()
        val big = StringBuilder()
        for (j in pointer until min(words.size, pointer + 400)) { starts.add(big.length); big.append(words[j]) }
        val n = big.length
        var prev = FloatArray(n + 1)
        var st = IntArray(n + 1) { it }
        for (i in 1..tl) {
            val cur = FloatArray(n + 1); val cst = IntArray(n + 1)
            cur[0] = prev[0] + Phon.ins(tail, i - 1)
            for (j in 1..n) {
                val a1 = prev[j - 1] + Phon.sub(tail[i - 1], big[j - 1])
                val a2 = cur[j - 1] + Phon.del(big, j - 1)
                val a3 = prev[j] + Phon.ins(tail, i - 1)
                if (a1 <= a2 && a1 <= a3) { cur[j] = a1; cst[j] = st[j - 1] } else if (a2 <= a3) { cur[j] = a2; cst[j] = cst[j - 1] } else { cur[j] = a3; cst[j] = st[j] }
            }
            prev = cur; st = cst
        }
        var jb = 1
        for (j in 1..n) if (prev[j] < prev[jb]) jb = j
        if (n == 0 || prev[jb] / Phon.eff(tail) > 0.25f) { jumpSeen = -1; return }
        val sc = st[jb]
        var wi = pointer
        for (x in starts.indices) if (starts[x] <= sc) wi = pointer + x
        if (wi <= pointer + 1) { jumpSeen = -1; return }
        if ((jumpSeen < 0 || wi !in jumpSeen - 4..jumpSeen + 20)) { jumpSeen = wi; return }
        for (x in pointer until wi) out.add(Out(x, Mark.Missed))
        pointer = wi
        anchor = hyp.length - tl
        jumpSeen = -1
    }
}
