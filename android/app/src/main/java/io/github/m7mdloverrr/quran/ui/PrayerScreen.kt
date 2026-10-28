package io.github.m7mdloverrr.quran.ui

import io.github.m7mdloverrr.quran.data.*

import android.Manifest
import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.absoluteOffset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.Canvas
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Explore
import androidx.compose.material.icons.rounded.MyLocation
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import io.github.m7mdloverrr.quran.AppViewModel
import io.github.m7mdloverrr.quran.data.Prefs
import io.github.m7mdloverrr.quran.data.Settings
import io.github.m7mdloverrr.quran.prayer.LocationHelper
import io.github.m7mdloverrr.quran.prayer.PrayerCalc
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.roundToInt

private val arLocale: Locale = Locale.forLanguageTag("ar")

fun prayerTime(d: Date): String = if (Lang.de) SimpleDateFormat("HH:mm", Locale.GERMAN).format(d) else SimpleDateFormat("h:mm a", arLocale).format(d)

class LocationRequest(val request: () -> Unit, val locating: Boolean, val error: String?)

@Composable
fun rememberLocationRequest(vm: AppViewModel): LocationRequest {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var locating by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val locate: () -> Unit = {
        scope.launch {
            locating = true
            error = null
            val loc = LocationHelper.current(ctx)
            if (loc == null) {
                error = TR("تعذّر تحديد موقعك. فعّل خدمة الموقع في الهاتف ثم أعد المحاولة.", "Standort konnte nicht bestimmt werden. Aktiviere die Standortdienste und versuche es erneut.")
            } else {
                vm.saveLocation(loc.latitude, loc.longitude, LocationHelper.cityName(ctx, loc.latitude, loc.longitude))
            }
            locating = false
        }
    }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        if (r.values.any { it }) locate() else error = TR("يلزم إذن الموقع لحساب مواقيت الصلاة واتجاه القبلة.", "Für Gebetszeiten und Qibla-Richtung wird die Standortberechtigung benötigt.")
    }
    return LocationRequest(
        request = {
            if (LocationHelper.granted(ctx)) locate()
            else launcher.launch(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION))
        },
        locating = locating,
        error = error,
    )
}

@Composable
private fun NeedLocation(loc: LocationRequest, text: String) {
    Column(Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(Icons.Rounded.MyLocation, null, Modifier.size(48.dp), tint = MaterialTheme.colorScheme.primary)
        Text(text, textAlign = TextAlign.Center)
        if (loc.locating) CircularProgressIndicator() else Button(onClick = loc.request) { Text(TR("تحديد موقعي", "Meinen Standort bestimmen")) }
        loc.error?.let { Text(it, color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayerScreen(vm: AppViewModel, onBack: () -> Unit, openQibla: () -> Unit) {
    val settings by vm.settings.collectAsStateWithLifecycle()
    val st = settings ?: return Loading()
    val loc = rememberLocationRequest(vm)
    LaunchedEffect(Unit) { if (st.lat == null) loc.request() }
    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text(TR("مواقيت الصلاة", "Gebetszeiten")) },
            navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, TR("رجوع", "Zurück")) } },
            actions = {
                if (loc.locating) CircularProgressIndicator(Modifier.size(24.dp).padding(end = 4.dp), strokeWidth = 2.dp)
                else IconButton(onClick = loc.request) { Icon(Icons.Rounded.MyLocation, TR("تحديث الموقع", "Standort aktualisieren")) }
            },
        )
    }) { pad ->
        Column(Modifier.padding(pad).verticalScroll(rememberScrollState())) {
            val lat = st.lat
            val lon = st.lon
            if (lat == null || lon == null) {
                NeedLocation(loc, TR("نحتاج موقعك لحساب مواقيت الصلاة بدقة. يتم الحساب على هاتفك دون إنترنت.", "Wir brauchen deinen Standort, um die Gebetszeiten genau zu berechnen. Die Berechnung erfolgt offline auf deinem Handy."))
                return@Column
            }
            loc.error?.let { Text(it, Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.error) }
            PrayerTimesCard(st, lat, lon)
            FilledTonalButton(onClick = openQibla, modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
                Icon(Icons.Rounded.Explore, null)
                Spacer(Modifier.size(8.dp))
                Text(TR("اتجاه القبلة", "Qibla-Richtung"))
            }
            Section(TR("طريقة الحساب", "Berechnungsmethode")) {
                PrayerCalc.methods.forEachIndexed { i, (_, name) ->
                    Row(
                        Modifier.fillMaxWidth().clickable { vm.setPrayerPref(Prefs.Keys.prayerMethod, i) },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(st.prayerMethod == i, { vm.setPrayerPref(Prefs.Keys.prayerMethod, i) })
                        Text(name)
                    }
                }
            }
            Section(TR("صلاة العصر", "Asr-Gebet")) {
                val opts = listOf(TR("الجمهور (شافعي، مالكي، حنبلي)", "Mehrheit (Schafii, Maliki, Hanbali)"), TR("الحنفي", "Hanafi"))
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    opts.forEachIndexed { i, l ->
                        SegmentedButton(st.madhab == i, { vm.setPrayerPref(Prefs.Keys.madhab, i) }, SegmentedButtonDefaults.itemShape(i, opts.size)) {
                            Text(l, fontSize = 12.sp, maxLines = 1)
                        }
                    }
                }
            }
            Section(TR("التنبيهات", "Erinnerungen")) {
                SwitchRow(TR("تنبيه عند دخول وقت كل صلاة", "Erinnerung zu jeder Gebetszeit"), st.prayerAlerts) { vm.setPrayerPref(Prefs.Keys.prayerAlerts, it) }
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun PrayerTimesCard(st: Settings, lat: Double, lon: Double) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000)
            now = System.currentTimeMillis()
        }
    }
    val day = remember(now / 60_000) { Calendar.getInstance().get(Calendar.DAY_OF_YEAR) }
    val times = remember(lat, lon, st.prayerMethod, st.madhab, day) { PrayerCalc.times(lat, lon, st.prayerMethod, st.madhab) }
    val minute = now / 60_000
    val (next, nextTime) = remember(lat, lon, st.prayerMethod, st.madhab, minute) { PrayerCalc.next(lat, lon, st.prayerMethod, st.madhab, Date(now)) }
    val left = ((nextTime.time - now) / 1000).coerceAtLeast(0)
    Box(
        Modifier.padding(16.dp).fillMaxWidth().clip(RoundedCornerShape(24.dp))
            .background(Brush.linearGradient(listOf(DarkGreen, Emerald))).padding(20.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(st.city.ifBlank { TR("موقعي", "Mein Standort") }, color = Color.White.copy(alpha = 0.8f), style = MaterialTheme.typography.labelLarge)
            Text(TR("صلاة ${PrayerCalc.names[next]} • ${prayerTime(nextTime)}", "${PrayerCalc.names[next]} • ${prayerTime(nextTime)}"), color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(
                TR("متبقٍ ", "noch ") + String.format(arLocale, "%02d:%02d:%02d", left / 3600, left / 60 % 60, left % 60),
                color = Color.White.copy(alpha = 0.9f), fontSize = 18.sp,
            )
        }
    }
    Surface(Modifier.padding(horizontal = 16.dp).fillMaxWidth(), shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.surfaceContainer) {
        Column(Modifier.padding(vertical = 6.dp)) {
            val nextIsToday = times[next] == nextTime
            times.forEachIndexed { i, t ->
                val active = nextIsToday && i == next
                Row(
                    Modifier.fillMaxWidth()
                        .background(if (active) MaterialTheme.colorScheme.primaryContainer else Color.Transparent)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(PrayerCalc.names[i], fontWeight = if (active) FontWeight.Bold else null, color = if (i == 1) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface)
                    Text(prayerTime(t), fontWeight = if (active) FontWeight.Bold else null)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QiblaScreen(vm: AppViewModel, onBack: () -> Unit) {
    val settings by vm.settings.collectAsStateWithLifecycle()
    val st = settings ?: return Loading()
    val loc = rememberLocationRequest(vm)
    Scaffold(containerColor = Color.Transparent, topBar = {
        TopAppBar(
            title = { Text(TR("اتجاه القبلة", "Qibla-Richtung")) },
            navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Rounded.ArrowBack, TR("رجوع", "Zurück")) } },
        )
    }) { pad ->
        Box(Modifier.padding(pad).fillMaxSize()) {
            val lat = st.lat
            val lon = st.lon
            if (lat == null || lon == null) NeedLocation(loc, TR("نحتاج موقعك لتحديد اتجاه القبلة.", "Wir brauchen deinen Standort, um die Qibla-Richtung zu bestimmen."))
            else Compass(LocalContext.current, lat, lon, st.city)
        }
    }
}

@Composable
private fun Compass(ctx: Context, lat: Double, lon: Double, city: String) {
    val qibla = remember(lat, lon) { PrayerCalc.qibla(lat, lon).toFloat() }
    var heading by remember { mutableFloatStateOf(0f) }
    var accuracy by remember { mutableIntStateOf(SensorManager.SENSOR_STATUS_ACCURACY_HIGH) }
    var available by remember { mutableStateOf(true) }
    DisposableEffect(lat, lon) {
        val sm = ctx.getSystemService(SensorManager::class.java)
        val sensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (sensor == null) {
            available = false
            return@DisposableEffect onDispose {}
        }
        val decl = GeomagneticField(lat.toFloat(), lon.toFloat(), 0f, System.currentTimeMillis()).declination
        val rot = FloatArray(9)
        val ori = FloatArray(3)
        var first = true
        val listener = object : SensorEventListener {
            override fun onSensorChanged(e: SensorEvent) {
                SensorManager.getRotationMatrixFromVector(rot, e.values)
                SensorManager.getOrientation(rot, ori)
                val az = (Math.toDegrees(ori[0].toDouble()).toFloat() + decl + 360f) % 360f
                heading = if (first) az else {
                    val delta = ((az - heading + 540f) % 360f) - 180f
                    (heading + delta * 0.15f + 360f) % 360f
                }
                first = false
            }
            override fun onAccuracyChanged(s: Sensor, a: Int) { accuracy = a }
        }
        sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(listener) }
    }
    val diff = ((qibla - heading + 540f) % 360f) - 180f
    val facing = abs(diff) < 4f
    val primary = MaterialTheme.colorScheme.primary
    val outline = MaterialTheme.colorScheme.outline
    val onSurface = MaterialTheme.colorScheme.onSurface
    Column(Modifier.fillMaxSize().padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(city.ifBlank { TR("موقعي", "Mein Standort") }, style = MaterialTheme.typography.titleMedium)
        Text(TR("القبلة على بعد ${qibla.roundToInt()}° من الشمال", "Qibla: ${qibla.roundToInt()}° von Norden"), color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (!available) {
            Text(TR("لا يحتوي هاتفك على مستشعر بوصلة. اتجاه القبلة ${qibla.roundToInt()}° من الشمال الحقيقي.", "Dein Handy hat keinen Kompasssensor. Qibla-Richtung: ${qibla.roundToInt()}° von geografisch Nord."), color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center)
            return@Column
        }
        Box(Modifier.size(300.dp), contentAlignment = Alignment.Center) {
            Box(Modifier.fillMaxSize().graphicsLayer { rotationZ = -heading }) {
                Canvas(Modifier.fillMaxSize()) {
                    val r = size.minDimension / 2
                    drawCircle(outline, r - 2.dp.toPx(), style = Stroke(2.dp.toPx()))
                    for (deg in 0 until 360 step 15) {
                        rotate(deg.toFloat()) {
                            val long = deg % 90 == 0
                            drawLine(
                                if (deg == 0) Color(0xFFD64545) else outline,
                                Offset(center.x, center.y - r + 6.dp.toPx()),
                                Offset(center.x, center.y - r + (if (long) 22f else 12f).dp.toPx()),
                                strokeWidth = (if (long) 3f else 1.5f).dp.toPx(),
                            )
                        }
                    }
                }
                listOf(TR("ش", "N") to 0.0, TR("ق", "O") to 90.0, TR("ج", "S") to 180.0, TR("غ", "W") to 270.0).forEach { (l, a) ->
                    val rad = Math.toRadians(a)
                    Text(
                        l,
                        Modifier.align(Alignment.Center)
                            .absoluteOffset(x = (sin(rad) * 108).dp, y = (-cos(rad) * 108).dp)
                            .graphicsLayer { rotationZ = heading },
                        color = if (a == 0.0) Color(0xFFD64545) else onSurface, fontWeight = FontWeight.Bold, fontSize = 18.sp,
                    )
                }
                Canvas(Modifier.fillMaxSize().graphicsLayer { rotationZ = qibla }) {
                    val r = size.minDimension / 2
                    val tip = center.y - r + 56.dp.toPx()
                    val p = Path().apply {
                        moveTo(center.x, tip)
                        lineTo(center.x - 14.dp.toPx(), center.y)
                        lineTo(center.x + 14.dp.toPx(), center.y)
                        close()
                    }
                    drawPath(p, if (facing) primary else primary.copy(alpha = 0.75f))
                    val k = 26.dp.toPx()
                    drawRect(Color(0xFF111111), Offset(center.x - k / 2, tip - k - 6.dp.toPx()), Size(k, k))
                    drawRect(Color(0xFFD4AF37), Offset(center.x - k / 2, tip - k - 6.dp.toPx() + k * 0.25f), Size(k, k * 0.14f))
                    drawCircle(primary, 8.dp.toPx(), center)
                }
            }
        }
        Text(
            if (facing) TR("أنت متجه نحو القبلة", "Du bist zur Qibla ausgerichtet") else if (diff > 0) TR("استدر يمينًا ${abs(diff).roundToInt()}°", "Dreh dich ${abs(diff).roundToInt()}° nach rechts") else TR("استدر يسارًا ${abs(diff).roundToInt()}°", "Dreh dich ${abs(diff).roundToInt()}° nach links"),
            color = if (facing) primary else onSurface, fontSize = 20.sp, fontWeight = FontWeight.Bold,
        )
        if (accuracy <= SensorManager.SENSOR_STATUS_ACCURACY_LOW) {
            Text(TR("دقة البوصلة منخفضة: حرّك الهاتف على شكل الرقم 8 للمعايرة، وابتعد عن المعادن والمغناطيس.", "Geringe Kompassgenauigkeit: Handy in Form einer 8 bewegen und von Metall und Magneten fernhalten."), color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center)
        } else {
            Text(TR("ضع الهاتف بشكل مسطح وبعيدًا عن المعادن.", "Halte das Handy flach und fern von Metall."), color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        }
    }
}
