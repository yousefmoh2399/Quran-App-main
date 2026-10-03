package com.example.quran_app_android.reminders

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build

object ReminderChannels {
    const val PREFS_SOUNDS = "reminder_sound_settings"
    const val KEY_MODE = "sound_mode" // "custom", "unified", "default"
    const val KEY_UNIFIED_SOUND = "unified_sound"
    const val KEY_WIRD_SOUND = "wird_sound"
    const val KEY_COMMUTE_SOUND = "commute_sound"
    const val KEY_SADAQAH_SOUND = "sadaqah_sound"
    const val KEY_AZKAR_SOUND = "azkar_sound"

    fun getSoundKeyForType(context: Context, type: String): String {
        val prefs = context.getSharedPreferences(PREFS_SOUNDS, Context.MODE_PRIVATE)
        val mode = prefs.getString(KEY_MODE, "custom") ?: "custom"
        if (mode == "default") return "system_default"
        if (mode == "unified") return prefs.getString(KEY_UNIFIED_SOUND, "fazakkir") ?: "fazakkir"

        return when (type) {
            ReminderItem.TYPE_WIRD_DAILY -> prefs.getString(KEY_WIRD_SOUND, "fazakkir") ?: "fazakkir"
            ReminderItem.TYPE_WIRD_COMMUTE -> prefs.getString(KEY_COMMUTE_SOUND, "fazakkir") ?: "fazakkir"
            ReminderItem.TYPE_SADAQAH_MONTHLY -> prefs.getString(KEY_SADAQAH_SOUND, "azkar_2") ?: "azkar_2"
            ReminderItem.TYPE_AZKAR_PERIODIC -> prefs.getString(KEY_AZKAR_SOUND, "azkar_1") ?: "azkar_1"
            else -> "system_default"
        }
    }

    fun getSoundUri(context: Context, soundKey: String): Uri? {
        return when (soundKey) {
            "silent" -> null
            "system_default", "default" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            "azkar_1" -> Uri.parse("android.resource://${context.packageName}/raw/azkar_1")
            "azkar_2" -> Uri.parse("android.resource://${context.packageName}/raw/azkar_2")
            "fazakkir" -> Uri.parse("android.resource://${context.packageName}/raw/fazakkir")
            "adhan" -> Uri.parse("android.resource://${context.packageName}/raw/adhan")
            "cannon" -> Uri.parse("android.resource://${context.packageName}/raw/cannon")
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
    }

    fun getChannelIdForType(context: Context, type: String): String {
        val soundKey = getSoundKeyForType(context, type)
        return when (type) {
            ReminderItem.TYPE_WIRD_DAILY -> "channel_wird_daily_$soundKey"
            ReminderItem.TYPE_WIRD_COMMUTE -> "channel_wird_commute_$soundKey"
            ReminderItem.TYPE_SADAQAH_MONTHLY -> "channel_sadaqah_$soundKey"
            ReminderItem.TYPE_AZKAR_PERIODIC -> "channel_azkar_$soundKey"
            else -> "channel_wird_daily_$soundKey"
        }
    }

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val types = listOf(
            Triple(ReminderItem.TYPE_WIRD_DAILY, "الورد اليومي للقرآن", "تنبيهات الورد القرآني اليومي ومتابعة الختمة"),
            Triple(ReminderItem.TYPE_WIRD_COMMUTE, "ورد المواصلات", "تنبيهات ورد القراءة أثناء التنقل والمواصلات"),
            Triple(ReminderItem.TYPE_SADAQAH_MONTHLY, "الصدقة وتفقد المحتاجين", "تذكير بالصدقة الشهرية وأبواب البر والخير"),
            Triple(ReminderItem.TYPE_AZKAR_PERIODIC, "الأذكار والتسابيح", "تذكيرات دورية بالأذكار النبوية والاستغفار")
        )

        for ((type, name, desc) in types) {
            val soundKey = getSoundKeyForType(context, type)
            val channelId = getChannelIdForType(context, type)
            val soundUri = getSoundUri(context, soundKey)

            val importance = if (soundKey == "silent") {
                NotificationManager.IMPORTANCE_LOW
            } else {
                NotificationManager.IMPORTANCE_HIGH
            }

            val channel = NotificationChannel(channelId, name, importance).apply {
                description = desc
                enableVibration(true)
                if (soundKey == "silent") {
                    setSound(null, null)
                } else if (soundUri != null) {
                    setSound(soundUri, audioAttributes)
                }
            }
            manager.createNotificationChannel(channel)
        }
    }
}
