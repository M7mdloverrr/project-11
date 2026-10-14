package io.github.m7mdloverrr.quran.tasmee

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import com.k2fsa.sherpa.onnx.FeatureConfig
import com.k2fsa.sherpa.onnx.OfflineModelConfig
import com.k2fsa.sherpa.onnx.OfflineRecognizer
import com.k2fsa.sherpa.onnx.OfflineRecognizerConfig
import com.k2fsa.sherpa.onnx.OfflineWhisperModelConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.isActive
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max

const val SAMPLE_RATE = 16000
const val FRAME = 480
const val FRAME_MS = 30

/** On-device Quran recitation recognizer (Whisper base fine-tuned on Quran recitation, int8 ONNX via sherpa-onnx). */
class QuranRecognizer(context: Context) {
    private val recognizer = OfflineRecognizer(
        context.assets,
        OfflineRecognizerConfig(
            featConfig = FeatureConfig(sampleRate = SAMPLE_RATE, featureDim = 80),
            modelConfig = OfflineModelConfig(
                whisper = OfflineWhisperModelConfig(
                    encoder = "asr/encoder.onnx",
                    decoder = "asr/decoder.onnx",
                    language = "ar",
                    task = "transcribe",
                    tailPaddings = 1000,
                ),
                tokens = "asr/tokens.txt",
                numThreads = Runtime.getRuntime().availableProcessors().coerceIn(2, 4),
                modelType = "whisper",
            ),
        ),
    )

    fun transcribe(samples: FloatArray): String {
        val lead = SAMPLE_RATE / 5
        val padded = FloatArray(lead + samples.size + SAMPLE_RATE)
        samples.copyInto(padded, lead)
        val stream = recognizer.createStream()
        return try {
            stream.acceptWaveform(padded, SAMPLE_RATE)
            recognizer.decode(stream)
            recognizer.getResult(stream).text.trim()
        } finally {
            stream.release()
        }
    }

    fun release() = recognizer.release()
}

interface AudioSource {
    fun frames(): Flow<FloatArray>
}

class MicSource : AudioSource {
    @SuppressLint("MissingPermission")
    override fun frames(): Flow<FloatArray> = flow {
        val min = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val rec = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION, SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, max(min, SAMPLE_RATE),
        )
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            throw IllegalStateException("microphone unavailable")
        }
        val buf = ShortArray(FRAME)
        try {
            rec.startRecording()
            while (currentCoroutineContext().isActive) {
                var n = 0
                while (n < FRAME) {
                    val r = rec.read(buf, n, FRAME - n)
                    if (r < 0) throw IllegalStateException("microphone read error $r")
                    n += r
                }
                emit(FloatArray(FRAME) { buf[it] / 32768f })
            }
        } finally {
            runCatching { rec.stop() }
            rec.release()
        }
    }.flowOn(Dispatchers.IO)
}

/** Debug-only source: plays a 16 kHz mono PCM WAV file in real time instead of the microphone. */
class WavSource(private val path: String) : AudioSource {
    override fun frames(): Flow<FloatArray> = flow {
        val bytes = File(path).readBytes()
        var off = 12
        var data = bytes.size
        var start = 44
        while (off + 8 <= bytes.size) {
            val id = String(bytes, off, 4, Charsets.US_ASCII)
            val len = ByteBuffer.wrap(bytes, off + 4, 4).order(ByteOrder.LITTLE_ENDIAN).int
            if (id == "data") { start = off + 8; data = minOf(bytes.size, start + len); break }
            off += 8 + len
        }
        val pcm = ByteBuffer.wrap(bytes, start, data - start).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val total = pcm.remaining()
        var i = 0
        while (i < total) {
            val n = minOf(FRAME, total - i)
            emit(FloatArray(FRAME) { if (it < n) pcm.get(i + it) / 32768f else 0f })
            i += FRAME
            delay(FRAME_MS.toLong())
        }
        while (currentCoroutineContext().isActive) {
            emit(FloatArray(FRAME))
            delay(FRAME_MS.toLong())
        }
    }.flowOn(Dispatchers.IO)
}

object TasmeeDebug {
    @Volatile var wav: String? = null
}
