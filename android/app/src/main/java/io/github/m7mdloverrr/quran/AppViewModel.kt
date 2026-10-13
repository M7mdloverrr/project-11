package io.github.m7mdloverrr.quran

import android.app.Application
import android.content.ComponentName
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import androidx.work.WorkInfo
import androidx.work.WorkManager
import io.github.m7mdloverrr.quran.audio.AudioCache
import io.github.m7mdloverrr.quran.audio.DownloadWorker
import io.github.m7mdloverrr.quran.audio.PlaybackService
import io.github.m7mdloverrr.quran.audio.recitationUrl
import io.github.m7mdloverrr.quran.data.Prefs
import io.github.m7mdloverrr.quran.data.Quran
import io.github.m7mdloverrr.quran.data.QuranRepository
import io.github.m7mdloverrr.quran.data.Reciter
import io.github.m7mdloverrr.quran.data.Settings
import io.github.m7mdloverrr.quran.data.Surah
import io.github.m7mdloverrr.quran.data.ar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class PlayingState(val surah: Int = 0, val ayah: Int = 0, val isPlaying: Boolean = false, val buffering: Boolean = false) {
    val active get() = surah > 0
}

data class UiMessage(val text: String, val retry: Boolean = false, val id: Long = System.nanoTime())

data class DownloadState(val running: Boolean, val progress: Float)

class AppViewModel(private val app: Application) : AndroidViewModel(app) {
    val prefs = Prefs(app)
    val settings: StateFlow<Settings?> = prefs.settings.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    private val _quran = MutableStateFlow<Quran?>(null)
    val quran = _quran.asStateFlow()
    private val _playing = MutableStateFlow(PlayingState())
    val playing = _playing.asStateFlow()
    private val _message = MutableStateFlow<UiMessage?>(null)
    val message = _message.asStateFlow()

    val downloads: StateFlow<Map<String, DownloadState>> = WorkManager.getInstance(app)
        .getWorkInfosByTagFlow(DownloadWorker.TAG)
        .map { infos ->
            infos.filter { !it.state.isFinished }.mapNotNull { info ->
                val name = info.tags.firstOrNull { it.startsWith("dl:") } ?: return@mapNotNull null
                val done = info.progress.getInt(DownloadWorker.KEY_DONE, 0)
                val total = info.progress.getInt(DownloadWorker.KEY_TOTAL, 0)
                name to DownloadState(info.state == WorkInfo.State.RUNNING, if (total > 0) done / total.toFloat() else 0f)
            }.toMap()
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    private val _cacheBytes = MutableStateFlow(0L)
    val cacheBytes = _cacheBytes.asStateFlow()

    private var controller: MediaController? = null
    private val controllerFuture = MediaController.Builder(app, SessionToken(app, ComponentName(app, PlaybackService::class.java))).buildAsync()
    private var endedHandled = false
    private var pending: Pair<Int, Int>? = null

    private val listener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) = sync(player)
        override fun onPlayerError(error: PlaybackException) = handleError(error)
    }

    init {
        viewModelScope.launch { _quran.value = QuranRepository.load(app) }
        controllerFuture.addListener({
            controller = runCatching { controllerFuture.get() }.getOrNull()?.also {
                it.addListener(listener)
                sync(it)
                pending?.let { (s, a) -> pending = null; play(s, a) }
            }
            if (controller == null) _message.value = UiMessage("تعذّر تشغيل مشغل الصوت")
        }, ContextCompat.getMainExecutor(app))
    }

    private fun sync(p: Player) {
        val id = p.currentMediaItem?.mediaId?.split(":")
        val s = id?.getOrNull(0)?.toIntOrNull() ?: 0
        val a = id?.getOrNull(1)?.toIntOrNull() ?: 0
        _playing.value = PlayingState(s, a, p.isPlaying, p.playbackState == Player.STATE_BUFFERING)
        if (p.playbackState == Player.STATE_ENDED) {
            if (!endedHandled) {
                endedHandled = true
                val st = settings.value
                if (st != null && st.continuous && s in 1..113) play(s + 1, 1)
            }
        } else {
            endedHandled = false
        }
    }

    private fun handleError(error: PlaybackException) {
        val c = controller ?: return
        val missing = error.errorCode == PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS ||
            error.errorCode == PlaybackException.ERROR_CODE_IO_FILE_NOT_FOUND
        if (missing && c.hasNextMediaItem()) {
            _message.value = UiMessage("تلاوة هذه الآية غير متوفرة لدى هذا القارئ، تم الانتقال إلى التالية")
            c.seekToNextMediaItem()
            c.prepare()
            c.play()
        } else {
            _message.value = UiMessage("تعذّر تشغيل التلاوة. تحقّق من الاتصال بالإنترنت أو حمّل السورة للاستماع دون اتصال.", retry = true)
        }
    }

    fun retry() {
        controller?.run { prepare(); play() }
    }

    fun consumeMessage(id: Long) {
        if (_message.value?.id == id) _message.value = null
    }

    fun play(surah: Int, ayah: Int, reciter: Reciter? = null, repeat: Int? = null) {
        val q = quran.value ?: return
        val st = settings.value ?: return
        val c = controller ?: run { pending = surah to ayah; return }
        val sura = q.surah(surah)
        val r = reciter ?: st.reciter
        val rep = repeat ?: st.repeat
        val times = if (rep <= 0) 1 else rep
        val start = ayah.coerceIn(1, sura.ayahs.size)
        val items = ArrayList<MediaItem>()
        if (start == 1 && sura.hasBasmala && rep > 0) items += item(r, sura, 0, 0)
        for (a in start..sura.ayahs.size) for (k in 0 until times) items += item(r, sura, a, k)
        c.repeatMode = if (rep <= 0) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        c.setMediaItems(items)
        c.setPlaybackSpeed(st.speed)
        c.prepare()
        c.play()
        _message.value = null
        viewModelScope.launch { prefs.saveLastRead(surah, start, q.ayah(surah, start).page) }
    }

    private fun item(r: Reciter, sura: Surah, ayah: Int, k: Int): MediaItem {
        val id = "${sura.number}:$ayah:$k:${r.id}"
        val title = if (ayah == 0) "سورة ${sura.name} • البسملة" else "${sura.name} • الآية ${ayah.ar()}"
        return MediaItem.Builder()
            .setMediaId(id)
            .setUri(recitationUrl(id))
            .setMediaMetadata(MediaMetadata.Builder().setTitle(title).setArtist(r.nameAr).setAlbumTitle("القرآن الكريم").build())
            .build()
    }

    fun togglePlay(fallbackSurah: Int, fallbackAyah: Int) {
        val c = controller ?: return
        when {
            c.mediaItemCount == 0 -> play(fallbackSurah, fallbackAyah)
            c.isPlaying -> c.pause()
            c.playbackState == Player.STATE_ENDED -> play(fallbackSurah, fallbackAyah)
            else -> {
                if (c.playbackState == Player.STATE_IDLE) c.prepare()
                c.play()
            }
        }
    }

    fun step(surah: Int, ayah: Int, delta: Int) {
        val q = quran.value ?: return
        val count = q.surah(surah).ayahs.size
        val target = ayah + delta
        when {
            target in 1..count -> play(surah, target)
            target > count && surah < 114 -> play(surah + 1, 1)
            target < 1 && surah > 1 -> play(surah - 1, q.surah(surah - 1).ayahs.size)
        }
    }

    private fun restartIfActive(reciter: Reciter? = null, repeat: Int? = null) {
        val p = playing.value
        if (p.active && controller?.isPlaying == true) play(p.surah, p.ayah.coerceAtLeast(1), reciter, repeat)
    }

    fun setReciter(r: Reciter) = viewModelScope.launch {
        prefs.set(Prefs.Keys.reciter, r.id)
        restartIfActive(reciter = r)
    }

    fun setRepeat(n: Int) = viewModelScope.launch {
        prefs.set(Prefs.Keys.repeat, n)
        restartIfActive(repeat = n)
    }

    fun setSpeed(v: Float) = viewModelScope.launch {
        prefs.set(Prefs.Keys.speed, v)
        controller?.setPlaybackSpeed(v)
    }

    fun setFontSize(v: Float) = viewModelScope.launch { prefs.set(Prefs.Keys.fontSize, v.coerceIn(18f, 44f)) }
    fun setTheme(v: Int) = viewModelScope.launch { prefs.set(Prefs.Keys.theme, v) }
    fun setContinuous(v: Boolean) = viewModelScope.launch { prefs.set(Prefs.Keys.continuous, v) }
    fun savePage(page: Int) = viewModelScope.launch { prefs.set(Prefs.Keys.lastPage, page) }
    fun toggleBookmark(key: String) = viewModelScope.launch { prefs.toggle(Prefs.Keys.bookmarks, key) }

    fun download(reciter: Reciter, surah: Surah) =
        DownloadWorker.enqueue(app, reciter.id, surah.number, surah.ayahs.size)

    fun downloadAll(reciter: Reciter) {
        val q = quran.value ?: return
        val done = settings.value?.downloaded ?: emptySet()
        q.surahs.filter { "${reciter.id}:${it.number}" !in done }.forEach { download(reciter, it) }
    }

    fun deleteDownloads(reciter: Reciter) = viewModelScope.launch {
        DownloadWorker.cancelReciter(app, reciter.id)
        withContext(Dispatchers.IO) { AudioCache.removeReciter(app, reciter) }
        prefs.removeDownloads(reciter.id)
        refreshCacheSize()
    }

    fun refreshCacheSize() = viewModelScope.launch {
        _cacheBytes.value = withContext(Dispatchers.IO) { AudioCache.sizeBytes(app) }
    }

    override fun onCleared() {
        controller?.removeListener(listener)
        MediaController.releaseFuture(controllerFuture)
    }
}
