package com.example.quran_app_android.reminders

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NativeRemindersBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "NativeRemindersBridge"
        private const val CHANNEL = "com.example.quran_app/native_reminders"

        fun registerWith(messenger: BinaryMessenger, context: Context): MethodChannel {
            val channel = MethodChannel(messenger, CHANNEL)
            val handler = NativeRemindersBridge(context)
            channel.setMethodCallHandler(handler)
            return channel
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val dbHelper = RemindersDbHelper.getInstance(context)

        when (call.method) {
            "getAllReminders" -> {
                try {
                    val list = dbHelper.getAllReminders().map { it.toMap() }
                    result.success(list)
                } catch (e: Exception) {
                    result.error("DB_ERROR", e.message, null)
                }
            }

            "getReminder" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                val item = dbHelper.getReminder(id)
                result.success(item?.toMap())
            }

            "saveReminder" -> {
                try {
                    val map = call.argument<Map<String, Any?>>("reminder")
                    if (map == null) {
                        result.error("INVALID_ARGS", "Missing reminder data", null)
                        return
                    }
                    val item = ReminderItem.fromMap(map)
                    dbHelper.saveReminder(item)
                    UnifiedReminderScheduler.scheduleNext(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SAVE_ERROR", e.message, null)
                }
            }

            "toggleReminder" -> {
                val id = call.argument<String>("id")
                val enabled = call.argument<Boolean>("enabled") ?: true
                if (id == null) {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                dbHelper.setReminderEnabled(id, enabled)
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(true)
            }

            "deleteReminder" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                val deleted = dbHelper.deleteReminder(id)
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(deleted)
            }

            "rescheduleAll" -> {
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(true)
            }

            "testTriggerReminder" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                val intent = Intent(context, UnifiedReminderReceiver::class.java).apply {
                    action = UnifiedReminderScheduler.ACTION_UNIFIED_ALARM
                    putExtra(UnifiedReminderScheduler.EXTRA_REMINDER_ID, id)
                }
                context.sendBroadcast(intent)
                result.success(true)
            }

            "getUpcomingAlarms" -> {
                try {
                    val now = System.currentTimeMillis()
                    val enabled = dbHelper.getEnabledReminders()
                    val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US)

                    val list = enabled.map { item ->
                        val nextTime = UnifiedReminderScheduler.calculateNextTriggerTime(item, now)
                        val isCancelled = ReminderCancellationChecker.shouldCancel(context, item)
                        mapOf(
                            "id" to item.id,
                            "type" to item.type,
                            "next_trigger_millis" to nextTime,
                            "next_trigger_formatted" to dateFormat.format(Date(nextTime)),
                            "is_cancelled_by_condition" to isCancelled,
                            "channel" to ReminderChannels.getChannelIdForType(item.type)
                        )
                    }.sortedBy { it["next_trigger_millis"] as Long }

                    result.success(list)
                } catch (e: Exception) {
                    result.error("UPCOMING_ERROR", e.message, null)
                }
            }

            "markWirdCompleted" -> {
                val dateStr = call.argument<String>("date") ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val prefs = context.getSharedPreferences(ReminderCancellationChecker.PREFS_USER_PROGRESS, Context.MODE_PRIVATE)
                prefs.edit().putString(ReminderCancellationChecker.KEY_WIRD_LAST_COMPLETED_DATE, dateStr).apply()
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(true)
            }

            "markCommuteCompleted" -> {
                val slotId = call.argument<String>("slot_id") ?: "commute"
                val dateStr = call.argument<String>("date") ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val prefs = context.getSharedPreferences(ReminderCancellationChecker.PREFS_USER_PROGRESS, Context.MODE_PRIVATE)
                prefs.edit().putBoolean("commute_done_${slotId}_$dateStr", true).apply()
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(true)
            }

            "markSadaqahDonated" -> {
                val dateStr = call.argument<String>("date") ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
                val amount = call.argument<Double>("amount")
                val note = call.argument<String>("note")

                val now = System.currentTimeMillis()
                val monthKey = SimpleDateFormat("yyyy-MM", Locale.US).format(Date(now))
                val prefs = context.getSharedPreferences(ReminderCancellationChecker.PREFS_SADAQAH, Context.MODE_PRIVATE)
                prefs.edit().putBoolean("sadaqah_donated_$monthKey", true).apply()

                dbHelper.addSadaqahLog(dateStr, amount, note)
                UnifiedReminderScheduler.scheduleNext(context)
                result.success(true)
            }

            "getSadaqahLogs" -> {
                try {
                    val logs = dbHelper.getSadaqahLogs()
                    result.success(logs)
                } catch (e: Exception) {
                    result.error("LOG_ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}
