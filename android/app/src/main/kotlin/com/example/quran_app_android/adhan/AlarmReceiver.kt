package com.example.quran_app_android.adhan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.quran_app_android.R

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val prayerKey = intent?.getStringExtra("prayer_key") ?: "prayer"
        val prayerName = intent?.getStringExtra("prayer_name") ?: "الصلاة"
        val scheduledMillis = intent?.getLongExtra("scheduled_millis", System.currentTimeMillis()) ?: System.currentTimeMillis()
        val notificationMode = intent?.getStringExtra("notification_mode") ?: "adhan"
        val adhanSound = intent?.getStringExtra("adhan_sound") ?: "default"
        val cityName = intent?.getStringExtra("city_name") ?: ""
        val isTest = intent?.getBooleanExtra("is_test", false) ?: false

        Log.i(
            "AlarmReceiver",
            "🚨 تم استقبال منبّه صلاة $prayerName (mode=$notificationMode, sound=$adhanSound, test=$isTest)"
        )

        // 1. استيقاظ المعالج لحظيًا
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "quran_app:adhan_alarm_wakelock"
            )
            wakeLock.acquire(15 * 1000L) // 15 ثانية كافية لإطلاق الخدمة والشاشة
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "⚠️ فشل أخذ WakeLock: ${e.message}")
        }

        // 2. تجديد وإكمال نافذة الـ 7 أيام فورًا (Self-replenishing rolling window)
        try {
            if (!isTest) {
                PrayerScheduler.scheduleRollingWindow(context)
                Log.i("AlarmReceiver", "🔄 تم تجديد نافذة الـ 7 أيام بنجاح عقب إطلاق منبه $prayerName")
            }
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "⚠️ فشل تجديد نافذة الصلوات: ${e.message}")
        }

        // 3. التحقق من وضع التنبيه
        if (notificationMode == "silent") {
            Log.i("AlarmReceiver", "صلاة $prayerName مضبوطة على وضع صامت — تم تخطي التنبيه.")
            return
        }

        // 4. إذا كان الوضع "تنبيه فقط" بدون أذان كامل
        if (notificationMode == "notification_only") {
            showSimplePrayerNotification(context, prayerKey, prayerName, cityName)
            return
        }

        // 5. وضع الأذان الكامل: إطلاق خدمة الصوت والشاشة فوق القفل
        val serviceIntent = Intent(context, AdhanService::class.java).apply {
            action = "START_ADHAN"
            putExtra("prayer_key", prayerKey)
            putExtra("prayer_name", prayerName)
            putExtra("scheduled_millis", scheduledMillis)
            putExtra("adhan_sound", adhanSound)
            putExtra("city_name", cityName)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "❌ فشل بدء خدمة الأذان: ${e.message}")
        }

        // إطلاق واجهة التنبيه فوق شاشة القفل
        val alertIntent = Intent(context, AdhanAlertActivity::class.java).apply {
            putExtra("prayer_key", prayerKey)
            putExtra("prayer_name", prayerName)
            putExtra("scheduled_millis", scheduledMillis)
            putExtra("city_name", cityName)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            )
        }

        try {
            context.startActivity(alertIntent)
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "⚠️ فشل فتح واجهة التنبيه فوق شاشة القفل: ${e.message}")
        }
    }

    private fun showSimplePrayerNotification(
        context: Context,
        prayerKey: String,
        prayerName: String,
        cityName: String
    ) {
        val channelId = "prayer_simple_channel"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "تنبيهات مواقيت الصلاة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيهات مواعيد الصلاة البسيطة"
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }

        val locationSuffix = if (cityName.isNotEmpty()) " في $cityName" else ""
        val appIconBitmap = try {
            BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)
        } catch (_: Exception) {
            null
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_mosque)
            .apply {
                if (appIconBitmap != null) {
                    setLargeIcon(appIconBitmap)
                }
            }
            .setContentTitle("حان الآن موعد صلاة $prayerName")
            .setContentText("أقم صلاتك تسعد حياتك$locationSuffix")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        manager.notify(prayerKey.hashCode(), notification)
    }
}
