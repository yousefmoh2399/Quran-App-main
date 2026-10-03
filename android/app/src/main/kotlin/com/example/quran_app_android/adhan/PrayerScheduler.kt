package com.example.quran_app_android.adhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import com.example.quran_app_android.MainActivity
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object PrayerScheduler {

    private const val TAG = "PrayerScheduler"
    private const val BACKUP_RESET_REQUEST_CODE = 12345
    private const val TEST_ADHAN_REQUEST_CODE = 12349

    private val arLocale = Locale("ar", "EG")
    private val timeFmt = SimpleDateFormat("hh:mm a, dd/MM/yyyy", arLocale).apply {
        timeZone = TimeZone.getDefault()
    }

    /**
     * Calculates and schedules a 7-day rolling window of exact prayer alarms.
     * Also schedules the daily 00:05 AM backup recalculation alarm.
     */
    fun scheduleRollingWindow(context: Context): Int {
        val now = System.currentTimeMillis()
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (!NativePrayerManager.hasValidLocation(context)) {
            Log.w(TAG, "⚠️ لا توجد إحداثيات موقع مسجلة — تم إيقاف جدولة الأذان حتى تحديد الموقع.")
            return 0
        }

        val settings = NativePrayerManager.getSettings(context)
        val rollingPrayers = NativePrayerManager.calculateRollingWindow(context, daysCount = 8)

        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val ignoring = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                pm.isIgnoringBatteryOptimizations(context.packageName)
            } else true
        } catch (_: Exception) { false }

        val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else true

        Log.i(
            TAG,
            "🚀 بدء جدولة نافذة الـ 7 أيام | SDK=${Build.VERSION.SDK_INT} | BatteryOptimizationsIgnored=$ignoring | canExact=$canExact"
        )

        var scheduledCount = 0
        var skippedCount = 0

        for (prayer in rollingPrayers) {
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("prayer_key", prayer.prayerKey)
                putExtra("prayer_name", prayer.nameAr)
                putExtra("scheduled_millis", prayer.timeMillis)
                putExtra("notification_mode", prayer.notificationMode)
                putExtra("adhan_sound", prayer.sound)
                putExtra("city_name", settings.cityName)
                putExtra("request_code", prayer.requestCode)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                prayer.requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (prayer.timeMillis <= now) {
                // Time already passed
                skippedCount++
                continue
            }

            try {
                val showIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val showPending = PendingIntent.getActivity(
                    context,
                    prayer.requestCode,
                    showIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (canExact) {
                        val alarmClockInfo = AlarmManager.AlarmClockInfo(prayer.timeMillis, showPending)
                        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    } else {
                        Log.w(TAG, "⚠️ صلاحية المنبهات الدقيقة غير متاحة، استخدام setAndAllowWhileIdle لصلاة ${prayer.nameAr}")
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            prayer.timeMillis,
                            pendingIntent
                        )
                    }
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        prayer.timeMillis,
                        pendingIntent
                    )
                }
                scheduledCount++
            } catch (e: Exception) {
                Log.e(TAG, "❌ فشل جدولة صلاة ${prayer.nameAr} (Day ${prayer.dayOffset}): ${e.message}")
            }
        }

        Log.i(
            TAG,
            "✅ تم جدولة $scheduledCount صلاة قادمة بنجاح على مدار 7 أيام (تم تجاوز $skippedCount صلاة سابقة)"
        )

        // جدولة منبه الاحتياط اليومي الساعة 00:05
        scheduleDailyMidnightBackup(context)

        logNextPrayer(rollingPrayers, now)
        return scheduledCount
    }

    /**
     * Schedules daily backup reset alarm at 00:05 AM every day.
     * At 00:05, AdhanResetReceiver recalculates and replenishes the 7-day rolling window.
     */
    fun scheduleDailyMidnightBackup(context: Context) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, AdhanResetReceiver::class.java).apply {
                action = "RECALCULATE_ADHAN_WINDOW"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                BACKUP_RESET_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val now = Calendar.getInstance()
            val backupTime = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 5)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= now.timeInMillis) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }

            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else true

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (canExact) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        backupTime.timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        backupTime.timeInMillis,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    backupTime.timeInMillis,
                    pendingIntent
                )
            }

            Log.i(
                TAG,
                "🕛 تم جدولة منبه الاحتياط اليومي الساعة 00:05 (${timeFmt.format(backupTime.timeInMillis)})"
            )
        } catch (e: Exception) {
            Log.e(TAG, "💥 فشل جدولة منبه الاحتياط اليومي: ${e.message}")
        }
    }

    /**
     * Schedules a test adhan alarm after [delaySeconds] (for debug and testing).
     */
    fun scheduleTestAdhan(context: Context, delaySeconds: Int = 10, prayerName: String = "الفجر") {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerTime = System.currentTimeMillis() + (delaySeconds * 1000L)

            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("prayer_key", "test")
                putExtra("prayer_name", prayerName)
                putExtra("scheduled_millis", triggerTime)
                putExtra("notification_mode", "adhan")
                putExtra("adhan_sound", "default")
                putExtra("city_name", "اختبار الأذان")
                putExtra("is_test", true)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                TEST_ADHAN_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val showIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val showPending = PendingIntent.getActivity(
                context,
                TEST_ADHAN_REQUEST_CODE,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerTime, showPending)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }

            Log.i(TAG, "🧪 [اختبار] تم جدولة منبه أذان تجريبي بعد $delaySeconds ثانية ($triggerTime)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ فشل جدولة الأذان التجريبي: ${e.message}")
        }
    }

    /**
     * Returns upcoming scheduled prayers as a list of maps for inspection in Flutter Debug screen.
     */
    fun getUpcomingPrayersList(context: Context): List<Map<String, Any>> {
        val now = System.currentTimeMillis()
        val rolling = NativePrayerManager.calculateRollingWindow(context, daysCount = 8)
        val upcoming = rolling.filter { it.timeMillis > now }

        val fmt = SimpleDateFormat("yyyy-MM-dd hh:mm a", arLocale)
        return upcoming.map { prayer ->
            mapOf(
                "prayerKey" to prayer.prayerKey,
                "prayerName" to prayer.nameAr,
                "timeMillis" to prayer.timeMillis,
                "formattedTime" to fmt.format(prayer.timeMillis),
                "dayOffset" to prayer.dayOffset,
                "requestCode" to prayer.requestCode,
                "notificationMode" to prayer.notificationMode,
                "sound" to prayer.sound
            )
        }
    }

    private fun logNextPrayer(prayers: List<ScheduledPrayer>, now: Long) {
        val upcoming = prayers.filter { it.timeMillis > now }.minByOrNull { it.timeMillis }
        if (upcoming == null) {
            Log.w(TAG, "ℹ️ لا توجد صلوات قادمة مسجلة في النافذة الحالية.")
            return
        }

        val remainingMs = upcoming.timeMillis - now
        Log.i(
            TAG,
            "⏰ الصلاة القادمة: ${upcoming.nameAr} (اليوم ${upcoming.dayOffset}) — ${timeFmt.format(upcoming.timeMillis)} — بعد ${formatRemaining(remainingMs)}"
        )
    }

    private fun formatRemaining(ms: Long): String {
        var sec = ms / 1000
        val days = sec / 86400
        sec %= 86400
        val hours = sec / 3600
        sec %= 3600
        val minutes = sec / 60

        val parts = mutableListOf<String>()
        if (days > 0) parts += "$days يوم"
        if (hours > 0) parts += "$hours ساعة"
        if (minutes > 0) parts += "$minutes دقيقة"
        if (parts.isEmpty()) return "أقل من دقيقة"
        return parts.joinToString(" و ")
    }
}
