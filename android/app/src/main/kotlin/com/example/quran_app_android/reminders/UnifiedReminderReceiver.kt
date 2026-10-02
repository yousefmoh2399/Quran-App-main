package com.example.quran_app_android.reminders

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.R
import com.example.quran_app_android.azkar.AzkarDataRepository
import org.json.JSONObject
import kotlin.random.Random

class UnifiedReminderReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "UnifiedReminderReceiver"
        const val ACTION_SADAQAH_DONATED = "com.example.quran_app_android.reminders.ACTION_SADAQAH_DONATED"
        const val NOTIFICATION_ID_BASE = 60000

        private val SADAQAH_MESSAGES = listOf(
            "قال ﷺ: «ما نقصت صدقة من مال، وما زاد الله عبداً بعفو إلا عزاً» (صحيح مسلم)",
            "قال تعالى: ﴿مَّثَلُ الَّذِينَ يُنفِقُونَ أَمْوَالَهُمْ فِي سَبِيلِ اللَّهِ كَمَثَلِ حَبَّةٍ أَنبَتَتْ سَبْعَ سَنَابِلَ فِي كُلِّ سُنبُلَةٍ مِّائَةُ حَبَّةٍ﴾",
            "قال ﷺ: «والصدقة تطفئ الخطيئة كما يطفئ الماء النار» (رواه الترمذي)",
            "قال ﷺ: «اتقوا النار ولو بشق تمرة» (متفق عليه)",
            "قال تعالى: ﴿يَمْحَقُ اللَّهُ الرِّبَا وَيُرْبِي الصَّدَقَاتِ وَاللَّهُ لَا يُحِبُّ كُلَّ كَفَّارٍ أَثِيمٍ﴾",
            "قال ﷺ: «إن الصدقة لتطفئ عن أهلها حر القبور، وإنما يستظل المؤمن يوم القيامة في ظل صدقته»",
            "قال تعالى: ﴿وَمَا تُنفِقُوا مِنْ خَيْرٍ يُوَفَّ إِلَيْكُمْ وَأَنتُمْ لَا تُظْلَمُونَ﴾"
        )
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val reminderId = intent?.getStringExtra(UnifiedReminderScheduler.EXTRA_REMINDER_ID)
        Log.i(TAG, "🔔 onReceive triggered for reminder ID: $reminderId")

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "QuranApp:UnifiedReminderWakeLock"
        )
        wakeLock.acquire(10_000L)

        try {
            ReminderChannels.createChannels(context)

            val dbHelper = RemindersDbHelper.getInstance(context)
            val reminder = if (!reminderId.isNullOrEmpty()) {
                dbHelper.getReminder(reminderId)
            } else {
                null
            }

            if (reminder == null) {
                Log.w(TAG, "No reminder found for ID: $reminderId. Rescheduling next...")
                UnifiedReminderScheduler.scheduleNext(context)
                return
            }

            if (!reminder.enabled) {
                Log.i(TAG, "Reminder [${reminder.id}] is disabled. Rescheduling next...")
                UnifiedReminderScheduler.scheduleNext(context)
                return
            }

            // 1. Check Cancellation Condition
            if (ReminderCancellationChecker.shouldCancel(context, reminder)) {
                Log.i(TAG, "⛔ Reminder [${reminder.id}] was cancelled by condition. Skipping notification.")
                dbHelper.updateLastTriggered(reminder.id, System.currentTimeMillis())
                UnifiedReminderScheduler.scheduleNext(context)
                return
            }

            // 2. Build & Show Notification
            showNotification(context, reminder)

            // 3. Update Last Triggered
            dbHelper.updateLastTriggered(reminder.id, System.currentTimeMillis())

            // 4. Chained Next Scheduling
            UnifiedReminderScheduler.scheduleNext(context)

        } catch (e: Exception) {
            Log.e(TAG, "Error in UnifiedReminderReceiver: ${e.message}", e)
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }

    private fun showNotification(context: Context, reminder: ReminderItem) {
        val channelId = ReminderChannels.getChannelIdForType(reminder.type)
        val payload = runCatching { JSONObject(reminder.payloadJson) }.getOrElse { JSONObject() }
        val schedule = runCatching { JSONObject(reminder.scheduleJson) }.getOrElse { JSONObject() }

        var title = payload.optString("title", "تذكير")
        var body = payload.optString("body", "")

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/mushaf")
        }

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        when (reminder.type) {
            ReminderItem.TYPE_WIRD_DAILY -> {
                if (title.isEmpty()) title = "وردك القرآني اليومي"
                if (body.isEmpty()) body = "حان وقت وردك القرآني اليومي، رتّل وتدبّر آيات الله."
                openAppIntent.putExtra("target_screen", "wird")
            }

            ReminderItem.TYPE_WIRD_COMMUTE -> {
                val targetPages = schedule.optInt("target_pages", 3)
                if (title.isEmpty()) title = "ورد المواصلات"
                if (body.isEmpty()) body = "استثمر وقت طريقك في تلاوة القرآن ($targetPages صفحات)"
                openAppIntent.putExtra("target_screen", "commute_wird")
                openAppIntent.putExtra("commute_mode", true)
                openAppIntent.putExtra("reminder_id", reminder.id)
            }

            ReminderItem.TYPE_SADAQAH_MONTHLY -> {
                if (title.isEmpty()) title = "تذكير الصدقة الشهرية"
                val randomHadith = SADAQAH_MESSAGES[Random.nextInt(SADAQAH_MESSAGES.size)]
                body = randomHadith

                // Add "تصدّقت" Action Button directly in the notification
                val donateIntent = Intent(context, SadaqahActionReceiver::class.java).apply {
                    action = ACTION_SADAQAH_DONATED
                    putExtra("reminder_id", reminder.id)
                    putExtra("notification_id", NOTIFICATION_ID_BASE + reminder.id.hashCode() % 1000)
                }
                val donatePendingIntent = PendingIntent.getBroadcast(
                    context,
                    reminder.id.hashCode(),
                    donateIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                builder.addAction(
                    android.R.drawable.checkbox_on_background,
                    "تصدّقت ✓",
                    donatePendingIntent
                )
            }

            ReminderItem.TYPE_AZKAR_PERIODIC -> {
                val dhikr = AzkarDataRepository.getRandom(context)
                title = "أذكار وتسابيح"
                body = "${dhikr.text}\n— ${dhikr.source}"
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            reminder.id.hashCode(),
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        builder.setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)

        val notificationId = NOTIFICATION_ID_BASE + Math.abs(reminder.id.hashCode() % 1000)

        if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            NotificationManagerCompat.from(context).notify(notificationId, builder.build())
            Log.i(TAG, "📢 Notification posted successfully for [${reminder.id}]")
        } else {
            Log.w(TAG, "Notification permission POST_NOTIFICATIONS not granted")
        }
    }
}
