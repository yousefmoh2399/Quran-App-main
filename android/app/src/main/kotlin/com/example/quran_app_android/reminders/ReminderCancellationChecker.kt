package com.example.quran_app_android.reminders

import android.content.Context
import android.util.Log
import com.example.quran_app_android.adhan.NativePrayerManager
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ReminderCancellationChecker {
    private const val TAG = "CancellationChecker"
    const val PREFS_USER_PROGRESS = "quran_user_progress_prefs"
    const val KEY_WIRD_LAST_COMPLETED_DATE = "wird_last_completed_date"
    const val PREFS_SADAQAH = "quran_sadaqah_prefs"

    /**
     * Returns true if the reminder should be cancelled/suppressed at trigger time.
     */
    fun shouldCancel(context: Context, reminder: ReminderItem): Boolean {
        try {
            val now = System.currentTimeMillis()
            val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))

            when (reminder.type) {
                ReminderItem.TYPE_WIRD_DAILY -> {
                    val prefs = context.getSharedPreferences(PREFS_USER_PROGRESS, Context.MODE_PRIVATE)
                    val lastCompleted = prefs.getString(KEY_WIRD_LAST_COMPLETED_DATE, "")
                    if (lastCompleted == todayStr) {
                        Log.i(TAG, "🚫 Suppressing daily wird notification: today's wird was already completed ($todayStr)")
                        return true
                    }
                }

                ReminderItem.TYPE_WIRD_COMMUTE -> {
                    val scheduleObj = runCatching { JSONObject(reminder.scheduleJson) }.getOrNull()
                    val slotId = scheduleObj?.optString("slot_id", reminder.id) ?: reminder.id
                    val prefs = context.getSharedPreferences(PREFS_USER_PROGRESS, Context.MODE_PRIVATE)
                    val isDone = prefs.getBoolean("commute_done_${slotId}_$todayStr", false)
                    if (isDone) {
                        Log.i(TAG, "🚫 Suppressing commute wird notification ($slotId): already completed today ($todayStr)")
                        return true
                    }
                }

                ReminderItem.TYPE_SADAQAH_MONTHLY -> {
                    val prefs = context.getSharedPreferences(PREFS_SADAQAH, Context.MODE_PRIVATE)
                    val monthKey = SimpleDateFormat("yyyy-MM", Locale.US).format(Date(now))
                    val isDonated = prefs.getBoolean("sadaqah_donated_$monthKey", false)

                    val scheduleObj = runCatching { JSONObject(reminder.scheduleJson) }.getOrNull()
                    val isSecondReminder = scheduleObj?.optBoolean("is_second_reminder", false) ?: false

                    if (isDonated) {
                        Log.i(TAG, "🚫 Suppressing sadaqah reminder: already marked as donated for cycle $monthKey")
                        return true
                    }
                }

                ReminderItem.TYPE_AZKAR_PERIODIC -> {
                    // Check prayer quiet window (±10 minutes around any prayer time)
                    if (isNearPrayerTime(context, now, 10L)) {
                        Log.i(TAG, "🚫 Suppressing azkar notification: within ±10 minutes of prayer time.")
                        return true
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking cancellation condition: ${e.message}", e)
        }
        return false
    }

    private fun isNearPrayerTime(context: Context, nowMillis: Long, toleranceMinutes: Long): Boolean {
        return try {
            val adhanSettings = NativePrayerManager.getSettings(context)
            if (!NativePrayerManager.hasValidLocation(context)) return false

            val cal = java.util.Calendar.getInstance().apply { timeInMillis = nowMillis }
            val year = cal.get(java.util.Calendar.YEAR)
            val month = cal.get(java.util.Calendar.MONTH) + 1
            val day = cal.get(java.util.Calendar.DAY_OF_MONTH)

            val pt = NativePrayerManager.calculatePrayerTimesForDate(adhanSettings, year, month, day) ?: return false
            val toleranceMillis = toleranceMinutes * 60 * 1000L

            val prayers = listOfNotNull(pt.fajr?.time, pt.dhuhr?.time, pt.asr?.time, pt.maghrib?.time, pt.isha?.time)
            prayers.any { prayerTime -> Math.abs(nowMillis - prayerTime) <= toleranceMillis }
        } catch (e: Exception) {
            Log.e(TAG, "Error in isNearPrayerTime: ${e.message}")
            false
        }
    }
}
