package com.example.quran_app_android.reminders

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

object ReminderChannels {
    const val CHANNEL_WIRD_DAILY = "channel_wird_daily"
    const val CHANNEL_WIRD_COMMUTE = "channel_wird_commute"
    const val CHANNEL_SADAQAH = "channel_sadaqah"
    const val CHANNEL_AZKAR = "channel_azkar_periodic"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        // 1. Channel Wird Daily
        val wirdChannel = NotificationChannel(
            CHANNEL_WIRD_DAILY,
            "الورد اليومي للقرآن",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات الورد القرآني اليومي وقراءة صفحات المصحف"
            enableVibration(true)
            setSound(soundUri, audioAttributes)
        }
        manager.createNotificationChannel(wirdChannel)

        // 2. Channel Wird Commute
        val commuteChannel = NotificationChannel(
            CHANNEL_WIRD_COMMUTE,
            "ورد المواصلات",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات ورد القراءة أثناء التنقل والمواصلات"
            enableVibration(true)
            setSound(soundUri, audioAttributes)
        }
        manager.createNotificationChannel(commuteChannel)

        // 3. Channel Sadaqah
        val sadaqahChannel = NotificationChannel(
            CHANNEL_SADAQAH,
            "الصدقة وتفقد المحتاجين",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تذكير بالصدقة الشهرية وأبواب البر والخير"
            enableVibration(true)
            setSound(soundUri, audioAttributes)
        }
        manager.createNotificationChannel(sadaqahChannel)

        // 4. Channel Azkar
        val azkarChannel = NotificationChannel(
            CHANNEL_AZKAR,
            "الأذكار الدورية",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "تذكيرات دورية بالأذكار النبوية والاستغفار والتسبيح"
            enableVibration(true)
        }
        manager.createNotificationChannel(azkarChannel)
    }

    fun getChannelIdForType(type: String): String {
        return when (type) {
            ReminderItem.TYPE_WIRD_DAILY -> CHANNEL_WIRD_DAILY
            ReminderItem.TYPE_WIRD_COMMUTE -> CHANNEL_WIRD_COMMUTE
            ReminderItem.TYPE_SADAQAH_MONTHLY -> CHANNEL_SADAQAH
            ReminderItem.TYPE_AZKAR_PERIODIC -> CHANNEL_AZKAR
            else -> CHANNEL_WIRD_DAILY
        }
    }
}
