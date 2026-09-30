package com.example.quran_app_android.azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar
import java.util.Date

object AzkarScheduler {
    private const val TAG = "AzkarScheduler"
    const val REQUEST_CODE_CHAINED_AZKAR = 40001

    /**
     * Schedules the next chained Azkar notification alarm based on user settings.
     */
    fun scheduleNext(context: Context) {
        val settings = AzkarSettingsManager.getSettings(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (!settings.enabled) {
            cancel(context)
            Log.i(TAG, "Azkar notifications disabled. Cancelled alarm.")
            return
        }

        val nextTriggerMillis = calculateNextTriggerTime(
            intervalMinutes = settings.intervalMinutes,
            fromHour = settings.activeFromHour,
            fromMinute = settings.activeFromMinute,
            toHour = settings.activeToHour,
            toMinute = settings.activeToMinute
        )

        val intent = Intent(context, AzkarReceiver::class.java).apply {
            action = AzkarReceiver.ACTION_TRIGGER_AZKAR
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_CHAINED_AZKAR,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextTriggerMillis,
                    pendingIntent
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    nextTriggerMillis,
                    pendingIntent
                )
            }
            Log.i(TAG, "⏰ Scheduled next chained Azkar alarm at ${Date(nextTriggerMillis)} (in ${settings.intervalMinutes} min intervals)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule chained azkar alarm: ${e.message}", e)
        }
    }

    /**
     * Calculates the next timestamp within the active hours window.
     */
    fun calculateNextTriggerTime(
        intervalMinutes: Int,
        fromHour: Int,
        fromMinute: Int,
        toHour: Int,
        toMinute: Int,
        currentTimeMillis: Long = System.currentTimeMillis()
    ): Long {
        val nowCal = Calendar.getInstance().apply {
            timeInMillis = currentTimeMillis
        }

        val startCal = Calendar.getInstance().apply {
            timeInMillis = currentTimeMillis
            set(Calendar.HOUR_OF_DAY, fromHour)
            set(Calendar.MINUTE, fromMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val endCal = Calendar.getInstance().apply {
            timeInMillis = currentTimeMillis
            set(Calendar.HOUR_OF_DAY, toHour)
            set(Calendar.MINUTE, toMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val now = nowCal.timeInMillis
        val start = startCal.timeInMillis
        val end = endCal.timeInMillis

        // If from == to, assume 24-hour operation
        if (fromHour == toHour && fromMinute == toMinute) {
            return now + intervalMinutes * 60 * 1000L
        }

        return if (now < start) {
            // Before active window: trigger at window start today
            start
        } else if (now in start..end) {
            val candidate = now + intervalMinutes * 60 * 1000L
            if (candidate <= end) {
                candidate
            } else {
                // Past end window: schedule for window start tomorrow
                startCal.apply { add(Calendar.DAY_OF_YEAR, 1) }.timeInMillis
            }
        } else {
            // Past end window: schedule for window start tomorrow
            startCal.apply { add(Calendar.DAY_OF_YEAR, 1) }.timeInMillis
        }
    }

    /**
     * Cancels any pending azkar alarm.
     */
    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AzkarReceiver::class.java).apply {
            action = AzkarReceiver.ACTION_TRIGGER_AZKAR
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_CHAINED_AZKAR,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
        Log.i(TAG, "Cancelled chained azkar alarm")
    }
}
