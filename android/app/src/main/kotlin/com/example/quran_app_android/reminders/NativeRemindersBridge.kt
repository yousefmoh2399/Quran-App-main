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
        private const val CHANNEL = "com.taqarrab.quran/native_reminders"

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
                            "channel" to ReminderChannels.getChannelIdForType(context, item.type)
                        )
                    }.sortedBy { it["next_trigger_millis"] as Long }

                    result.success(list)
                } catch (e: Exception) {
                    result.error("UPCOMING_ERROR", e.message, null)
                }
            }

            "previewSound" -> {
                try {
                    val soundKey = call.argument<String>("soundKey") ?: "system_default"
                    SoundPlayerHelper.play(context, soundKey)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PLAY_ERROR", e.message, null)
                }
            }

            "stopSound" -> {
                try {
                    SoundPlayerHelper.stop()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STOP_ERROR", e.message, null)
                }
            }

            "saveSoundSettings" -> {
                try {
                    val mode = call.argument<String>("mode") ?: "custom"
                    val unifiedSound = call.argument<String>("unifiedSound") ?: "fazakkir"
                    val wirdSound = call.argument<String>("wirdSound") ?: "fazakkir"
                    val commuteSound = call.argument<String>("commuteSound") ?: "fazakkir"
                    val sadaqahSound = call.argument<String>("sadaqahSound") ?: "azkar_2"
                    val azkarSound = call.argument<String>("azkarSound") ?: "azkar_1"

                    val prefs = context.getSharedPreferences(ReminderChannels.PREFS_SOUNDS, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString(ReminderChannels.KEY_MODE, mode)
                        .putString(ReminderChannels.KEY_UNIFIED_SOUND, unifiedSound)
                        .putString(ReminderChannels.KEY_WIRD_SOUND, wirdSound)
                        .putString(ReminderChannels.KEY_COMMUTE_SOUND, commuteSound)
                        .putString(ReminderChannels.KEY_SADAQAH_SOUND, sadaqahSound)
                        .putString(ReminderChannels.KEY_AZKAR_SOUND, azkarSound)
                        .apply()

                    ReminderChannels.createChannels(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SAVE_SOUNDS_ERROR", e.message, null)
                }
            }

            "getSoundSettings" -> {
                try {
                    val prefs = context.getSharedPreferences(ReminderChannels.PREFS_SOUNDS, Context.MODE_PRIVATE)
                    val map = mapOf(
                        "mode" to (prefs.getString(ReminderChannels.KEY_MODE, "custom") ?: "custom"),
                        "unifiedSound" to (prefs.getString(ReminderChannels.KEY_UNIFIED_SOUND, "fazakkir") ?: "fazakkir"),
                        "wirdSound" to (prefs.getString(ReminderChannels.KEY_WIRD_SOUND, "fazakkir") ?: "fazakkir"),
                        "commuteSound" to (prefs.getString(ReminderChannels.KEY_COMMUTE_SOUND, "fazakkir") ?: "fazakkir"),
                        "sadaqahSound" to (prefs.getString(ReminderChannels.KEY_SADAQAH_SOUND, "azkar_2") ?: "azkar_2"),
                        "azkarSound" to (prefs.getString(ReminderChannels.KEY_AZKAR_SOUND, "azkar_1") ?: "azkar_1")
                    )
                    result.success(map)
                } catch (e: Exception) {
                    result.error("GET_SOUNDS_ERROR", e.message, null)
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

    object SoundPlayerHelper {
        private var mediaPlayer: android.media.MediaPlayer? = null

        fun play(context: Context, soundKey: String) {
            stop()
            try {
                val uri = ReminderChannels.getSoundUri(context, soundKey) ?: return
                mediaPlayer = android.media.MediaPlayer().apply {
                    setDataSource(context, uri)
                    setAudioAttributes(
                        android.media.AudioAttributes.Builder()
                            .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                            .build()
                    )
                    prepare()
                    start()
                    setOnCompletionListener {
                        stop()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error playing sound: $soundKey", e)
            }
        }

        fun stop() {
            try {
                mediaPlayer?.let {
                    if (it.isPlaying) {
                        it.stop()
                    }
                    it.release()
                }
            } catch (e: Exception) {
                // ignore
            } finally {
                mediaPlayer = null
            }
        }
    }
}
