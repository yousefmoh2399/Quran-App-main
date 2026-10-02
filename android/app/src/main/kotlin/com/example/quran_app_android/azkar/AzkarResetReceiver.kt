package com.example.quran_app_android.azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AzkarResetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            Log.i("AzkarResetReceiver", "🌙 Midnight reached — rescheduling azkar for new day")

            // Re-schedule next chained alarm
            AzkarScheduler.scheduleNext(context)
        } catch (e: Exception) {
            Log.e("AzkarResetReceiver", "❌ Error resetting daily azkar: ${e.message}")
            e.printStackTrace()
        }
    }
}
