package com.example.quran_app_android.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.azkar.AzkarScheduler
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Date

object UnifiedReminderScheduler {
    private const val TAG = "UnifiedScheduler"
    const val REQUEST_CODE_UNIFIED_ALARM = 50001
    const val ACTION_UNIFIED_ALARM = "com.example.quran_app_android.reminders.ACTION_UNIFIED_ALARM"
    const val EXTRA_REMINDER_ID = "extra_reminder_id"

    /**
     * Calculates the closest upcoming trigger timestamp among ALL enabled reminders
     * and sets ONE single chained alarm.
     */
    fun scheduleNext(context: Context) {
        val dbHelper = RemindersDbHelper.getInstance(context)
        val enabledReminders = dbHelper.getEnabledReminders()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (enabledReminders.isEmpty()) {
            cancelAlarm(context, alarmManager)
            Log.i(TAG, "No enabled reminders found. Cancelled unified alarm.")
            return
        }

        val now = System.currentTimeMillis()
        var closestReminder: ReminderItem? = null
        var earliestTriggerTime = Long.MAX_VALUE

        for (reminder in enabledReminders) {
            val nextTime = calculateNextTriggerTime(reminder, now)
            if (nextTime in (now + 1000L)..<earliestTriggerTime) {
                earliestTriggerTime = nextTime
                closestReminder = reminder
            }
        }

        if (closestReminder == null || earliestTriggerTime == Long.MAX_VALUE) {
            cancelAlarm(context, alarmManager)
            Log.i(TAG, "Could not determine any future trigger time for enabled reminders.")
            return
        }

        val intent = Intent(context, UnifiedReminderReceiver::class.java).apply {
            action = ACTION_UNIFIED_ALARM
            putExtra(EXTRA_REMINDER_ID, closestReminder.id)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_UNIFIED_ALARM,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            val showIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val showPending = PendingIntent.getActivity(
                context,
                REQUEST_CODE_UNIFIED_ALARM,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    alarmManager.canScheduleExactAlarms()
                } else true

                if (canExact) {
                    val alarmClockInfo = AlarmManager.AlarmClockInfo(earliestTriggerTime, showPending)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        earliestTriggerTime,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    earliestTriggerTime,
                    pendingIntent
                )
            }

            Log.i(TAG, "⏰ Scheduled unified alarm (exact alarm clock) for [${closestReminder.id} - ${closestReminder.type}] at ${Date(earliestTriggerTime)}")

            // Save active schedule info in SharedPreferences for easy querying
            val prefs = context.getSharedPreferences("unified_reminders_state", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("active_reminder_id", closestReminder.id)
                .putLong("active_reminder_time", earliestTriggerTime)
                .apply()

        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling unified alarm: ${e.message}", e)
        }
    }

    /**
     * Calculates the next trigger time for a single reminder strictly in the future.
     */
    fun calculateNextTriggerTime(reminder: ReminderItem, now: Long = System.currentTimeMillis()): Long {
        val schedule = runCatching { JSONObject(reminder.scheduleJson) }.getOrElse { JSONObject() }

        return when (reminder.type) {
            ReminderItem.TYPE_WIRD_DAILY -> {
                val hour = schedule.optInt("hour", 20)
                val minute = schedule.optInt("minute", 0)
                calculateNextDailyTime(hour, minute, now)
            }

            ReminderItem.TYPE_WIRD_COMMUTE -> {
                val daysArray = schedule.optJSONArray("days")
                val activeDays = if (daysArray != null && daysArray.length() > 0) {
                    (0 until daysArray.length()).map { daysArray.getInt(it) }.toSet()
                } else {
                    setOf(Calendar.SUNDAY, Calendar.MONDAY, Calendar.TUESDAY, Calendar.WEDNESDAY, Calendar.THURSDAY)
                }

                val slotsArray = schedule.optJSONArray("slots")
                if (slotsArray != null && slotsArray.length() > 0) {
                    var earliestSlot = Long.MAX_VALUE
                    for (i in 0 until slotsArray.length()) {
                        val slot = slotsArray.getJSONObject(i)
                        val slotHour = slot.optInt("hour", 7)
                        val slotMinute = slot.optInt("minute", 30)
                        val slotNext = calculateNextWeeklyTime(slotHour, slotMinute, activeDays, now)
                        if (slotNext in (now + 1000L)..<earliestSlot) {
                            earliestSlot = slotNext
                        }
                    }
                    if (earliestSlot != Long.MAX_VALUE) {
                        return earliestSlot
                    }
                }

                val hour = schedule.optInt("hour", 7)
                val minute = schedule.optInt("minute", 30)
                calculateNextWeeklyTime(hour, minute, activeDays, now)
            }

            ReminderItem.TYPE_SADAQAH_MONTHLY -> {
                val calendarType = schedule.optString("calendar", "gregorian")
                val dayType = schedule.optString("day_type", "day_of_month")
                val targetDay = schedule.optInt("day", 25)
                val hour = schedule.optInt("hour", 10)
                val minute = schedule.optInt("minute", 0)
                val secondReminder = schedule.optBoolean("second_reminder", false)

                val primaryTrigger = HijriCalendarHelper.calculateNextMonthlyTrigger(
                    calendarType = calendarType,
                    dayType = dayType,
                    targetDay = targetDay,
                    hour = hour,
                    minute = minute,
                    currentTimeMillis = now
                )

                // Check if a second reminder (2 days after previous cycle) should be triggered
                if (secondReminder && reminder.lastTriggered > 0) {
                    val twoDaysAfterLast = reminder.lastTriggered + 2 * 24 * 60 * 60 * 1000L
                    if (twoDaysAfterLast > now && twoDaysAfterLast < primaryTrigger) {
                        return twoDaysAfterLast
                    }
                }

                primaryTrigger
            }

            ReminderItem.TYPE_AZKAR_PERIODIC -> {
                val intervalMinutes = schedule.optInt("interval_minutes", 60)
                val fromHour = schedule.optInt("from_hour", 8)
                val fromMinute = schedule.optInt("from_minute", 0)
                val toHour = schedule.optInt("to_hour", 22)
                val toMinute = schedule.optInt("to_minute", 0)
                AzkarScheduler.calculateNextTriggerTime(intervalMinutes, fromHour, fromMinute, toHour, toMinute, now)
            }

            else -> {
                val hour = schedule.optInt("hour", 12)
                val minute = schedule.optInt("minute", 0)
                calculateNextDailyTime(hour, minute, now)
            }
        }
    }

    private fun calculateNextDailyTime(hour: Int, minute: Int, now: Long): Long {
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= now) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }

    private fun calculateNextWeeklyTime(hour: Int, minute: Int, activeDays: Set<Int>, now: Long): Long {
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        for (i in 0..7) {
            val candidateCal = (cal.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, i) }
            val dayOfWeek = candidateCal.get(Calendar.DAY_OF_WEEK)
            if (activeDays.contains(dayOfWeek) && candidateCal.timeInMillis > now) {
                return candidateCal.timeInMillis
            }
        }

        // Fallback
        cal.add(Calendar.DAY_OF_YEAR, 1)
        return cal.timeInMillis
    }

    private fun cancelAlarm(context: Context, alarmManager: AlarmManager) {
        val intent = Intent(context, UnifiedReminderReceiver::class.java).apply {
            action = ACTION_UNIFIED_ALARM
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_UNIFIED_ALARM,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}
