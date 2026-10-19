package io.github.m7mdloverrr.quran.tasmee

import com.k2fsa.sherpa.onnx.OnlineRecognizerResult
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
import com.k2fsa.sherpa.onnx.OnlineModelConfig
import com.k2fsa.sherpa.onnx.OnlineRecognizer
import com.k2fsa.sherpa.onnx.OnlineRecognizerConfig
import com.k2fsa.sherpa.onnx.OnlineStream
import com.k2fsa.sherpa.onnx.OnlineZipformer2CtcModelConfig
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

/** Rolling recognition window and how often it is re-decoded. */
const val WINDOW_FRAMES = 4000 / FRAME_MS
const val STRIDE_MS = 300

/** Silence after the last word before the session finishes by itself. */
const val END_MS = 1200
/** Heard sounds without any matched word before the whole Quran is searched again. */
const val LOST_CHARS = 20

/** On-device Quran recitation recognizer (Whisper base fine-tuned on Quran recitation, int8 ONNX via sherpa-onnx). */
class QuranRecognizer(context: Context) {
    private val recognizer = OfflineRecognizer(
        null,
        OfflineRecognizerConfig(
            featConfig = FeatureConfig(sampleRate = SAMPLE_RATE, featureDim = 80),
            modelConfig = OfflineModelConfig(
                whisper = OfflineWhisperModelConfig(
                    encoder = ModelStore.file(context, ModelStore.whisper, "encoder.onnx"),
                    decoder = ModelStore.file(context, ModelStore.whisper, "decoder.onnx"),
                    language = "ar",
                    task = "transcribe",
                    tailPaddings = 1000,
                ),
                tokens = ModelStore.file(context, ModelStore.whisper, "tokens.txt"),
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

/** Streaming Quran-Lab zipformer CTC: emits a cumulative phoneme hypothesis as audio arrives. */
/** A streaming recognizer returning its cumulative hypothesis; [phonetic] outputs Quran-Lab phonemes, otherwise Arabic text. */
interface Streamer {
    val phonetic: Boolean
    fun reset()
    fun accept(samples: FloatArray): String
    fun finish(): String
    fun release()
    fun timing(): Tajweed.Timing? = null
}

class LiveRecognizer(context: Context) : Streamer {
    override val phonetic = true
    private val recognizer = OnlineRecognizer(
        context.assets,
        OnlineRecognizerConfig(
            featConfig = FeatureConfig(sampleRate = SAMPLE_RATE, featureDim = 80),
            modelConfig = OnlineModelConfig(
                zipformer2Ctc = OnlineZipformer2CtcModelConfig(model = "asr_live/model.int8.onnx"),
                tokens = "asr_live/tokens.txt",
                numThreads = 2,
            ),
            enableEndpoint = false,
            decodingMethod = "greedy_search",
        ),
    )
    private var stream: OnlineStream = recognizer.createStream()
    private var last: OnlineRecognizerResult? = null

    override fun timing() = last?.let { Tajweed.Timing(it.tokens, it.timestamps) }

    override fun reset() { stream.release(); stream = recognizer.createStream() }

    override fun accept(samples: FloatArray): String {
        stream.acceptWaveform(samples, SAMPLE_RATE)
        while (recognizer.isReady(stream)) recognizer.decode(stream)
        return recognizer.getResult(stream).also { last = it }.text
    }

    override fun finish(): String {
        stream.acceptWaveform(FloatArray(SAMPLE_RATE), SAMPLE_RATE)
        stream.inputFinished()
        while (recognizer.isReady(stream)) recognizer.decode(stream)
        return recognizer.getResult(stream).also { last = it }.text
    }

    override fun release() { stream.release(); recognizer.release() }
}
