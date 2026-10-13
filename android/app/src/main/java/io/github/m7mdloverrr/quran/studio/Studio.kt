package io.github.m7mdloverrr.quran.studio

import io.github.m7mdloverrr.quran.data.shown
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import androidx.annotation.OptIn
import androidx.core.content.res.ResourcesCompat
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSpec
import androidx.media3.common.Effect
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.TextureOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.common.OverlaySettings
import androidx.media3.effect.Presentation
import androidx.media3.effect.RgbAdjustment
import androidx.media3.effect.StaticOverlaySettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.github.m7mdloverrr.quran.R
import io.github.m7mdloverrr.quran.audio.AudioCache
import io.github.m7mdloverrr.quran.data.Ayah
import io.github.m7mdloverrr.quran.data.Reciter
import io.github.m7mdloverrr.quran.data.ar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import java.util.Locale
import kotlin.coroutines.coroutineContext
import kotlin.math.min

class Background(val id: String, val nameAr: String, val thumb: Int, val credit: String) {
    val uri: Uri get() = Uri.parse("asset:///backgrounds/$id.mp4")
}

val Backgrounds = listOf(
    Background("waterfall", "شلال", R.drawable.bg_waterfall, "Llywelyn2000, CC BY-SA 4.0 — Wikimedia Commons"),
    Background("forest", "غابة", R.drawable.bg_forest, "Queen Asali, CC BY-SA 4.0 — Wikimedia Commons"),
    Background("ocean", "بحر", R.drawable.bg_ocean, "Nature video, HD - 4K, CC BY 3.0 — Wikimedia Commons"),
    Background("mountains", "جبال", R.drawable.bg_mountains, "Pastelitodepapa, CC0 — Wikimedia Commons"),
    Background("rain", "مطر", R.drawable.bg_rain, "Shishirdasika, CC BY-SA 4.0 — Wikimedia Commons"),
    Background("sunset", "غروب", R.drawable.bg_sunset, "Ian Furst, CC BY-SA 4.0 — Wikimedia Commons"),
)

val TextColors = listOf(0xFFFFFFFF, 0xFFF4D58D, 0xFFBDEFD9, 0xFF111111)

data class StudioStyle(
    val font: Int = 0,
    val size: Float = 1f,
    val color: Long = 0xFFFFFFFF,
    val position: Int = 1,
    val shadow: Boolean = true,
    val dim: Float = 0.35f,
)

enum class Aspect(val label: String, val w: Int, val h: Int) {
    Portrait("9:16", 9, 16), Landscape("16:9", 16, 9), Square("1:1", 1, 1);

    /** Output size whose short side equals [shortSide], rounded to even pixels. */
    fun size(shortSide: Int): Pair<Int, Int> =
        if (w <= h) shortSide to (shortSide * h / w) / 2 * 2 else (shortSide * w / h) / 2 * 2 to shortSide
}

class VerseClip(val ayah: Ayah, val file: File, val durationUs: Long)

class VerseRenderer(context: Context, val cfg: StudioStyle, private val surahName: String, private val reciterName: String) {
    private val typeface: Typeface =
        if (cfg.font == 0) ResourcesCompat.getFont(context, when (io.github.m7mdloverrr.quran.data.Scripts.index) { 0 -> R.font.kfgqpc_hafs; 3 -> R.font.indopak; else -> R.font.amiri_quran }) ?: Typeface.SERIF
        else Typeface.create(Typeface.SERIF, Typeface.NORMAL)

    fun render(w: Int, h: Int, ayah: Ayah): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val unit = min(w, h) / 1080f
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = this@VerseRenderer.typeface
            color = cfg.color.toInt()
            textSize = 72f * unit * cfg.size
            if (cfg.shadow) setShadowLayer(14f * unit, 0f, 4f * unit, 0xD0000000.toInt())
        }
        val text = ayah.shown + (if (io.github.m7mdloverrr.quran.data.Scripts.index == 0) " " else " \u06DD") + ayah.number.ar()
        val maxW = (w * 0.86f).toInt()
        val maxH = h * 0.62f
        var layout: StaticLayout
        while (true) {
            layout = StaticLayout.Builder.obtain(text, 0, text.length, paint, maxW)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setTextDirection(TextDirectionHeuristics.RTL)
                .setLineSpacing(0f, 1.2f)
                .build()
            if (layout.height <= maxH || paint.textSize < 22f * unit) break
            paint.textSize *= 0.92f
        }
        val top = when (cfg.position) {
            0 -> h * 0.10f
            2 -> h * 0.86f - layout.height
            else -> (h - layout.height) / 2f
        }
        canvas.save()
        canvas.translate((w - maxW) / 2f, top)
        layout.draw(canvas)
        canvas.restore()
        val cap = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = cfg.color.toInt()
            alpha = 220
            textSize = 34f * unit
            textAlign = Paint.Align.CENTER
            if (cfg.shadow) setShadowLayer(10f * unit, 0f, 3f * unit, 0xD0000000.toInt())
        }
        val capY = if (cfg.position == 2) top - 36f * unit else top + layout.height + 64f * unit
        canvas.drawText("$surahName • الآية ${ayah.number.ar()} • $reciterName", w / 2f, capY, cap)
        return bmp
    }
}

class AudioMissing(val ayah: Ayah) : Exception()

@OptIn(UnstableApi::class)
suspend fun prepareAudio(ctx: Context, reciter: Reciter, ayahs: List<Ayah>, progress: (Float) -> Unit): List<VerseClip> =
    withContext(Dispatchers.IO) {
        val dir = File(ctx.cacheDir, "studio/${reciter.id}").apply { mkdirs() }
        val factory = AudioCache.dataSourceFactory(ctx)
        ayahs.mapIndexed { i, a ->
            coroutineContext.ensureActive()
            val f = File(dir, String.format(Locale.US, "%03d%03d.mp3", a.surah, a.number))
            if (!f.exists() || f.length() == 0L) {
                val tmp = File(f.path + ".part")
                val ds = factory.createDataSource()
                try {
                    ds.open(DataSpec(Uri.parse(reciter.url(a.surah, a.number))))
                    tmp.outputStream().use { out ->
                        val buf = ByteArray(64 * 1024)
                        while (true) {
                            val n = ds.read(buf, 0, buf.size)
                            if (n == C.RESULT_END_OF_INPUT) break
                            out.write(buf, 0, n)
                        }
                    }
                } catch (e: androidx.media3.datasource.HttpDataSource.InvalidResponseCodeException) {
                    throw AudioMissing(a)
                } finally {
                    ds.close()
                }
                tmp.renameTo(f)
            }
            val mmr = MediaMetadataRetriever()
            val ms = try {
                mmr.setDataSource(f.path)
                mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            } finally {
                mmr.release()
            }
            if (ms <= 0) { f.delete(); throw AudioMissing(a) }
            progress((i + 1f) / ayahs.size)
            // Small margin below the container duration so each clip is fully decodable and verse timing never drifts.
            VerseClip(a, f, (ms - 60).coerceAtLeast(200) * 1000L)
        }
    }

/** Builds a real MP4: looping background video + verse-by-verse recitation + synchronized Quran text overlay. */
@OptIn(UnstableApi::class)
fun startExport(
    ctx: Context,
    clips: List<VerseClip>,
    background: Uri,
    width: Int,
    height: Int,
    renderer: VerseRenderer,
    out: File,
    onDone: () -> Unit,
    onError: (ExportException) -> Unit,
): Transformer {
    val starts = clips.runningFold(0L) { acc, c -> acc + c.durationUs }
    val overlay = object : BitmapOverlay() {
        private var current = -1
        private var bitmap: Bitmap? = null
        private var base = 0L
        private var prev = -1L

        private fun timeline(t: Long): Long {
            if (prev >= 0 && t < prev) base += prev + 33_333
            prev = t
            return base + t
        }

        private fun indexAt(abs: Long): Int {
            val i = starts.indexOfLast { it <= abs }.coerceIn(0, clips.lastIndex)
            return i
        }

        private var lastAbs = 0L

        override fun getBitmap(presentationTimeUs: Long): Bitmap {
            lastAbs = timeline(presentationTimeUs)
            val i = indexAt(lastAbs)
            if (i != current || bitmap == null) {
                bitmap = renderer.render(width, height, clips[i].ayah)
                current = i
            }
            return bitmap!!
        }

        override fun getOverlaySettings(presentationTimeUs: Long): OverlaySettings {
            val i = indexAt(lastAbs)
            val alpha = ((lastAbs - starts[i]) / 350_000f).coerceIn(0f, 1f)
            return StaticOverlaySettings.Builder().setAlphaScale(alpha).build()
        }
    }
    val dim = 1f - renderer.cfg.dim
    val bg = EditedMediaItem.Builder(MediaItem.fromUri(background))
        .setRemoveAudio(true)
        .setEffects(
            Effects(
                ImmutableList.of(),
                ImmutableList.of<Effect>(
                    Presentation.createForWidthAndHeight(width, height, Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP),
                    RgbAdjustment.Builder().setRedScale(dim).setGreenScale(dim).setBlueScale(dim).build(),
                    OverlayEffect(ImmutableList.of<TextureOverlay>(overlay)),
                ),
            ),
        )
        .build()
    val audio = clips.map { c ->
        EditedMediaItem.Builder(
            MediaItem.Builder().setUri(Uri.fromFile(c.file))
                .setClippingConfiguration(MediaItem.ClippingConfiguration.Builder().setEndPositionUs(c.durationUs).build())
                .build(),
        ).build()
    }
    val composition = Composition.Builder(
        EditedMediaItemSequence.Builder(audio).build(),
        EditedMediaItemSequence.Builder(bg).setIsLooping(true).build(),
    ).build()
    val transformer = Transformer.Builder(ctx)
        .setVideoMimeType(MimeTypes.VIDEO_H264)
        .setAudioMimeType(MimeTypes.AUDIO_AAC)
        .addListener(object : Transformer.Listener {
            override fun onCompleted(composition: Composition, exportResult: ExportResult) = onDone()
            override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) = onError(exportException)
        })
        .build()
    transformer.start(composition, out.path)
    return transformer
}

fun saveToGallery(ctx: Context, file: File, name: String): Uri {
    val resolver = ctx.contentResolver
    val values = ContentValues().apply {
        put(MediaStore.Video.Media.DISPLAY_NAME, name)
        put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
        put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/Quran")
        put(MediaStore.Video.Media.IS_PENDING, 1)
    }
    val uri = resolver.insert(MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), values)
        ?: error("MediaStore insert failed")
    try {
        resolver.openOutputStream(uri)!!.use { o -> file.inputStream().use { it.copyTo(o) } }
        resolver.update(uri, ContentValues().apply { put(MediaStore.Video.Media.IS_PENDING, 0) }, null, null)
    } catch (e: Exception) {
        resolver.delete(uri, null, null)
        throw e
    }
    return uri
}
