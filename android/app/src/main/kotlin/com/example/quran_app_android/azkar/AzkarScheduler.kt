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
     * Schedules the next Azkar notification through the UnifiedReminderScheduler.
     * All reminder scheduling is unified in one engine.
     */
    fun scheduleNext(context: Context) {
        // Cancel any legacy separate alarm to ensure no double-firing
        cancel(context)
        Log.i(TAG, "Delegating Azkar scheduling to UnifiedReminderScheduler")
        com.example.quran_app_android.reminders.UnifiedReminderScheduler.scheduleNext(context)
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
