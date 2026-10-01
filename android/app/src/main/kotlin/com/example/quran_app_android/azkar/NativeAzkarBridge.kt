package com.example.quran_app_android.azkar

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object NativeAzkarBridge {
    private const val TAG = "NativeAzkarBridge"
    private const val CHANNEL = "native_azkar_bridge"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveSettings" -> {
                        try {
                            val enabled = call.argument<Boolean>("enabled") ?: true
                            val interval = call.argument<Int>("interval") ?: 60
                            val fromHour = call.argument<Int>("fromHour") ?: 8
                            val fromMin = call.argument<Int>("fromMin") ?: 0
                            val toHour = call.argument<Int>("toHour") ?: 22
                            val toMin = call.argument<Int>("toMin") ?: 0
                            val quietPrayer = call.argument<Boolean>("quietPrayer") ?: true
                            val categoriesList = call.argument<List<String>>("categories")
                            val categories = categoriesList?.toSet() ?: setOf("morning_evening", "quranic", "prophetic", "tasbeeh", "istighfar", "general")
                            val sound = call.argument<Boolean>("sound") ?: true
                            val vibration = call.argument<Boolean>("vibration") ?: true

                            val settings = AzkarNativeSettings(
                                enabled = enabled,
                                intervalMinutes = interval,
                                activeFromHour = fromHour,
                                activeFromMinute = fromMin,
                                activeToHour = toHour,
                                activeToMinute = toMin,
                                quietPrayerWindow = quietPrayer,
                                selectedCategories = categories,
                                soundEnabled = sound,
                                vibrationEnabled = vibration
                            )

                            AzkarSettingsManager.saveSettings(context, settings)
                            if (enabled) {
                                AzkarScheduler.scheduleNext(context)
                            } else {
                                AzkarScheduler.cancel(context)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving settings: ${e.message}", e)
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }

                    "getSettings" -> {
                        try {
                            val s = AzkarSettingsManager.getSettings(context)
                            val map = mapOf(
                                "enabled" to s.enabled,
                                "interval" to s.intervalMinutes,
                                "fromHour" to s.activeFromHour,
                                "fromMin" to s.activeFromMinute,
                                "toHour" to s.activeToHour,
                                "toMin" to s.activeToMinute,
                                "quietPrayer" to s.quietPrayerWindow,
                                "categories" to s.selectedCategories.toList(),
                                "sound" to s.soundEnabled,
                                "vibration" to s.vibrationEnabled
                            )
                            result.success(map)
                        } catch (e: Exception) {
                            result.error("GET_FAILED", e.message, null)
                        }
                    }

                    "reschedule" -> {
                        AzkarScheduler.scheduleNext(context)
                        result.success(true)
                    }

                    "cancelAzkar" -> {
                        AzkarScheduler.cancel(context)
                        result.success(true)
                    }

                    "testNotification" -> {
                        val testIntent = Intent(context, AzkarReceiver::class.java).apply {
                            action = AzkarReceiver.ACTION_TEST_AZKAR
                        }
                        context.sendBroadcast(testIntent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
