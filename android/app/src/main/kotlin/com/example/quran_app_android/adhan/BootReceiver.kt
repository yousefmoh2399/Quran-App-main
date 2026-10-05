package com.example.quran_app_android.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i("AdhanBootReceiver", "🚀 استلام حدث نظام ($action) — إعادة فحص وجدولة الصلوات")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.TIME_SET" -> {
                try {
                    if (NativePrayerManager.hasValidLocation(context)) {
                        val count = PrayerScheduler.scheduleRollingWindow(context)
                        Log.i("AdhanBootReceiver", "🕋 تمت إعادة جدولة $count صلاة بنجاح للـ 7 أيام القادمة بعد $action")
                    } else {
                        Log.w("AdhanBootReceiver", "⚠️ لم يتم العثور على موقع مسجل — في انتظار فتح المستخدم للتطبيق وتحديد موقعه.")
                    }
                } catch (e: Exception) {
                    Log.e("AdhanBootReceiver", "💥 فشل أثناء إعادة الجدولة بعد $action: ${e.message}")
                }
            }
            else -> {
                Log.d("AdhanBootReceiver", "حدث غير معني: $action")
            }
        }
    }
}
