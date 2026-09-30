package com.example.quran_app_android.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return

        Log.i("BootReceiver", "🚀 BootReceiver تم استدعاؤه — الحدث الحالي: $action")

        if (action in listOf(
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_LOCKED_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED,
                Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED
            )
        ) {
            Log.i("BootReceiver", "♻️ النظام تغيّر ($action) → إعادة جدولة الأذان")

            val prefs = context.getSharedPreferences("location_prefs", Context.MODE_PRIVATE)
            val lat = prefs.getFloat("lat", 0f).toDouble()
            val lng = prefs.getFloat("lng", 0f).toDouble()

            if (lat == 0.0 || lng == 0.0) {
                Log.w("BootReceiver", "⚠️ لا توجد إحداثيات محفوظة — لن يتم جدولة الأذان.")
                Toast.makeText(context, "⚠️ لم يتم العثور على الموقع لتجديد الأذان", Toast.LENGTH_SHORT).show()
                return
            }

            Log.i("BootReceiver", "✅ تم العثور على إحداثيات محفوظة ($lat, $lng) — إعادة الجدولة الآن")
            Toast.makeText(context, "🔁 إعادة جدولة الأذان تلقائيًا بعد إعادة التشغيل", Toast.LENGTH_SHORT).show()

            try {
                NativeAdhanBridge.reschedule(context, lat, lng)
                Log.i("BootReceiver", "🕋 تم استدعاء NativeAdhanBridge.reschedule بنجاح")
            } catch (e: Exception) {
                Log.e("BootReceiver", "💥 فشل أثناء إعادة الجدولة: ${e.message}")
            }
        } else {
            Log.d("BootReceiver", "ℹ️ حدث غير مهم: $action")
        }
    }
}
