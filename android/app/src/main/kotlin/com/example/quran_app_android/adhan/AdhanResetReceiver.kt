package com.example.quran_app_android.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Triggered at 00:05 AM every day or upon manual reset.
 * Recalculates prayer times for the new day and replenishes the 7-day rolling window
 * using true astronomical calculation from NativePrayerManager (not adding 24h).
 */
class AdhanResetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i("AdhanResetReceiver", "🕛 استقبال حدث إعادة الجدولة الليلية (00:05 AM) — جاري إعادة الحساب فلكياً لـ 7 أيام قادمة")
        try {
            if (NativePrayerManager.hasValidLocation(context)) {
                val scheduled = PrayerScheduler.scheduleRollingWindow(context)
                Log.i("AdhanResetReceiver", "✅ تمت إعادة جدولة $scheduled صلاة بنجاح للنافذة القادمة.")
            } else {
                Log.w("AdhanResetReceiver", "⚠️ لا توجد إحداثيات موقع مسجلة — تم تأجيل الجدولة.")
            }
        } catch (e: Exception) {
            Log.e("AdhanResetReceiver", "💥 فشل في إعادة الحساب والجدولة الليلية: ${e.message}")
        }
    }
}
