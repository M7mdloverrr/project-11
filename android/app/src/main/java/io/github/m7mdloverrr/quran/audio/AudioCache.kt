package io.github.m7mdloverrr.quran.audio

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import io.github.m7mdloverrr.quran.data.Reciter
import java.io.File

/** Single on-disk store for streamed and downloaded recitations, so played verses stay available offline. */
@OptIn(UnstableApi::class)
object AudioCache {
    @Volatile private var cache: SimpleCache? = null

    fun get(context: Context): SimpleCache = cache ?: synchronized(this) {
        cache ?: SimpleCache(
            File(context.applicationContext.filesDir, "recitations"),
            NoOpCacheEvictor(),
            StandaloneDatabaseProvider(context.applicationContext),
        ).also { cache = it }
    }

    fun dataSourceFactory(context: Context): CacheDataSource.Factory = CacheDataSource.Factory()
        .setCache(get(context))
        .setUpstreamDataSourceFactory(
            DefaultHttpDataSource.Factory()
                .setConnectTimeoutMs(15_000)
                .setReadTimeoutMs(20_000)
                .setAllowCrossProtocolRedirects(true),
        )
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)

    fun removeReciter(context: Context, reciter: Reciter) {
        val c = get(context)
        c.keys.filter { it.contains("/${reciter.folder}/") }.forEach { c.removeResource(it) }
    }

    fun sizeBytes(context: Context): Long = get(context).cacheSpace
}
