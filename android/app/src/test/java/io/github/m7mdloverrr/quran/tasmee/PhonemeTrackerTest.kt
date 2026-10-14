package io.github.m7mdloverrr.quran.tasmee

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Replays real zipformer hypotheses (recorded from Husary recitations) through the tracker. */
class PhonemeTrackerTest {
    private val surahs: List<List<String>> by lazy {
        val txt = File("src/main/assets/tasmee_phonemes.json").readText()
        val body = txt.substringAfter("[[").substringBeforeLast("]]")
        body.split("],[").map { s -> Regex("\"([^\"]*)\"").findAll(s).map { it.groupValues[1] }.toList() }
    }

    private fun run(file: String, surah: Int, from: Int, to: Int): Pair<Map<Int, Mark>, PhonemeTracker> {
        val words = (from..to).flatMap { a -> surahs[surah - 1][a - 1].split(' ').map { if (it == "-") "" else it } }
        val tr = PhonemeTracker(words, 0.35f)
        val marks = HashMap<Int, Mark>()
        for (line in javaClass.getResource("/live/$file")!!.readText().lines()) {
            val final = line.startsWith("FINAL ")
            for (o in tr.update(line.removePrefix("FINAL "), final)) marks[o.index] = o.mark
        }
        println("$file: ${tr.pointer}/${words.size} " + marks.entries.filter { it.value != Mark.Correct }.sortedBy { it.key }.joinToString { "${it.key}=${it.value}" })
        assertEquals(words.size, tr.pointer)
        return marks to tr
    }

    @Test fun ikhlas() { val (m, _) = run("ikhlas.txt", 112, 1, 4); assertEquals(15, m.values.count { it == Mark.Correct }) }

    @Test fun kursi() { val (m, _) = run("kursi.txt", 2, 255, 255); assertTrue(m.values.count { it == Mark.Correct } >= 48) }

    @Test fun skippedVerses() {
        val (m, _) = run("mulk23.txt", 67, 1, 5)
        assertTrue(m.values.count { it == Mark.Missed } >= 25)
        assertTrue((0..7).all { m[it] == Mark.Correct })
        assertTrue((40..59).all { m[it] == Mark.Correct })
    }
}
