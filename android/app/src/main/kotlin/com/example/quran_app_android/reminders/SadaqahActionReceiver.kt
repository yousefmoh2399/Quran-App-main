package com.example.quran_app_android.reminders

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SadaqahActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SadaqahActionReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == UnifiedReminderReceiver.ACTION_SADAQAH_DONATED) {
            val notificationId = intent.getIntExtra("notification_id", -1)
            Log.i(TAG, "🤲 'تصدّقت' action tapped! Notification ID: $notificationId")

            try {
                // 1. Dismiss notification
                if (notificationId != -1) {
                    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.cancel(notificationId)
                }

                // 2. Mark this month as completed in SharedPreferences
                val now = System.currentTimeMillis()
                val monthKey = SimpleDateFormat("yyyy-MM", Locale.US).format(Date(now))
                val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))

                val prefs = context.getSharedPreferences(ReminderCancellationChecker.PREFS_SADAQAH, Context.MODE_PRIVATE)
                prefs.edit()
                    .putBoolean("sadaqah_donated_$monthKey", true)
                    .putString("sadaqah_last_donated_date", todayStr)
                    .apply()

                // 3. Insert record in local SQLite database
                val dbHelper = RemindersDbHelper.getInstance(context)
                dbHelper.addSadaqahLog(
                    date = todayStr,
                    amount = null,
                    note = "سُجّلت بنقرة واحدة من الإشعار"
                )

                // 4. Show brief Toast message
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(
                        context.applicationContext,
                        "تقبّل الله طاعتكم وبارك في رزقكم 🤲",
                        Toast.LENGTH_LONG
                    ).show()
                }

                // 5. Re-schedule unified reminders engine
                UnifiedReminderScheduler.scheduleNext(context)

            } catch (e: Exception) {
                Log.e(TAG, "Error processing sadaqah donated action: ${e.message}", e)
            }
        }
    }
}
