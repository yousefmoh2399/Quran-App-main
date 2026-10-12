package com.example.quran_app_android.adhan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object LockScreenBannerManager {

    private const val CHANNEL_ID = "prayer_banner_channel_v2"
    private const val NOTIFICATION_ID = 99901
    private const val TAG = "LockScreenBannerManager"

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "شريط مواقيت الصلاة وشاشة القفل",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "عرض مستمر وأنيق لمواقيت الصلاة، الورد القرآني، والأذكار على شاشة القفل"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    setSound(null, null)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    fun updateBanner(context: Context, data: Map<String, Any?>) {
        try {
            ensureChannel(context)

            val isEnabled = (data["isEnabled"] as? Boolean) ?: true
            if (!isEnabled) {
                cancelBanner(context)
                return
            }

            val cityName = (data["cityName"] as? String) ?: "القاهرة"
            val hijriLine = (data["hijriLine"] as? String) ?: ""
            val nextPrayerName = (data["nextPrayerName"] as? String) ?: ""
            val nextPrayerTime = (data["nextPrayerTimeStr"] as? String) ?: ""
            val nextPrayerCountdown = (data["nextPrayerCountdown"] as? String) ?: ""
            val fajrTime = (data["fajr"] as? String) ?: "--:--"
            val dhuhrTime = (data["dhuhr"] as? String) ?: "--:--"
            val asrTime = (data["asr"] as? String) ?: "--:--"
            val maghribTime = (data["maghrib"] as? String) ?: "--:--"
            val ishaTime = (data["isha"] as? String) ?: "--:--"
            val actualNext = (data["actualNextPrayer"] as? String) ?: ""
            val wirdLine = (data["wirdLine"] as? String) ?: ""
            val zikrLine = (data["zikrLine"] as? String) ?: ""

            val showNextPrayer = (data["showNextPrayer"] as? Boolean) ?: true
            val showAllPrayers = (data["showAllPrayers"] as? Boolean) ?: true
            val showWirdProgress = (data["showWirdProgress"] as? Boolean) ?: true
            val showDailyZikr = (data["showDailyZikr"] as? Boolean) ?: true
            val showQuickActions = (data["showQuickActions"] as? Boolean) ?: true

            val packageName = context.packageName

            // 1. Collapsed RemoteViews
            val collapsedViews = RemoteViews(packageName, R.layout.notification_prayer_banner_collapsed)
            val collapsedTitle = if (nextPrayerName.isNotEmpty()) {
                "الصلاة القادمة: $nextPrayerName $nextPrayerTime"
            } else {
                "تطبيق تقرّب"
            }
            collapsedViews.setTextViewText(R.id.banner_collapsed_title, collapsedTitle)
            collapsedViews.setTextViewText(R.id.banner_collapsed_subtitle, "تقرّب • $cityName")
            if (nextPrayerCountdown.isNotEmpty()) {
                collapsedViews.setTextViewText(R.id.banner_collapsed_countdown, nextPrayerCountdown)
                collapsedViews.setViewVisibility(R.id.banner_collapsed_countdown, View.VISIBLE)
            } else {
                collapsedViews.setViewVisibility(R.id.banner_collapsed_countdown, View.GONE)
            }

            // 2. Expanded RemoteViews
            val expandedViews = RemoteViews(packageName, R.layout.notification_prayer_banner_expanded)
            expandedViews.setTextViewText(R.id.banner_expanded_city, cityName)
            if (hijriLine.isNotEmpty()) {
                expandedViews.setTextViewText(R.id.banner_expanded_hijri, " • $hijriLine")
                expandedViews.setViewVisibility(R.id.banner_expanded_hijri, View.VISIBLE)
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_hijri, View.GONE)
            }

            // Next Prayer highlight box
            if (showNextPrayer && nextPrayerName.isNotEmpty()) {
                expandedViews.setViewVisibility(R.id.banner_expanded_next_box, View.VISIBLE)
                expandedViews.setTextViewText(
                    R.id.banner_expanded_next_label,
                    "🕌 الصلاة القادمة: $nextPrayerName $nextPrayerTime"
                )
                expandedViews.setTextViewText(
                    R.id.banner_expanded_next_countdown,
                    nextPrayerCountdown
                )
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_next_box, View.GONE)
            }

            // 5 Prayers table
            if (showAllPrayers) {
                expandedViews.setViewVisibility(R.id.banner_expanded_prayers_row, View.VISIBLE)
                expandedViews.setTextViewText(R.id.banner_time_fajr, fajrTime)
                expandedViews.setTextViewText(R.id.banner_time_dhuhr, dhuhrTime)
                expandedViews.setTextViewText(R.id.banner_time_asr, asrTime)
                expandedViews.setTextViewText(R.id.banner_time_maghrib, maghribTime)
                expandedViews.setTextViewText(R.id.banner_time_isha, ishaTime)

                val prayerConfigs = listOf(
                    Triple("fajr", R.id.banner_box_fajr, R.id.banner_name_fajr to R.id.banner_time_fajr),
                    Triple("dhuhr", R.id.banner_box_dhuhr, R.id.banner_name_dhuhr to R.id.banner_time_dhuhr),
                    Triple("asr", R.id.banner_box_asr, R.id.banner_name_asr to R.id.banner_time_asr),
                    Triple("maghrib", R.id.banner_box_maghrib, R.id.banner_name_maghrib to R.id.banner_time_maghrib),
                    Triple("isha", R.id.banner_box_isha, R.id.banner_name_isha to R.id.banner_time_isha)
                )

                for ((key, boxId, textIds) in prayerConfigs) {
                    val isNext = key.equals(actualNext, ignoreCase = true)
                    if (isNext) {
                        expandedViews.setInt(boxId, "setBackgroundResource", R.drawable.banner_prayer_active_bg)
                        expandedViews.setTextColor(textIds.first, 0xFFE2BE78.toInt())
                        expandedViews.setTextColor(textIds.second, 0xFFFFFFFF.toInt())
                    } else {
                        expandedViews.setInt(boxId, "setBackgroundResource", R.drawable.banner_prayer_normal_bg)
                        expandedViews.setTextColor(textIds.first, 0xFFA0B8AD.toInt())
                        expandedViews.setTextColor(textIds.second, 0xFFFFFFFF.toInt())
                    }
                }
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_prayers_row, View.GONE)
            }

            // Wird Row
            if (showWirdProgress && wirdLine.isNotEmpty()) {
                expandedViews.setViewVisibility(R.id.banner_expanded_wird, View.VISIBLE)
                expandedViews.setTextViewText(R.id.banner_expanded_wird, "📖 الورد: $wirdLine")
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_wird, View.GONE)
            }

            // Dhikr Row
            if (showDailyZikr && zikrLine.isNotEmpty()) {
                expandedViews.setViewVisibility(R.id.banner_expanded_dhikr, View.VISIBLE)
                expandedViews.setTextViewText(R.id.banner_expanded_dhikr, "📿 ذكر الوقت: «$zikrLine»")
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_dhikr, View.GONE)
            }

            // Action Buttons
            if (showQuickActions) {
                expandedViews.setViewVisibility(R.id.banner_expanded_actions_row, View.VISIBLE)
                expandedViews.setOnClickPendingIntent(
                    R.id.banner_btn_wird,
                    createNavigationPendingIntent(context, "quran", 6001)
                )
                expandedViews.setOnClickPendingIntent(
                    R.id.banner_btn_azkar,
                    createNavigationPendingIntent(context, "azkar", 6002)
                )
                expandedViews.setOnClickPendingIntent(
                    R.id.banner_btn_prayers,
                    createNavigationPendingIntent(context, "prayer_times", 6003)
                )
            } else {
                expandedViews.setViewVisibility(R.id.banner_expanded_actions_row, View.GONE)
            }

            val openAppPendingIntent = createOpenAppPendingIntent(context)

            // Build ongoing luxury notification
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_crescent_moon)
                .setColor(0xFF0F5C4A.toInt())
                .setCustomContentView(collapsedViews)
                .setCustomBigContentView(expandedViews)
                .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setContentIntent(openAppPendingIntent)

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, builder.build())

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error updating lock screen banner: ${e.message}", e)
        }
    }

    fun updateWithNativeTimes(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.lockscreen_banner_enabled", true)
            if (!isEnabled) {
                cancelBanner(context)
                return
            }

            if (!NativePrayerManager.hasValidLocation(context)) return

            val settings = NativePrayerManager.getSettings(context)
            val coords = Coordinates(settings.latitude, settings.longitude)
            val params = when (settings.calculationMethod.uppercase()) {
                "UMM_AL_QURA", "UMMALQURA" -> CalculationMethod.UMM_AL_QURA.parameters
                "MUSLIM_WORLD_LEAGUE", "MWL" -> CalculationMethod.MUSLIM_WORLD_LEAGUE.parameters
                "KARACHI" -> CalculationMethod.KARACHI.parameters
                "NORTH_AMERICA", "ISNA" -> CalculationMethod.NORTH_AMERICA.parameters
                "DUBAI" -> CalculationMethod.DUBAI.parameters
                "KUWAIT" -> CalculationMethod.KUWAIT.parameters
                "QATAR" -> CalculationMethod.QATAR.parameters
                "SINGAPORE" -> CalculationMethod.SINGAPORE.parameters
                "MOON_SIGHTING_COMMITTEE" -> CalculationMethod.MOON_SIGHTING_COMMITTEE.parameters
                else -> CalculationMethod.EGYPTIAN.parameters
            }.apply {
                madhab = if (settings.madhab.uppercase() == "HANAFI") Madhab.HANAFI else Madhab.SHAFI
                adjustments.fajr = settings.fajrOffset
                adjustments.sunrise = settings.sunriseOffset
                adjustments.dhuhr = settings.dhuhrOffset
                adjustments.asr = settings.asrOffset
                adjustments.maghrib = settings.maghribOffset
                adjustments.isha = settings.ishaOffset
            }

            val today = DateComponents.from(Date())
            val pt = PrayerTimes(coords, today, params) ?: return

            val timeFormat = SimpleDateFormat("hh:mm a", Locale("ar"))
            fun fTime(d: Date?): String = if (d != null) timeFormat.format(d) else "--:--"

            val now = Date()
            val nextPrayer = pt.nextPrayer()
            val nextName: String
            val nextTime: String
            val actualNextKey: String

            when (nextPrayer) {
                com.batoulapps.adhan.Prayer.FAJR -> {
                    nextName = "الفجر"; nextTime = fTime(pt.fajr); actualNextKey = "fajr"
                }
                com.batoulapps.adhan.Prayer.SUNRISE -> {
                    nextName = "الشروق"; nextTime = fTime(pt.sunrise); actualNextKey = "sunrise"
                }
                com.batoulapps.adhan.Prayer.DHUHR -> {
                    nextName = "الظهر"; nextTime = fTime(pt.dhuhr); actualNextKey = "dhuhr"
                }
                com.batoulapps.adhan.Prayer.ASR -> {
                    nextName = "العصر"; nextTime = fTime(pt.asr); actualNextKey = "asr"
                }
                com.batoulapps.adhan.Prayer.MAGHRIB -> {
                    nextName = "المغرب"; nextTime = fTime(pt.maghrib); actualNextKey = "maghrib"
                }
                com.batoulapps.adhan.Prayer.ISHA -> {
                    nextName = "العشاء"; nextTime = fTime(pt.isha); actualNextKey = "isha"
                }
                else -> {
                    nextName = "الفجر"; nextTime = fTime(pt.fajr); actualNextKey = "fajr"
                }
            }

            val nextDate = pt.timeForPrayer(nextPrayer) ?: pt.fajr
            val diffSec = (nextDate.time - now.time) / 1000
            val countdownStr = if (diffSec <= 0) {
                "الآن"
            } else {
                val h = diffSec / 3600
                val m = (diffSec % 3600) / 60
                if (h > 0) "متبقي $h س و $m د" else "متبقي $m د"
            }

            val payload = mapOf<String, Any?>(
                "isEnabled" to isEnabled,
                "cityName" to if (settings.cityName.isNotEmpty()) settings.cityName else "القاهرة",
                "nextPrayerName" to nextName,
                "nextPrayerTimeStr" to nextTime,
                "nextPrayerCountdown" to countdownStr,
                "fajr" to fTime(pt.fajr),
                "dhuhr" to fTime(pt.dhuhr),
                "asr" to fTime(pt.asr),
                "maghrib" to fTime(pt.maghrib),
                "isha" to fTime(pt.isha),
                "actualNextPrayer" to actualNextKey,
                "showNextPrayer" to prefs.getBoolean("flutter.lockscreen_show_next_prayer", true),
                "showAllPrayers" to prefs.getBoolean("flutter.lockscreen_show_all_prayers", true),
                "showWirdProgress" to prefs.getBoolean("flutter.lockscreen_show_wird", true),
                "showDailyZikr" to prefs.getBoolean("flutter.lockscreen_show_zikr", true),
                "showQuickActions" to prefs.getBoolean("flutter.lockscreen_show_actions", true),
                "wirdLine" to (prefs.getString("flutter.mushaf_last_wird_line", "") ?: ""),
                "zikrLine" to "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ"
            )

            updateBanner(context, payload)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error in updateWithNativeTimes: ${e.message}", e)
        }
    }

    fun cancelBanner(context: Context) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(NOTIFICATION_ID)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error canceling lock screen banner: ${e.message}", e)
        }
    }

    private fun createOpenAppPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(context, 6000, intent, flags)
    }

    private fun createNavigationPendingIntent(context: Context, targetScreen: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("target_screen", targetScreen)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
