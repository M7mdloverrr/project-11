package io.github.m7mdloverrr.quran.tasmee

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Replays real zipformer hypotheses and checks how early the recited surah is found. */
class LocatorTest {
    private val all: List<List<TWord>> by lazy {
        val body = File("src/main/assets/tasmee_phonemes.json").readText().substringAfter("[[").substringBeforeLast("]]")
        body.split("],[").mapIndexed { s, su ->
            Regex("\"([^\"]*)\"").findAll(su).map { it.groupValues[1] }.toList().flatMapIndexed { a, ay ->
                ay.split(' ').map { w -> val p = if (w == "-") "" else w; TWord(s + 1, a + 1, p, p, false, p) }
            }
        }
    }
    private val loc by lazy { Locator.build(all, true) }

    private fun first(lines: List<String>): Pair<Int, Location>? {
        var last = -100
        var prev: Location? = null
        for (line in lines) {
            val h = line.removePrefix("FINAL ")
            if (h.length - last < 5) continue
            last = h.length
            val l = loc.find(h, 0) ?: continue
            if (l.strong || (prev != null && prev.surah == l.surah && l.start in prev.start..prev.start + 15)) return h.length to l
            prev = l
        }
        return null
    }

    private fun lines(f: String) = javaClass.getResource("/live/$f")!!.readText().lines().filter { it.isNotBlank() }

    private fun check(name: String, ls: List<String>, surah: Int, maxChars: Int) {
        val (n, l) = first(ls)!!
        println("$name: found ${l.surah}:${l.start} after $n sounds (strong=${l.strong})")
        assertEquals(surah, l.surah)
        assertTrue(n <= maxChars)
    }

    @Test fun ikhlas() = check("ikhlas", lines("ikhlas.txt"), 112, 30)
    @Test fun kursi() = check("kursi", lines("kursi.txt"), 2, 70)
    @Test fun mulk() = check("mulk", lines("mulk23.txt"), 67, 35)

    @Test fun ikhlasAfterBasmala() {
        val b = all[0].filter { it.ayah == 1 }.joinToString("") { it.phon }
        val ls = (1..b.length).map { b.substring(0, it) } + lines("ikhlas.txt").map { b + it.removePrefix("FINAL ") }
        val (n, l) = first(ls)!!
        println("basmala+ikhlas: found ${l.surah}:${l.start} after ${n - b.length} sounds past the basmala")
        assertEquals(112, l.surah)
        assertTrue(n - b.length <= 30)
    }

    @Test fun fatiha() {
        val f = lines("fat_sub.txt")
        val (_, l) = first(f)!!
        println("fatiha: found ${l.surah}:${l.start}")
        assertEquals(1, l.surah)
    }
}
