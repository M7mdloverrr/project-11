package io.github.m7mdloverrr.quran.tasmee

import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.max

class NemoMelTest {
    @Test fun matchesLibrosa() {
        val bytes = javaClass.getResource("/live/ikhlas3s.wav")!!.readBytes()
        val pcm = ByteBuffer.wrap(bytes, 44, bytes.size - 44).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val x = FloatArray(pcm.remaining()) { pcm.get(it) / 32768f }
        val mel = NemoMel()
        val frames = ArrayList<FloatArray>()
        var i = 0
        while (i < x.size) { frames.addAll(mel.accept(x.copyOfRange(i, minOf(x.size, i + 480)))); i += 480 }
        val ref = javaClass.getResource("/live/mel_ikhlas.txt")!!.readText().lines().map { l -> l.split(' ').map { it.toFloat() } }
        var worst = 0f
        for (t in 0 until minOf(ref.size, frames.size)) for (m in 0 until 80) if (ref[t][m] > -10f) worst = max(worst, abs(ref[t][m] - frames[t][m]))
        println("mel frames=${frames.size} worst=$worst")
        assertTrue(worst < 0.05f)
    }
}
