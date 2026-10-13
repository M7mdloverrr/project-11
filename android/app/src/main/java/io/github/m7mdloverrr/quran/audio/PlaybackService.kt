package io.github.m7mdloverrr.quran.audio

import android.app.PendingIntent
import android.content.Intent
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import io.github.m7mdloverrr.quran.MainActivity
import io.github.m7mdloverrr.quran.data.AyahTimings
import io.github.m7mdloverrr.quran.data.Reciters
import android.content.Context
import androidx.media3.extractor.DefaultExtractorsFactory

/** Media item ids are "surah:ayah:repeatIndex:reciterId"; ayah 0 is the basmala. */
fun recitationUrl(mediaId: String): String? {
    val p = mediaId.split(":")
    val s = p.getOrNull(0)?.toIntOrNull() ?: return null
    val a = p.getOrNull(1)?.toIntOrNull() ?: return null
    val r = Reciters.byId(p.getOrNull(3))
    return if (a == 0) r.url(1, 1) else r.url(s, a)
}

/** Sets the uri (and the clip inside a whole-surah file, if any) for a recitation media id. */
fun MediaItem.Builder.recitation(context: Context, mediaId: String): MediaItem.Builder {
    val p = mediaId.split(":")
    val s = p.getOrNull(0)?.toIntOrNull() ?: return this
    val a = p.getOrNull(1)?.toIntOrNull() ?: return this
    val r = Reciters.byId(p.getOrNull(3))
    val (cs, ca) = if (a == 0) 1 to 1 else s to a
    setUri(r.url(cs, ca))
    AyahTimings.clip(context, r, cs, ca)?.let { (start, end) ->
        setClippingConfiguration(
            MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(end).build(),
        )
    }
    return this
}

@OptIn(UnstableApi::class)
class PlaybackService : MediaSessionService() {
    private var session: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        val player = ExoPlayer.Builder(this)
            .setMediaSourceFactory(DefaultMediaSourceFactory(
                    AudioCache.dataSourceFactory(this),
                    DefaultExtractorsFactory().setConstantBitrateSeekingEnabled(true),
                ),
            )
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_SPEECH).build(),
                true,
            )
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .build()
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        session = MediaSession.Builder(this, player)
            .setSessionActivity(open)
            .setCallback(object : MediaSession.Callback {
                override fun onAddMediaItems(
                    mediaSession: MediaSession,
                    controller: MediaSession.ControllerInfo,
                    mediaItems: MutableList<MediaItem>,
                ): ListenableFuture<MutableList<MediaItem>> = Futures.immediateFuture(
                    mediaItems.map { item ->
                        if (recitationUrl(item.mediaId) == null) item
                        else item.buildUpon().recitation(this@PlaybackService, item.mediaId).build()
                    }.toMutableList(),
                )
            })
            .build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo) = session

    override fun onTaskRemoved(rootIntent: Intent?) {
        val p = session?.player
        if (p == null || !p.playWhenReady || p.mediaItemCount == 0) stopSelf()
    }

    override fun onDestroy() {
        session?.run {
            player.release()
            release()
        }
        session = null
        super.onDestroy()
    }
}
