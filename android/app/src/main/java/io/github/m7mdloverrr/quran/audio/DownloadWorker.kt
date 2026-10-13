package io.github.m7mdloverrr.quran.audio

import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.cache.CacheWriter
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import io.github.m7mdloverrr.quran.data.Prefs
import io.github.m7mdloverrr.quran.data.Reciters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

/** Downloads every verse of one surah for one reciter into [AudioCache]. */
class DownloadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    @OptIn(UnstableApi::class)
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val reciter = Reciters.byId(inputData.getString(KEY_RECITER))
        val surah = inputData.getInt(KEY_SURAH, 0)
        val count = inputData.getInt(KEY_COUNT, 0)
        if (surah !in 1..114 || count <= 0) return@withContext Result.failure()
        val urls = buildList {
            if (surah != 1 && surah != 9) add(reciter.url(1, 1))
            for (a in 1..count) add(reciter.url(surah, a))
        }
        val source = AudioCache.dataSourceFactory(applicationContext).createDataSource()
        var missing = 0
        for ((i, url) in urls.withIndex()) {
            if (isStopped) return@withContext Result.failure()
            try {
                CacheWriter(source, DataSpec(Uri.parse(url)), null, null).cache()
            } catch (e: HttpDataSource.InvalidResponseCodeException) {
                if (e.responseCode == 404) missing++ else return@withContext retryOrFail()
            } catch (e: IOException) {
                return@withContext retryOrFail()
            }
            setProgress(workDataOf(KEY_DONE to i + 1, KEY_TOTAL to urls.size))
        }
        Prefs(applicationContext).toggle(Prefs.Keys.downloaded, "${reciter.id}:$surah", on = true)
        Result.success(workDataOf(KEY_MISSING to missing))
    }

    private fun retryOrFail() = if (runAttemptCount < 3) Result.retry() else Result.failure()

    companion object {
        const val TAG = "recitation-download"
        const val KEY_RECITER = "reciter"
        const val KEY_SURAH = "surah"
        const val KEY_COUNT = "count"
        const val KEY_DONE = "done"
        const val KEY_TOTAL = "total"
        const val KEY_MISSING = "missing"

        fun name(reciterId: String, surah: Int) = "dl:$reciterId:$surah"

        fun enqueue(context: Context, reciterId: String, surah: Int, ayahCount: Int) {
            val request = OneTimeWorkRequestBuilder<DownloadWorker>()
                .setInputData(workDataOf(KEY_RECITER to reciterId, KEY_SURAH to surah, KEY_COUNT to ayahCount))
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .addTag(TAG)
                .addTag(name(reciterId, surah))
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(name(reciterId, surah), ExistingWorkPolicy.KEEP, request)
        }

        fun cancelReciter(context: Context, reciterId: String) {
            val wm = WorkManager.getInstance(context)
            for (s in 1..114) wm.cancelUniqueWork(name(reciterId, s))
        }
    }
}
