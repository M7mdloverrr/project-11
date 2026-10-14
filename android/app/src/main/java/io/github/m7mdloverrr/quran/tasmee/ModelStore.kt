package io.github.m7mdloverrr.quran.tasmee

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/** Optional speech models downloaded on demand from the project's GitHub release. */
object ModelStore {
    class Model(val id: String, val files: List<Pair<String, Long>>) {
        val bytes get() = files.sumOf { it.second }
    }

    private const val BASE = "https://github.com/M7mdloverrr/project-11/releases/download/tasmee-models-v1/"

    val whisper = Model(
        "whisper",
        listOf("encoder.onnx" to 29_104_812L, "decoder.onnx" to 50_994_860L, "tokens.txt" to 816_730L),
    )

    fun dir(context: Context, m: Model) = File(context.filesDir, "models/${m.id}")

    fun file(context: Context, m: Model, name: String) = File(dir(context, m), name).absolutePath

    fun ready(context: Context, m: Model) = m.files.all { (n, size) -> File(dir(context, m), n).length() == size }

    fun delete(context: Context, m: Model) {
        dir(context, m).deleteRecursively()
    }

    suspend fun download(context: Context, m: Model, progress: (Float) -> Unit) = withContext(Dispatchers.IO) {
        val d = dir(context, m).apply { mkdirs() }
        var done = 0L
        for ((name, size) in m.files) {
            val out = File(d, name)
            if (out.length() == size) { done += size; continue }
            val part = File(d, "$name.part")
            var have = if (part.exists()) part.length() else 0L
            if (have > size) { part.delete(); have = 0 }
            val conn = URL(BASE + "${m.id}-$name").openConnection() as HttpURLConnection
            try {
                conn.connectTimeout = 15_000
                conn.readTimeout = 30_000
                if (have > 0) conn.setRequestProperty("Range", "bytes=$have-")
                val code = conn.responseCode
                if (code != 200 && code != 206) throw IOException("HTTP $code")
                if (code == 200) have = 0
                conn.inputStream.use { inp ->
                    java.io.FileOutputStream(part, have > 0).use { o ->
                        val buf = ByteArray(64 * 1024)
                        while (true) {
                            currentCoroutineContext().ensureActive()
                            val n = inp.read(buf)
                            if (n < 0) break
                            o.write(buf, 0, n)
                            have += n
                            progress((done + have).toFloat() / m.bytes)
                        }
                    }
                }
            } finally {
                conn.disconnect()
            }
            if (part.length() != size) throw IOException("incomplete $name")
            if (!part.renameTo(out)) throw IOException("rename $name")
            done += size
        }
        progress(1f)
    }
}
