package com.example.quran_app_android.azkar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.R
import com.example.quran_app_android.adhan.NativePrayerManager
import java.util.Calendar
import kotlin.random.Random

class AzkarReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.i(TAG, "📿 onReceive action: $action")

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "QuranApp:AzkarWakeLock"
        )
        wakeLock.acquire(10_000L) // 10 seconds timeout

        try {
            val isTest = action == ACTION_TEST_AZKAR
            val settings = AzkarSettingsManager.getSettings(context)

            if (!settings.enabled && !isTest) {
                Log.i(TAG, "Azkar notifications disabled. Skipping.")
                return
            }

            val now = System.currentTimeMillis()

            // 1. Check quiet prayer window (±10 minutes around any prayer time)
            if (!isTest && settings.quietPrayerWindow && isNearPrayerTime(context, now, 10L)) {
                Log.i(TAG, "⏸️ Azkar notification suppressed: within ±10 minutes of prayer time.")
                // Chain next alarm and exit
                AzkarScheduler.scheduleNext(context)
                return
            }

            // 2. Select a dhikr dynamically from native repository respecting selected categories
            val dhikr = AzkarDataRepository.getRandom(context, settings.selectedCategories)

            // 3. Display the notification
            showNotification(context, dhikr, settings)

            // 4. Chain next notification alarm if this was a scheduled run
            if (!isTest) {
                AzkarScheduler.scheduleNext(context)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error in AzkarReceiver: ${e.message}", e)
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }

    private fun showNotification(context: Context, dhikr: AzkarItem, settings: AzkarNativeSettings) {
        val channelId = if (settings.soundEnabled) "azkar_channel_sound" else "azkar_channel_silent"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = if (settings.soundEnabled) "تنبيهات الأذكار (صوتي)" else "تنبيهات الأذكار (صامت)"
            val importance = if (settings.soundEnabled) NotificationManager.IMPORTANCE_DEFAULT else NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = "تنبيهات واستغفار دوري خلال اليوم"
                if (settings.vibrationEnabled) {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 250, 200, 250)
                } else {
                    enableVibration(false)
                }
                if (!settings.soundEnabled) {
                    setSound(null, null)
                }
            }
            manager.createNotificationChannel(channel)
        }

        // Tap opens MainActivity
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            1001,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "ذكر وتذكير 📿 • ${dhikr.category_name}"
        val bigText = "${dhikr.text}\n\n📖 المصدر: ${dhikr.source}"

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_crescent_moon)
            .setContentTitle(title)
            .setContentText(dhikr.text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setContentIntent(contentPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        if (settings.vibrationEnabled) {
            builder.setVibrate(longArrayOf(0, 250, 200, 250))
        }

        if (settings.soundEnabled) {
            val defaultSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            builder.setSound(defaultSound)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            val notificationId = 30000 + Random.nextInt(1000)
            NotificationManagerCompat.from(context).notify(notificationId, builder.build())
            Log.i(TAG, "✅ Azkar notification displayed successfully: ${dhikr.id}")
        } else {
            Log.w(TAG, "⚠️ Cannot show Azkar notification: POST_NOTIFICATIONS not granted.")
        }
    }

    /**
     * Checks if current time is within ±toleranceMinutes of any of the 5 daily prayer times.
     */
    private fun isNearPrayerTime(context: Context, nowMillis: Long, toleranceMinutes: Long): Boolean {
        return try {
            val adhanSettings = NativePrayerManager.getSettings(context)
            if (!NativePrayerManager.hasValidLocation(context)) return false

            val cal = Calendar.getInstance().apply { timeInMillis = nowMillis }
            val year = cal.get(Calendar.YEAR)
            val month = cal.get(Calendar.MONTH) + 1
            val day = cal.get(Calendar.DAY_OF_MONTH)

            val pt = NativePrayerManager.calculatePrayerTimesForDate(adhanSettings, year, month, day) ?: return false
            val toleranceMillis = toleranceMinutes * 60 * 1000L

            val prayers = listOfNotNull(pt.fajr?.time, pt.dhuhr?.time, pt.asr?.time, pt.maghrib?.time, pt.isha?.time)
            prayers.any { prayerTime -> Math.abs(nowMillis - prayerTime) <= toleranceMillis }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking prayer time quiet window: ${e.message}")
            false
        }
    }

    companion object {
        private const val TAG = "AzkarReceiver"
        const val ACTION_TRIGGER_AZKAR = "com.example.quran_app_android.TRIGGER_AZKAR"
        const val ACTION_TEST_AZKAR = "com.example.quran_app_android.TEST_AZKAR"
    }
}
