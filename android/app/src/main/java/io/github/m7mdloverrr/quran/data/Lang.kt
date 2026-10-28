package io.github.m7mdloverrr.quran.data

import android.content.Context
import android.content.Intent

object Lang {
    var de = false
        private set

    fun init(ctx: Context) {
        de = ctx.getSharedPreferences("ui", Context.MODE_PRIVATE).getBoolean("de", false)
    }

    fun switch(ctx: Context, german: Boolean) {
        ctx.getSharedPreferences("ui", Context.MODE_PRIVATE).edit().putBoolean("de", german).commit()
        val i = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: return
        ctx.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
        Runtime.getRuntime().exit(0)
    }
}

fun TR(ar: String, de: String) = if (Lang.de) de else ar

val SurahNamesDe = listOf(
    "Die Eröffnung",
    "Die Kuh",
    "Die Sippe Imrans",
    "Die Frauen",
    "Der Tisch",
    "Das Vieh",
    "Die Höhen",
    "Die Beute",
    "Die Reue",
    "Yunus",
    "Hud",
    "Yusuf",
    "Der Donner",
    "Ibrahim",
    "Al-Hidschr",
    "Die Bienen",
    "Die Nachtreise",
    "Die Höhle",
    "Maryam",
    "Ta-Ha",
    "Die Propheten",
    "Die Pilgerfahrt",
    "Die Gläubigen",
    "Das Licht",
    "Die Unterscheidung",
    "Die Dichter",
    "Die Ameisen",
    "Die Geschichte",
    "Die Spinne",
    "Die Römer",
    "Luqman",
    "Die Niederwerfung",
    "Die Gruppierungen",
    "Saba",
    "Der Erschaffer",
    "Ya-Sin",
    "Die sich Reihenden",
    "Sad",
    "Die Scharen",
    "Der Vergebende",
    "Ausführlich dargelegt",
    "Die Beratung",
    "Der Goldprunk",
    "Der Rauch",
    "Die Kniende",
    "Die Sanddünen",
    "Muhammad",
    "Der Sieg",
    "Die Gemächer",
    "Qaf",
    "Die Aufwirbelnden",
    "Der Berg",
    "Der Stern",
    "Der Mond",
    "Der Allerbarmer",
    "Das eintreffende Ereignis",
    "Das Eisen",
    "Der Streit",
    "Die Versammlung",
    "Die Geprüfte",
    "Die Reihe",
    "Der Freitag",
    "Die Heuchler",
    "Die gegenseitige Übervorteilung",
    "Die Scheidung",
    "Das Verbieten",
    "Die Herrschaft",
    "Das Schreibrohr",
    "Die fällig Werdende",
    "Die Himmelsleiter",
    "Nuh",
    "Die Dschinn",
    "Der Eingehüllte",
    "Der Zugedeckte",
    "Die Auferstehung",
    "Der Mensch",
    "Die Entsandten",
    "Die Kunde",
    "Die Entreißenden",
    "Er runzelte die Stirn",
    "Das Einrollen",
    "Das Zerbrechen",
    "Die das Maß Kürzenden",
    "Das Zerreißen",
    "Die Türme",
    "Der Pochende",
    "Der Höchste",
    "Die Überdeckende",
    "Die Morgendämmerung",
    "Die Ortschaft",
    "Die Sonne",
    "Die Nacht",
    "Die Morgenhelle",
    "Das Auftun",
    "Die Feige",
    "Das Anhaftende",
    "Die Bestimmung",
    "Der klare Beweis",
    "Das Beben",
    "Die Rennenden",
    "Das Verhängnis",
    "Die Vermehrung",
    "Das Zeitalter",
    "Der Stichler",
    "Der Elefant",
    "Die Quraisch",
    "Die Hilfeleistung",
    "Die Fülle",
    "Die Ungläubigen",
    "Die Hilfe",
    "Die Palmfasern",
    "Die Aufrichtigkeit",
    "Das Frühlicht",
    "Die Menschen",
)

val Surah.title: String get() = if (Lang.de) SurahNamesDe[number - 1] else name
val Reciter.label: String get() = if (Lang.de) nameEn else nameAr
