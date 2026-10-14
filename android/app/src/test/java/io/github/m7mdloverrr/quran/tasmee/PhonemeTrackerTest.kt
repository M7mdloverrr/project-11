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
            if (final) println("$file before final: ${tr.pointer}/${words.size}")
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

    @Test fun wrongWordInserted() {
        val (m, _) = run("fat_ins.txt", 1, 1, 7)
        assertTrue((8..28).count { m[it] == Mark.Correct } >= 19)
    }

    @Test fun wrongWordsReplaced() {
        val (m, _) = run("fat_sub.txt", 1, 1, 7)
        assertTrue((10..28).count { m[it] == Mark.Correct } >= 17)
    }

    @Test fun oneWrongWordLive() {
        val words = (1..7).flatMap { a -> surahs[0][a - 1].split(' ').map { if (it == "-") "" else it } }
        val full = javaClass.getResource("/live/fat_ins.txt")!!.readText().lines().last().removePrefix("FINAL ")
        val i = full.indexOf("قُلءَررَحمَاانِ")
        val said = full.substring(0, i) + "ءَررَحمَاانِقُلهُوَ" + full.substring(full.indexOf("مَاالِكِ"))
        val tr = PhonemeTracker(words, 0.35f)
        val marks = HashMap<Int, Mark>()
        for (n in 3..said.length step 3) for (o in tr.update(said.substring(0, n), false)) marks[o.index] = o.mark
        println("live wrong: ${tr.pointer}/${words.size} " + marks.entries.filter { it.value != Mark.Correct }.joinToString { "${it.key}=${it.value}" })
        assertTrue(tr.pointer >= 27)
        assertEquals(Mark.Wrong, marks[9])
    }
}
