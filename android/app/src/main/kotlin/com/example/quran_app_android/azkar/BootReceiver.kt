package com.example.quran_app_android.azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            val action = intent?.action ?: return
            Log.i(TAG, "🔄 System event received ($action) - Rescheduling chained azkar")

            if (action in listOf(
                    Intent.ACTION_BOOT_COMPLETED,
                    Intent.ACTION_LOCKED_BOOT_COMPLETED,
                    Intent.ACTION_MY_PACKAGE_REPLACED,
                    Intent.ACTION_TIME_CHANGED,
                    Intent.ACTION_TIMEZONE_CHANGED,
                    "android.intent.action.TIME_SET"
                )
            ) {
                // Asynchronously initialize azkar repo cache and schedule next alarm
                AzkarDataRepository.initAsync(context)
                AzkarScheduler.scheduleNext(context)
                com.example.quran_app_android.reminders.UnifiedReminderScheduler.scheduleNext(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in Azkar BootReceiver: ${e.message}", e)
        }
    }

    companion object {
        private const val TAG = "AzkarBootReceiver"
    }
}
