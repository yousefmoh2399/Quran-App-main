package com.example.quran_app_android.reminders

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.PowerManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.quran_app_android.MainActivity
import com.example.quran_app_android.R
import com.example.quran_app_android.azkar.AzkarDataRepository
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.abs
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
        private val WIRD_QUOTES = listOf(
            "قال ﷺ: «اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه» (صحيح مسلم)",
            "قال تعالى: ﴿إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ﴾",
            "قال ﷺ: «خيركم من تعلم القرآن وعلمه» (صحيح البخاري)",
            "قال تعالى: ﴿وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا﴾",
            "قال ﷺ: «يقال لصاحب القرآن: اقرأ وارق ورتل كما كنت ترتل في الدنيا» (رواه الترمذي)",
            "قال تعالى: ﴿كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ﴾"
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
        val channelId = ReminderChannels.getChannelIdForType(context, reminder.type)
        val payload = runCatching { JSONObject(reminder.payloadJson) }.getOrElse { JSONObject() }
        val schedule = runCatching { JSONObject(reminder.scheduleJson) }.getOrElse { JSONObject() }

        var title = payload.optString("title", "تذكير")
        var body = payload.optString("body", "")

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val appIconBitmap = BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_crescent_moon)
            .setLargeIcon(appIconBitmap)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val soundKey = ReminderChannels.getSoundKeyForType(context, reminder.type)
        val soundUri = ReminderChannels.getSoundUri(context, soundKey)
        if (soundKey == "silent") {
            builder.setSilent(true)
        } else if (soundUri != null) {
            builder.setSound(soundUri)
        }

        when (reminder.type) {
            ReminderItem.TYPE_WIRD_DAILY -> {
                if (title.isEmpty()) title = "وردك القرآني اليومي 📖"
                val quote = WIRD_QUOTES[Random.nextInt(WIRD_QUOTES.size)]
                body = "حان وقت وردك القرآني المبارك، رتّل وتدبّر آيات الله.\n$quote"
                openAppIntent.putExtra("target_screen", "wird")
                openAppIntent.putExtra("route", "/mushaf")
            }

            ReminderItem.TYPE_WIRD_COMMUTE -> {
                var targetPages = schedule.optInt("target_pages", 3)
                var slotId: String? = null
                val slotsArray = schedule.optJSONArray("slots")
                if (slotsArray != null && slotsArray.length() > 0) {
                    val cal = Calendar.getInstance()
                    val currentMins = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
                    var bestSlot: JSONObject? = null
                    var minDiff = Int.MAX_VALUE
                    for (i in 0 until slotsArray.length()) {
                        val s = slotsArray.getJSONObject(i)
                        val h = s.optInt("hour", 7)
                        val m = s.optInt("minute", 30)
                        val diff = abs((h * 60 + m) - currentMins)
                        if (diff < minDiff) {
                            minDiff = diff
                            bestSlot = s
                        }
                    }
                    if (bestSlot != null) {
                        targetPages = bestSlot.optInt("target_pages", targetPages)
                        slotId = if (bestSlot.has("id")) bestSlot.optString("id") else null
                    }
                }

                if (title.isEmpty()) title = "ورد المواصلات 🚌"
                if (body.isEmpty()) body = "استثمر وقت طريقك في تلاوة القرآن الكريم ($targetPages صفحات)"
                openAppIntent.putExtra("target_screen", "commute_wird")
                openAppIntent.putExtra("route", "/mushaf")
                openAppIntent.putExtra("commute_mode", true)
                openAppIntent.putExtra("target_pages", targetPages)
                if (slotId != null) openAppIntent.putExtra("slot_id", slotId)
                val countTowards = schedule.optBoolean("count_towards_main", true)
                openAppIntent.putExtra("count_towards_main", countTowards)
                val lastPage = schedule.optInt("last_page", 1)
                openAppIntent.putExtra("page", lastPage)
                openAppIntent.putExtra("reminder_id", reminder.id)
            }

            ReminderItem.TYPE_SADAQAH_MONTHLY -> {
                if (title.isEmpty()) title = "تذكير الصدقة الشهرية 🌿"
                val randomHadith = SADAQAH_MESSAGES[Random.nextInt(SADAQAH_MESSAGES.size)]
                body = randomHadith
                openAppIntent.putExtra("target_screen", "sadaqah")
                openAppIntent.putExtra("route", "/sadaqahLogs")

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
                val settings = com.example.quran_app_android.azkar.AzkarSettingsManager.getSettings(context)
                val dhikr = AzkarDataRepository.getRotatingZikr(context, settings.selectedCategories)
                title = AzkarDataRepository.getTitleForDhikr(dhikr)
                body = dhikr.text
                val bigBody = "${dhikr.text}\n\n📖 المصدر: ${dhikr.source}${if (dhikr.count > 1) " • التكرار: ${dhikr.count} مرات" else ""}"
                builder.setStyle(NotificationCompat.BigTextStyle().bigText(bigBody))
                openAppIntent.putExtra("target_screen", "azkar")
                openAppIntent.putExtra("route", "/azkar")
                openAppIntent.putExtra("category", dhikr.category)
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
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(false)

        if (reminder.type != ReminderItem.TYPE_AZKAR_PERIODIC) {
            builder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
        }

        // Rotating slots for periodic azkar so status bar shows recent ones and plays sound reliably
        val notificationId = if (reminder.type == ReminderItem.TYPE_AZKAR_PERIODIC) {
            val azkarSlot = (System.currentTimeMillis() / (1000 * 60)) % 5
            NOTIFICATION_ID_BASE + 400 + azkarSlot.toInt()
        } else {
            NOTIFICATION_ID_BASE + Math.abs(reminder.id.hashCode() % 1000)
        }

        if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            NotificationManagerCompat.from(context).notify(notificationId, builder.build())
            Log.i(TAG, "📢 Notification posted successfully for [${reminder.id}]: $title")
        } else {
            Log.w(TAG, "Notification permission POST_NOTIFICATIONS not granted")
        }
    }
}
