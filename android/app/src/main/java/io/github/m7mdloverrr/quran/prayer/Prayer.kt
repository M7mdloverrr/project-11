package io.github.m7mdloverrr.quran.prayer

import io.github.m7mdloverrr.quran.data.*

import android.Manifest
import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.HighLatitudeRule
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.Qibla
import com.batoulapps.adhan.data.DateComponents
import io.github.m7mdloverrr.quran.MainActivity
import io.github.m7mdloverrr.quran.R
import io.github.m7mdloverrr.quran.data.Prefs
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Date
import java.util.Locale
import kotlin.coroutines.resume
import kotlin.math.abs

object PrayerCalc {
    val methods = listOf(
        CalculationMethod.MUSLIM_WORLD_LEAGUE to TR("رابطة العالم الإسلامي", "Muslimische Weltliga"),
        CalculationMethod.UMM_AL_QURA to TR("أم القرى (مكة المكرمة)", "Umm al-Qura (Mekka)"),
        CalculationMethod.EGYPTIAN to TR("الهيئة المصرية العامة للمساحة", "Ägyptische Vermessungsbehörde"),
        CalculationMethod.KARACHI to TR("جامعة العلوم الإسلامية بكراتشي", "Universität für Islamwissenschaften, Karatschi"),
        CalculationMethod.DUBAI to TR("دبي", "Dubai"),
        CalculationMethod.KUWAIT to TR("الكويت", "Kuwait"),
        CalculationMethod.QATAR to TR("قطر", "Katar"),
        CalculationMethod.SINGAPORE to TR("سنغافورة", "Singapur"),
        CalculationMethod.NORTH_AMERICA to TR("أمريكا الشمالية (ISNA)", "Nordamerika (ISNA)"),
        CalculationMethod.MOON_SIGHTING_COMMITTEE to TR("لجنة رؤية الهلال", "Mondsichtungskomitee"),
    )
    val names = listOf(TR("الفجر", "Fadschr"), TR("الشروق", "Sonnenaufgang"), TR("الظهر", "Dhuhr"), TR("العصر", "Asr"), TR("المغرب", "Maghrib"), TR("العشاء", "Ischa"))

    fun times(lat: Double, lon: Double, method: Int, madhab: Int, day: Date = Date()): List<Date> {
        val p = methods[method.coerceIn(0, methods.lastIndex)].first.parameters
        p.madhab = if (madhab == 1) Madhab.HANAFI else Madhab.SHAFI
        if (abs(lat) > 48) p.highLatitudeRule = HighLatitudeRule.SEVENTH_OF_THE_NIGHT
        val t = PrayerTimes(Coordinates(lat, lon), DateComponents.from(day), p)
        return listOf(t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha)
    }

    /** Next obligatory prayer (sunrise excluded) as index into [names] and its time. */
    fun next(lat: Double, lon: Double, method: Int, madhab: Int, now: Date = Date()): Pair<Int, Date> {
        for (d in 0..1) {
            times(lat, lon, method, madhab, Date(now.time + d * 86_400_000L)).forEachIndexed { i, t ->
                if (i != 1 && t.after(now)) return i to t
            }
        }
        return 0 to times(lat, lon, method, madhab, Date(now.time + 2 * 86_400_000L))[0]
    }

    fun qibla(lat: Double, lon: Double) = Qibla(Coordinates(lat, lon)).direction
}

object PrayerAlarms {
    const val ACTION = "io.github.m7mdloverrr.quran.PRAYER"
    private const val CHANNEL = "prayer_times"

    suspend fun schedule(ctx: Context, after: Long = System.currentTimeMillis() + 30_000) {
        val s = Prefs(ctx).settings.first()
        val am = ctx.getSystemService(AlarmManager::class.java)
        val intent = Intent(ctx, PrayerReceiver::class.java).setAction(ACTION)
        val lat = s.lat
        val lon = s.lon
        if (!s.prayerAlerts || lat == null || lon == null) {
            am.cancel(PendingIntent.getBroadcast(ctx, 1, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            return
        }
        val (i, t) = PrayerCalc.next(lat, lon, s.prayerMethod, s.madhab, Date(after))
        val pi = PendingIntent.getBroadcast(ctx, 1, intent.putExtra("prayer", i), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        if (Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, t.time, pi)
        } else {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, t.time, pi)
        }
    }

    fun notify(ctx: Context, prayer: Int, city: String) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, TR("مواقيت الصلاة", "Gebetszeiten"), NotificationManager.IMPORTANCE_HIGH))
        if (Build.VERSION.SDK_INT >= 33 &&
            ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val open = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java).putExtra("open", "prayer"),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_crescent)
            .setContentTitle(TR("حان الآن موعد صلاة ${PrayerCalc.names[prayer]}", "Jetzt ist Gebetszeit: ${PrayerCalc.names[prayer]}"))
            .setContentText(city.ifBlank { TR("مواقيت الصلاة", "Gebetszeiten") })
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        nm.notify(100 + prayer, n)
    }
}

class PrayerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ctx = context.applicationContext
        Lang.init(ctx)
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                if (intent.action == PrayerAlarms.ACTION) {
                    val s = Prefs(ctx).settings.first()
                    if (s.prayerAlerts) PrayerAlarms.notify(ctx, intent.getIntExtra("prayer", 0), s.city)
                }
                PrayerAlarms.schedule(ctx)
            } finally {
                pending.finish()
            }
        }
    }
}

object LocationHelper {
    fun granted(ctx: Context) =
        ctx.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ctx.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    @SuppressLint("MissingPermission")
    suspend fun current(ctx: Context): Location? {
        if (!granted(ctx)) return null
        val lm = ctx.getSystemService(LocationManager::class.java)
        val providers = lm.getProviders(true)
        val last = providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }.maxByOrNull { it.time }
        if (last != null && System.currentTimeMillis() - last.time < 30 * 60_000L) return last
        val candidates = buildList {
            if (Build.VERSION.SDK_INT >= 31) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
        }.filter { it in providers }
        if (candidates.isEmpty()) return last
        val fresh = withTimeoutOrNull(25_000) {
            suspendCancellableCoroutine<Location?> { c ->
                var pending = candidates.size
                val done: (Location?) -> Unit = { l ->
                    pending--
                    if (c.isActive && (l != null || pending == 0)) c.resume(l)
                }
                val listeners = mutableListOf<LocationListener>()
                candidates.forEach { provider ->
                    if (Build.VERSION.SDK_INT >= 30) {
                        lm.getCurrentLocation(provider, null, ctx.mainExecutor) { done(it) }
                    } else {
                        val l = object : LocationListener {
                            override fun onLocationChanged(location: Location) = done(location)
                            @Deprecated("API 29") override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                            override fun onProviderEnabled(provider: String) {}
                            override fun onProviderDisabled(provider: String) {}
                        }
                        listeners += l
                        @Suppress("DEPRECATION")
                        lm.requestSingleUpdate(provider, l, Looper.getMainLooper())
                    }
                }
                c.invokeOnCancellation { listeners.forEach { lm.removeUpdates(it) } }
            }
        }
        return fresh ?: last
    }

    suspend fun cityName(ctx: Context, lat: Double, lon: Double): String = withContext(Dispatchers.IO) {
        runCatching {
            @Suppress("DEPRECATION")
            Geocoder(ctx, Locale.forLanguageTag(TR("ar", "de"))).getFromLocation(lat, lon, 1)?.firstOrNull()?.let {
                it.locality ?: it.subAdminArea ?: it.adminArea
            }
        }.getOrNull() ?: ""
    }
}
