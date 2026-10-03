package com.example.quran_app_android.adhan

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.CalculationParameters
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.HighLatitudeRule
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerAdjustments
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

data class AdhanSettings(
    val latitude: Double,
    val longitude: Double,
    val cityName: String = "",
    val calculationMethod: String = "EGYPTIAN",
    val madhab: String = "SHAFI",
    val highLatitudeRule: String = "MIDDLE_OF_THE_NIGHT",
    val timeZoneId: String = "",
    // Manual minute adjustments
    val fajrOffset: Int = 0,
    val sunriseOffset: Int = 0,
    val dhuhrOffset: Int = 0,
    val asrOffset: Int = 0,
    val maghribOffset: Int = 0,
    val ishaOffset: Int = 0,
    // Per-prayer enable toggles
    val fajrEnabled: Boolean = true,
    val dhuhrEnabled: Boolean = true,
    val asrEnabled: Boolean = true,
    val maghribEnabled: Boolean = true,
    val ishaEnabled: Boolean = true,
    // Notification mode: "adhan" (full audio + alert), "notification_only", "silent"
    val fajrMode: String = "adhan",
    val dhuhrMode: String = "adhan",
    val asrMode: String = "adhan",
    val maghribMode: String = "adhan",
    val ishaMode: String = "adhan",
    // Selected audio: "default", "makkah", "madinah", "abdulbasit", "mishary", "alaqsa"
    val adhanSound: String = "default",
    // Sheikh Al-Shaarawy Post-Adhan Du'a
    val playPostAdhanDua: Boolean = true
)

data class ScheduledPrayer(
    val prayerKey: String,   // fajr, dhuhr, asr, maghrib, isha
    val nameAr: String,      // الفجر، الظهر، العصر، المغرب، العشاء
    val timeMillis: Long,
    val dayOffset: Int,      // 0 = today, 1 = tomorrow ... up to 7
    val requestCode: Int,
    val notificationMode: String, // adhan, notification_only, silent
    val sound: String
)

object NativePrayerManager {

    private const val PREFS_NAME = "adhan_native_settings"
    private const val TAG = "NativePrayerManager"

    fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun hasValidLocation(context: Context): Boolean {
        val prefs = getPrefs(context)
        val lat = prefs.getFloat("latitude", 0f).toDouble()
        val lng = prefs.getFloat("longitude", 0f).toDouble()
        return !(lat == 0.0 && lng == 0.0)
    }

    fun getSettings(context: Context): AdhanSettings {
        val prefs = getPrefs(context)
        return AdhanSettings(
            latitude = prefs.getFloat("latitude", 0f).toDouble(),
            longitude = prefs.getFloat("longitude", 0f).toDouble(),
            cityName = prefs.getString("cityName", "") ?: "",
            calculationMethod = prefs.getString("calculationMethod", "EGYPTIAN") ?: "EGYPTIAN",
            madhab = prefs.getString("madhab", "SHAFI") ?: "SHAFI",
            highLatitudeRule = prefs.getString("highLatitudeRule", "MIDDLE_OF_THE_NIGHT") ?: "MIDDLE_OF_THE_NIGHT",
            timeZoneId = prefs.getString("timeZoneId", TimeZone.getDefault().id) ?: TimeZone.getDefault().id,
            fajrOffset = prefs.getInt("fajrOffset", 0),
            sunriseOffset = prefs.getInt("sunriseOffset", 0),
            dhuhrOffset = prefs.getInt("dhuhrOffset", 0),
            asrOffset = prefs.getInt("asrOffset", 0),
            maghribOffset = prefs.getInt("maghribOffset", 0),
            ishaOffset = prefs.getInt("ishaOffset", 0),
            fajrEnabled = prefs.getBoolean("fajrEnabled", true),
            dhuhrEnabled = prefs.getBoolean("dhuhrEnabled", true),
            asrEnabled = prefs.getBoolean("asrEnabled", true),
            maghribEnabled = prefs.getBoolean("maghribEnabled", true),
            ishaEnabled = prefs.getBoolean("ishaEnabled", true),
            fajrMode = prefs.getString("fajrMode", "adhan") ?: "adhan",
            dhuhrMode = prefs.getString("dhuhrMode", "adhan") ?: "adhan",
            asrMode = prefs.getString("asrMode", "adhan") ?: "adhan",
            maghribMode = prefs.getString("maghribMode", "adhan") ?: "adhan",
            ishaMode = prefs.getString("ishaMode", "adhan") ?: "adhan",
            adhanSound = prefs.getString("adhanSound", "default") ?: "default",
            playPostAdhanDua = prefs.getBoolean("playPostAdhanDua", true)
        )
    }

    fun saveSettings(context: Context, settings: AdhanSettings) {
        val prefs = getPrefs(context)
        prefs.edit().apply {
            putFloat("latitude", settings.latitude.toFloat())
            putFloat("longitude", settings.longitude.toFloat())
            putString("cityName", settings.cityName)
            putString("calculationMethod", settings.calculationMethod)
            putString("madhab", settings.madhab)
            putString("highLatitudeRule", settings.highLatitudeRule)
            putString("timeZoneId", settings.timeZoneId)
            putInt("fajrOffset", settings.fajrOffset)
            putInt("sunriseOffset", settings.sunriseOffset)
            putInt("dhuhrOffset", settings.dhuhrOffset)
            putInt("asrOffset", settings.asrOffset)
            putInt("maghribOffset", settings.maghribOffset)
            putInt("ishaOffset", settings.ishaOffset)
            putBoolean("fajrEnabled", settings.fajrEnabled)
            putBoolean("dhuhrEnabled", settings.dhuhrEnabled)
            putBoolean("asrEnabled", settings.asrEnabled)
            putBoolean("maghribEnabled", settings.maghribEnabled)
            putBoolean("ishaEnabled", settings.ishaEnabled)
            putString("fajrMode", settings.fajrMode)
            putString("dhuhrMode", settings.dhuhrMode)
            putString("asrMode", settings.asrMode)
            putString("maghribMode", settings.maghribMode)
            putString("ishaMode", settings.ishaMode)
            putString("adhanSound", settings.adhanSound)
            putBoolean("playPostAdhanDua", settings.playPostAdhanDua)
            apply()
        }
        Log.i(TAG, "Saved settings: lat=${settings.latitude}, lng=${settings.longitude}, method=${settings.calculationMethod}, madhab=${settings.madhab}")
    }

    fun parseCalculationMethod(methodName: String): CalculationMethod {
        return when (methodName.uppercase()) {
            "EGYPTIAN" -> CalculationMethod.EGYPTIAN
            "UMM_AL_QURA", "UMMALQURA" -> CalculationMethod.UMM_AL_QURA
            "MUSLIM_WORLD_LEAGUE", "MWL" -> CalculationMethod.MUSLIM_WORLD_LEAGUE
            "KARACHI" -> CalculationMethod.KARACHI
            "NORTH_AMERICA", "ISNA" -> CalculationMethod.NORTH_AMERICA
            "DUBAI" -> CalculationMethod.DUBAI
            "KUWAIT" -> CalculationMethod.KUWAIT
            "QATAR" -> CalculationMethod.QATAR
            "SINGAPORE" -> CalculationMethod.SINGAPORE
            "TEHRAN", "TURKEY" -> CalculationMethod.MUSLIM_WORLD_LEAGUE
            "MOON_SIGHTING_COMMITTEE" -> CalculationMethod.MOON_SIGHTING_COMMITTEE
            else -> CalculationMethod.EGYPTIAN
        }
    }

    fun parseMadhab(madhabName: String): Madhab {
        return when (madhabName.uppercase()) {
            "HANAFI" -> Madhab.HANAFI
            else -> Madhab.SHAFI
        }
    }

    fun parseHighLatitudeRule(ruleName: String): HighLatitudeRule {
        return when (ruleName.uppercase()) {
            "SEVENTH_OF_THE_NIGHT" -> HighLatitudeRule.SEVENTH_OF_THE_NIGHT
            "TWILIGHT_ANGLE" -> HighLatitudeRule.TWILIGHT_ANGLE
            else -> HighLatitudeRule.MIDDLE_OF_THE_NIGHT
        }
    }

    fun calculatePrayerTimesForDate(
        settings: AdhanSettings,
        year: Int,
        month: Int, // 1..12
        day: Int
    ): PrayerTimes? {
        if (settings.latitude == 0.0 && settings.longitude == 0.0) {
            Log.w(TAG, "Cannot calculate prayer times: lat & lng are 0.0")
            return null
        }

        val coordinates = Coordinates(settings.latitude, settings.longitude)
        val dateComponents = DateComponents(year, month, day)

        val params: CalculationParameters = parseCalculationMethod(settings.calculationMethod).parameters
        params.madhab = parseMadhab(settings.madhab)
        params.highLatitudeRule = parseHighLatitudeRule(settings.highLatitudeRule)
        params.adjustments = PrayerAdjustments(
            settings.fajrOffset,
            settings.sunriseOffset,
            settings.dhuhrOffset,
            settings.asrOffset,
            settings.maghribOffset,
            settings.ishaOffset
        )

        return PrayerTimes(coordinates, dateComponents, params)
    }

    /**
     * Calculates the next 7 days of prayer times (today = day 0 through day 7).
     * Returns ScheduledPrayer objects with prayer details, exact timestamps, and deterministic request codes.
     */
    fun calculateRollingWindow(context: Context, daysCount: Int = 8): List<ScheduledPrayer> {
        val settings = getSettings(context)
        if (!hasValidLocation(context)) {
            Log.w(TAG, "No valid location available to calculate rolling window.")
            return emptyList()
        }

        val tz = if (settings.timeZoneId.isNotEmpty()) {
            try { TimeZone.getTimeZone(settings.timeZoneId) } catch (_: Exception) { TimeZone.getDefault() }
        } else {
            TimeZone.getDefault()
        }

        val calendar = Calendar.getInstance(tz).apply {
            timeInMillis = System.currentTimeMillis()
        }

        val prayerNames = mapOf(
            "fajr" to "الفجر",
            "dhuhr" to "الظهر",
            "asr" to "العصر",
            "maghrib" to "المغرب",
            "isha" to "العشاء"
        )

        val prayerIndices = mapOf(
            "fajr" to 1,
            "dhuhr" to 2,
            "asr" to 3,
            "maghrib" to 4,
            "isha" to 5
        )

        val result = mutableListOf<ScheduledPrayer>()

        for (dayOffset in 0 until daysCount) {
            val dayCal = (calendar.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, dayOffset)
            }
            val year = dayCal.get(Calendar.YEAR)
            val month = dayCal.get(Calendar.MONTH) + 1 // Calendar.MONTH is 0-indexed
            val day = dayCal.get(Calendar.DAY_OF_MONTH)

            val prayerTimes = calculatePrayerTimesForDate(settings, year, month, day) ?: continue

            val prayers = listOf(
                Triple("fajr", prayerTimes.fajr, settings.fajrEnabled to settings.fajrMode),
                Triple("dhuhr", prayerTimes.dhuhr, settings.dhuhrEnabled to settings.dhuhrMode),
                Triple("asr", prayerTimes.asr, settings.asrEnabled to settings.asrMode),
                Triple("maghrib", prayerTimes.maghrib, settings.maghribEnabled to settings.maghribMode),
                Triple("isha", prayerTimes.isha, settings.ishaEnabled to settings.ishaMode)
            )

            for ((key, date, config) in prayers) {
                val (enabled, mode) = config
                if (!enabled || mode == "silent") {
                    continue
                }

                val timeMillis = date.time
                // Request code schema: (dayOffset * 10) + prayerIndex
                // E.g. Day 0 Fajr = 1, Day 0 Isha = 5, Day 1 Fajr = 11, Day 7 Isha = 75
                val prayerIndex = prayerIndices[key] ?: 1
                val requestCode = 20000 + (dayOffset * 10) + prayerIndex

                result.add(
                    ScheduledPrayer(
                        prayerKey = key,
                        nameAr = prayerNames[key] ?: key,
                        timeMillis = timeMillis,
                        dayOffset = dayOffset,
                        requestCode = requestCode,
                        notificationMode = mode,
                        sound = settings.adhanSound
                    )
                )
            }
        }

        return result
    }
}
