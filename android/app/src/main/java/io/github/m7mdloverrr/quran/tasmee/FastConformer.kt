package io.github.m7mdloverrr.quran.tasmee

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import java.io.File
import java.nio.FloatBuffer
import java.nio.LongBuffer
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/** NeMo-style streaming log-mel features: pre-emphasis 0.97, 25 ms Hann window, 10 ms hop, 512-point FFT, 80 Slaney mels. */
class NemoMel {
    private val nFft = 512
    private val hop = 160
    private val win = FloatArray(nFft).also { w ->
        val off = (nFft - 400) / 2
        for (i in 0 until 400) w[off + i] = (0.5 - 0.5 * cos(2 * PI * i / 400)).toFloat()
    }
    private val mel = melBank()
    private var buf = FloatArray(nFft / 2)
    private var len = nFft / 2
    private var start = -(nFft / 2).toLong()
    private var next = 0L
    private var prev = 0f
    private val re = FloatArray(nFft)
    private val im = FloatArray(nFft)
    private val rev = IntArray(nFft).also { r -> val bits = 9; for (i in 0 until nFft) r[i] = Integer.reverse(i) ushr (32 - bits) }

    /** Feeds 16 kHz samples and returns any newly completed 80-dim frames. */
    fun accept(samples: FloatArray): List<FloatArray> {
        if (len + samples.size > buf.size) buf = buf.copyOf(max(buf.size * 2, len + samples.size))
        for (x in samples) { buf[len++] = x - 0.97f * prev; prev = x }
        val out = ArrayList<FloatArray>()
        while (true) {
            val s0 = next * hop - nFft / 2
            val i0 = (s0 - start).toInt()
            if (i0 + nFft > len) break
            out.add(frame(i0)); next++
        }
        val drop = ((next * hop - nFft / 2) - start).toInt()
        if (drop > 0) { System.arraycopy(buf, drop, buf, 0, len - drop); len -= drop; start += drop }
        return out
    }

    private fun frame(i0: Int): FloatArray {
        for (i in 0 until nFft) { re[rev[i]] = buf[i0 + i] * win[i]; im[rev[i]] = 0f }
        var size = 2
        while (size <= nFft) {
            val half = size / 2; val step = -2 * PI / size
            for (k in 0 until half) {
                val wr = cos(step * k).toFloat(); val wi = sin(step * k).toFloat()
                var j = k
                while (j < nFft) {
                    val l = j + half
                    val tr = wr * re[l] - wi * im[l]; val ti = wr * im[l] + wi * re[l]
                    re[l] = re[j] - tr; im[l] = im[j] - ti; re[j] += tr; im[j] += ti
                    j += size
                }
            }
            size *= 2
        }
        val f = FloatArray(80)
        for (m in 0 until 80) {
            var s = 0f
            val row = mel[m]
            for (k in row.indices) if (row[k] != 0f) s += row[k] * (re[k] * re[k] + im[k] * im[k])
            f[m] = ln(s + 5.9604645e-8f)
        }
        return f
    }

    private fun melBank(): Array<FloatArray> {
        fun hz2mel(h: Double): Double = if (h < 1000) h / (200.0 / 3) else 15 + ln(h / 1000) / (ln(6.4) / 27)
        fun mel2hz(m: Double): Double = if (m < 15) m * 200.0 / 3 else 1000 * kotlin.math.exp((ln(6.4) / 27) * (m - 15))
        val bins = nFft / 2 + 1
        val pts = DoubleArray(82) { mel2hz(hz2mel(0.0) + (hz2mel(8000.0) - hz2mel(0.0)) * it / 81) }
        return Array(80) { m ->
            val lo = pts[m]; val c = pts[m + 1]; val hi = pts[m + 2]
            val enorm = 2.0 / (hi - lo)
            FloatArray(bins) { k ->
                val hz = k * 8000.0 / (bins - 1)
                (max(0.0, min((hz - lo) / (c - lo), (hi - hz) / (hi - c))) * enorm).toFloat()
            }
        }
    }
}

/** Streaming FastConformer CTC (Muno459/fastconformer-quran) with NeMo cache-aware inference. */
class FastConformerRecognizer(context: Context) : Streamer {
    override val phonetic = false
    private val env = OrtEnvironment.getEnvironment()
    private val session = env.createSession(
        ModelStore.file(context, ModelStore.fastConformer, "model.onnx"),
        OrtSession.SessionOptions().apply { setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceIn(2, 4)) },
    )
    private val vocab = File(ModelStore.file(context, ModelStore.fastConformer, "tokens.txt")).readLines()
        .filter { it.isNotBlank() }.map { it.substringBeforeLast(' ') }
    private val blank = vocab.size

    private lateinit var mel: NemoMel
    private val frames = ArrayList<FloatArray>()
    private val sum = DoubleArray(80)
    private val sq = DoubleArray(80)
    private var seen = 0
    private var done = 0
    private var cacheCh = FloatArray(17 * 70 * 512)
    private var cacheT = FloatArray(17 * 512 * 8)
    private var cacheLen = 0L
    private var last = -1
    private val text = StringBuilder()

    init { reset() }

    override fun reset() {
        mel = NemoMel(); frames.clear(); sum.fill(0.0); sq.fill(0.0); seen = 0; done = 0
        cacheCh.fill(0f); cacheT.fill(0f); cacheLen = 0; last = -1; text.setLength(0)
    }

    override fun accept(samples: FloatArray): String {
        for (f in mel.accept(samples)) {
            frames.add(f); seen++
            for (i in 0 until 80) { sum[i] += f[i]; sq[i] += f[i].toDouble() * f[i] }
        }
        while (seen >= done + CHUNK) step()
        return text.toString()
    }

    override fun finish(): String {
        accept(FloatArray(CHUNK * 160 + 4000))
        return text.toString()
    }

    private fun step() {
        val base = seen - frames.size
        val from = max(0, done - PRE)
        val n = done + CHUNK - from
        val x = FloatArray(80 * n)
        val mean = DoubleArray(80) { sum[it] / seen }
        for (i in 0 until 80) {
            val sd = sqrt(max(0.0, sq[i] / seen - mean[i] * mean[i])) + 1e-5
            for (t in 0 until n) x[i * n + t] = ((frames[from + t - base][i] - mean[i]) / sd).toFloat()
        }
        val inputs = mapOf(
            "audio_signal" to OnnxTensor.createTensor(env, FloatBuffer.wrap(x), longArrayOf(1, 80, n.toLong())),
            "length" to OnnxTensor.createTensor(env, LongBuffer.wrap(longArrayOf(n.toLong())), longArrayOf(1)),
            "cache_last_channel" to OnnxTensor.createTensor(env, FloatBuffer.wrap(cacheCh), longArrayOf(1, 17, 70, 512)),
            "cache_last_time" to OnnxTensor.createTensor(env, FloatBuffer.wrap(cacheT), longArrayOf(1, 17, 512, 8)),
            "cache_last_channel_len" to OnnxTensor.createTensor(env, LongBuffer.wrap(longArrayOf(cacheLen)), longArrayOf(1)),
        )
        try {
            session.run(inputs).use { r ->
                @Suppress("UNCHECKED_CAST")
                val lp = (r[0].value as Array<Array<FloatArray>>)[0]
                for (row in lp) {
                    var best = 0
                    for (k in row.indices) if (row[k] > row[best]) best = k
                    if (best != last && best != blank && best < vocab.size) text.append(vocab[best].replace('\u2581', ' '))
                    last = best
                }
                cacheCh = (r[r.size() - 3] as OnnxTensor).floatBuffer.let { b -> FloatArray(b.remaining()).also { b.get(it) } }
                cacheT = (r[r.size() - 2] as OnnxTensor).floatBuffer.let { b -> FloatArray(b.remaining()).also { b.get(it) } }
                cacheLen = (r[r.size() - 1] as OnnxTensor).longBuffer.get(0)
            }
        } finally {
            inputs.values.forEach { it.close() }
        }
        done += CHUNK
        val keep = done - PRE - base
        if (keep > 0) repeat(keep) { frames.removeAt(0) }
    }

    override fun release() { session.close() }

    companion object {
        const val CHUNK = 112
        const val PRE = 9
    }
}
