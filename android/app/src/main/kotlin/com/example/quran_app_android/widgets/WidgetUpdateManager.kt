package com.example.quran_app_android.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.R
import com.example.quran_app_android.adhan.NativePrayerManager
import com.example.quran_app_android.adhan.ScheduledPrayer
import com.example.quran_app_android.azkar.AzkarDataRepository
import com.example.quran_app_android.azkar.AzkarItem
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

object WidgetUpdateManager {
    private const val TAG = "WidgetUpdateManager"
    private const val PREFS_NAME = "azkar_widget_prefs"
    private const val KEY_MANUAL_OFFSET = "manual_widget_offset"

    const val ACTION_NEXT_DHIKR = "com.example.quran_app_android.ACTION_NEXT_DHIKR"
    const val ACTION_PERIODIC_UPDATE = "com.example.quran_app_android.ACTION_PERIODIC_UPDATE"
    const val REQUEST_CODE_PERIODIC_WIDGET = 50001
    const val REQUEST_CODE_NEXT_DHIKR = 50002

    fun getManualOffset(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_MANUAL_OFFSET, 0)
    }

    fun incrementManualOffset(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val current = prefs.getInt(KEY_MANUAL_OFFSET, 0)
        prefs.edit().putInt(KEY_MANUAL_OFFSET, current + 1).apply()
        Log.i(TAG, "Manual dhikr offset incremented to ${current + 1}")
    }

    /**
     * Updates all active widgets on the home screen.
     */
    fun updateAll(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val dhikr = AzkarDataRepository.getDeterministic(
                context,
                timeMillis = System.currentTimeMillis(),
                manualOffset = getManualOffset(context)
            )

            val prayerData = getUpcomingPrayerInfo(context)

            // 1. Small Widget
            updateSmallWidgets(context, appWidgetManager, dhikr)

            // 2. Medium Widget
            updateMediumWidgets(context, appWidgetManager, dhikr, prayerData)

            // 3. Large Widget
            updateLargeWidgets(context, appWidgetManager, dhikr, prayerData)

            // 4. Prayer Times Widget
            updatePrayerWidgets(context, appWidgetManager, prayerData)

            // 5. Wird & Khatma Widget
            updateWirdWidgets(context, appWidgetManager)

            // 6. Ramadan Widget
            updateRamadanWidgets(context, appWidgetManager, prayerData)

            // Ensure next 10-minute inexact alarm is scheduled
            scheduleNextPeriodicUpdate(context)

        } catch (e: Exception) {
            Log.e(TAG, "Error updating widgets: ${e.message}", e)
        }
    }

    private fun updateSmallWidgets(context: Context, manager: AppWidgetManager, dhikr: AzkarItem) {
        val ids = manager.getAppWidgetIds(ComponentName(context, AzkarSmallWidgetProvider::class.java))
        if (ids.isEmpty()) return

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_azkar_small)
            views.setTextViewText(R.id.small_widget_text, dhikr.text)
            views.setTextViewText(R.id.small_widget_source, dhikr.source)

            // Open app on body tap
            views.setOnClickPendingIntent(R.id.widget_root_small, createOpenAppPendingIntent(context, widgetId))

            // Next dhikr button
            views.setOnClickPendingIntent(R.id.small_btn_next, createNextDhikrPendingIntent(context))

            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateMediumWidgets(
        context: Context,
        manager: AppWidgetManager,
        dhikr: AzkarItem,
        prayerData: PrayerWidgetData
    ) {
        val mediumIds = manager.getAppWidgetIds(ComponentName(context, AzkarMediumWidgetProvider::class.java))
        val legacyIds = manager.getAppWidgetIds(ComponentName(context, com.example.quran_app_android.MyHomeWidget::class.java))
        val ids = mediumIds + legacyIds
        if (ids.isEmpty()) return

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_azkar_medium)
            views.setTextViewText(R.id.med_widget_text, dhikr.text)
            views.setTextViewText(R.id.med_widget_source, dhikr.source)
            views.setTextViewText(R.id.med_category_badge, dhikr.category_name)

            if (prayerData.nextPrayerName.isNotEmpty()) {
                views.setTextViewText(R.id.med_prayer_text, "${prayerData.nextPrayerName} ${prayerData.nextPrayerTimeStr}")
            }

            views.setOnClickPendingIntent(R.id.widget_root_medium, createOpenAppPendingIntent(context, widgetId))
            views.setOnClickPendingIntent(R.id.med_btn_next, createNextDhikrPendingIntent(context))

            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateLargeWidgets(
        context: Context,
        manager: AppWidgetManager,
        dhikr: AzkarItem,
        prayerData: PrayerWidgetData
    ) {
        val ids = manager.getAppWidgetIds(ComponentName(context, AzkarLargeWidgetProvider::class.java))
        if (ids.isEmpty()) return

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_azkar_large)
            views.setTextViewText(R.id.large_widget_text, dhikr.text)
            views.setTextViewText(R.id.large_widget_source, dhikr.source)
            views.setTextViewText(R.id.large_category_badge, dhikr.category_name)
            views.setTextViewText(R.id.large_city_name, prayerData.cityName)

            if (prayerData.nextPrayerName.isNotEmpty()) {
                views.setTextViewText(
                    R.id.large_prayer_countdown,
                    "الصلاة القادمة: ${prayerData.nextPrayerName} (${prayerData.remainingCountdown})"
                )
            }

            // Fill 5 prayer times
            views.setTextViewText(R.id.time_fajr, prayerData.fajrTime)
            views.setTextViewText(R.id.time_dhuhr, prayerData.dhuhrTime)
            views.setTextViewText(R.id.time_asr, prayerData.asrTime)
            views.setTextViewText(R.id.time_maghrib, prayerData.maghribTime)
            views.setTextViewText(R.id.time_isha, prayerData.ishaTime)

            views.setOnClickPendingIntent(R.id.widget_root_large, createOpenAppPendingIntent(context, widgetId))
            views.setOnClickPendingIntent(R.id.large_btn_open_app, createOpenAppPendingIntent(context, widgetId))
            views.setOnClickPendingIntent(R.id.large_btn_next, createNextDhikrPendingIntent(context))

            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updatePrayerWidgets(
        context: Context,
        manager: AppWidgetManager,
        prayerData: PrayerWidgetData
    ) {
        val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidgetProvider::class.java))
        if (ids.isEmpty()) return

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
            views.setTextViewText(R.id.prayer_widget_city, prayerData.cityName)

            if (prayerData.nextPrayerName.isNotEmpty()) {
                views.setTextViewText(
                    R.id.prayer_widget_countdown,
                    "الصلاة القادمة: ${prayerData.nextPrayerName} (${prayerData.remainingCountdown})"
                )
            }

            views.setTextViewText(R.id.pw_time_fajr, prayerData.fajrTime)
            views.setTextViewText(R.id.pw_time_dhuhr, prayerData.dhuhrTime)
            views.setTextViewText(R.id.pw_time_asr, prayerData.asrTime)
            views.setTextViewText(R.id.pw_time_maghrib, prayerData.maghribTime)
            views.setTextViewText(R.id.pw_time_isha, prayerData.ishaTime)

            views.setOnClickPendingIntent(R.id.widget_root_prayer, createOpenAppPendingIntent(context, widgetId))

            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateWirdWidgets(context: Context, manager: AppWidgetManager) {
        val ids = manager.getAppWidgetIds(ComponentName(context, WirdKhatmaWidgetProvider::class.java))
        if (ids.isEmpty()) return

        val prefs = context.getSharedPreferences("wird_widget_prefs", Context.MODE_PRIVATE)
        val streak = prefs.getInt("wird_streak", 0)
        val target = prefs.getInt("wird_target", 4)
        val completed = prefs.getInt("wird_completed", 0)
        val lastPage = prefs.getInt("wird_last_page", 1)
        val planTitle = prefs.getString("wird_plan_title", "الورد اليومي") ?: "الورد اليومي"

        val percent = if (target > 0) ((completed.toFloat() / target.toFloat()) * 100).toInt().coerceIn(0, 100) else 0

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_wird_khatma)
            views.setTextViewText(R.id.wird_widget_streak, if (streak > 0) "🔥 $streak أيام متتالية" else "✨ ابدأ ورد اليوم")
            views.setTextViewText(R.id.wird_widget_plan, "$planTitle: $target صفحات")
            views.setTextViewText(R.id.wird_widget_progress_text, "$completed / $target ($percent%)")
            views.setProgressBar(R.id.wird_widget_progress_bar, 100, percent, false)
            views.setTextViewText(R.id.wird_widget_last_page, "آخر قراءة: الصفحة $lastPage")

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("open_page", lastPage)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root_wird, pendingIntent)
            views.setOnClickPendingIntent(R.id.wird_btn_continue, pendingIntent)

            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateRamadanWidgets(context: Context, manager: AppWidgetManager, prayerData: PrayerWidgetData) {
        val ids = manager.getAppWidgetIds(ComponentName(context, RamadanWidgetProvider::class.java))
        if (ids.isEmpty()) return

        // 1. Try reading synced values from SharedPreferences
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val homeWidgetPrefs = context.getSharedPreferences("group.com.homeScreenApp", Context.MODE_PRIVATE)

        val dayNumber = flutterPrefs.getInt("flutter.ramadan_day", homeWidgetPrefs.getInt("ramadan_day", 1))
        val dayTitle = flutterPrefs.getString("flutter.ramadan_day_title", null)
            ?: homeWidgetPrefs.getString("ramadan_day_title", "اليوم $dayNumber")
            ?: "اليوم $dayNumber"

        val eventTitle = flutterPrefs.getString("flutter.ramadan_event_title", null)
            ?: homeWidgetPrefs.getString("ramadan_event_title", null)

        val countdownStr = flutterPrefs.getString("flutter.ramadan_countdown", null)
            ?: homeWidgetPrefs.getString("ramadan_countdown", null)

        val imsakTime = flutterPrefs.getString("flutter.ramadan_imsak_time", null)
            ?: homeWidgetPrefs.getString("ramadan_imsak_time", null)
            ?: run {
                if (prayerData.fajrTime != "--:--") prayerData.fajrTime else "04:15 ص"
            }

        val iftarTime = flutterPrefs.getString("flutter.ramadan_iftar_time", null)
            ?: homeWidgetPrefs.getString("ramadan_iftar_time", null)
            ?: prayerData.maghribTime

        val dua = flutterPrefs.getString("flutter.ramadan_daily_dua", null)
            ?: homeWidgetPrefs.getString("ramadan_daily_dua", null)
            ?: "«ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ»"

        val headerText = if (!eventTitle.isNullOrEmpty() && !countdownStr.isNullOrEmpty()) {
            "$eventTitle: $countdownStr"
        } else {
            "موعد الإفطار: $iftarTime"
        }

        for (widgetId in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_ramadan)
            views.setTextViewText(R.id.ramadan_widget_title, "شهر رمضان المبارك 🌙")
            views.setTextViewText(R.id.ramadan_widget_day, dayTitle)
            views.setTextViewText(R.id.ramadan_widget_countdown, headerText)
            views.setTextViewText(R.id.ramadan_widget_imsak, imsakTime)
            views.setTextViewText(R.id.ramadan_widget_iftar, iftarTime)
            views.setTextViewText(R.id.ramadan_widget_dua, dua)

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/ramadan_hub")
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root_ramadan, pendingIntent)

            manager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Schedules the next periodic update using an inexact alarm (every ~10 minutes).
     * DO NOT use exact alarms for widgets.
     */
    fun scheduleNextPeriodicUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_PERIODIC_UPDATE
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_PERIODIC_WIDGET,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val now = System.currentTimeMillis()
        val tenMinutesMillis = 10 * 60 * 1000L
        val nextBoundary = ((now / tenMinutesMillis) + 1) * tenMinutesMillis + 2000L

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Inexact idle-allowed alarm
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC,
                    nextBoundary,
                    pendingIntent
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC,
                    nextBoundary,
                    pendingIntent
                )
            }
            Log.d(TAG, "Scheduled inexact widget update at ${Date(nextBoundary)}")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling widget update: ${e.message}")
        }
    }

    private fun createOpenAppPendingIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        return PendingIntent.getActivity(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createNextDhikrPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_NEXT_DHIKR
            setPackage(context.packageName)
            data = android.net.Uri.parse("taqarrab://widget/next_dhikr?t=${System.currentTimeMillis()}")
            putExtra("ts", System.currentTimeMillis())
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_NEXT_DHIKR,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    data class PrayerWidgetData(
        val cityName: String,
        val nextPrayerName: String,
        val nextPrayerTimeStr: String,
        val remainingCountdown: String,
        val fajrTime: String,
        val dhuhrTime: String,
        val asrTime: String,
        val maghribTime: String,
        val ishaTime: String
    )

    private fun getUpcomingPrayerInfo(context: Context): PrayerWidgetData {
        val settings = NativePrayerManager.getSettings(context)
        val cityName = if (settings.cityName.isNotEmpty()) settings.cityName else "القاهرة"
        val timeFormat = SimpleDateFormat("hh:mm a", Locale("ar"))
        val shortTimeFormat = SimpleDateFormat("hh:mm", Locale("ar"))

        val cal = Calendar.getInstance()
        val pt = NativePrayerManager.calculatePrayerTimesForDate(
            settings,
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH)
        )

        if (pt == null) {
            return PrayerWidgetData(
                cityName = cityName,
                nextPrayerName = "الصلاة",
                nextPrayerTimeStr = "",
                remainingCountdown = "--:--",
                fajrTime = "--:--",
                dhuhrTime = "--:--",
                asrTime = "--:--",
                maghribTime = "--:--",
                ishaTime = "--:--"
            )
        }

        val fajr = pt.fajr?.time ?: 0L
        val dhuhr = pt.dhuhr?.time ?: 0L
        val asr = pt.asr?.time ?: 0L
        val maghrib = pt.maghrib?.time ?: 0L
        val isha = pt.isha?.time ?: 0L

        val now = System.currentTimeMillis()
        val prayerList = listOf(
            Triple("الفجر", fajr, shortTimeFormat.format(Date(fajr))),
            Triple("الظهر", dhuhr, shortTimeFormat.format(Date(dhuhr))),
            Triple("العصر", asr, shortTimeFormat.format(Date(asr))),
            Triple("المغرب", maghrib, shortTimeFormat.format(Date(maghrib))),
            Triple("العشاء", isha, shortTimeFormat.format(Date(isha)))
        )

        val nextTriple = prayerList.firstOrNull { it.second > now }
        val (nextName, nextTimeMs, nextTimeStr) = if (nextTriple != null) {
            Triple(nextTriple.first, nextTriple.second, timeFormat.format(Date(nextTriple.second)))
        } else {
            // All prayers today have passed (after Isha): next prayer is tomorrow's Fajr
            val tomorrowCal = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }
            val tomorrowPt = NativePrayerManager.calculatePrayerTimesForDate(
                settings,
                tomorrowCal.get(Calendar.YEAR),
                tomorrowCal.get(Calendar.MONTH) + 1,
                tomorrowCal.get(Calendar.DAY_OF_MONTH)
            )
            val tomorrowFajr = tomorrowPt?.fajr?.time ?: (fajr + 24 * 3600 * 1000L)
            Triple("الفجر", tomorrowFajr, timeFormat.format(Date(tomorrowFajr)))
        }

        val diffMillis = Math.max(0L, nextTimeMs - now)
        val hours = diffMillis / (1000 * 60 * 60)
        val minutes = (diffMillis % (1000 * 60 * 60)) / (1000 * 60)

        val countdownStr = if (hours > 0) {
            "متبقي $hours س و $minutes د"
        } else {
            "متبقي $minutes دقيقة"
        }

        return PrayerWidgetData(
            cityName = cityName,
            nextPrayerName = nextName,
            nextPrayerTimeStr = nextTimeStr,
            remainingCountdown = countdownStr,
            fajrTime = prayerList[0].third,
            dhuhrTime = prayerList[1].third,
            asrTime = prayerList[2].third,
            maghribTime = prayerList[3].third,
            ishaTime = prayerList[4].third
        )
    }
}
