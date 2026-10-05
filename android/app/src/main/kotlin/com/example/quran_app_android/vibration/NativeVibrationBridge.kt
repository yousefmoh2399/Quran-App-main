package com.example.quran_app_android.vibration

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object NativeVibrationBridge {
    private const val CHANNEL = "com.taqarrab.quran/vibration"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val vibrator = getVibrator(context)
                if (vibrator == null || !vibrator.hasVibrator()) {
                    result.success(false)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "vibrate" -> {
                        val duration = (call.argument<Number>("duration")?.toLong()) ?: 350L
                        vibrateOnce(vibrator, duration)
                        result.success(true)
                    }
                    "vibratePattern" -> {
                        val patternList = call.argument<List<Number>>("pattern")
                        val repeat = (call.argument<Number>("repeat")?.toInt()) ?: -1
                        if (patternList != null && patternList.isNotEmpty()) {
                            val pattern = patternList.map { it.toLong() }.toLongArray()
                            vibratePattern(vibrator, pattern, repeat)
                            result.success(true)
                        } else {
                            vibrateOnce(vibrator, 350L)
                            result.success(true)
                        }
                    }
                    "cancel" -> {
                        vibrator.cancel()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getVibrator(context: Context): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager =
                    context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun vibrateOnce(vibrator: Vibrator, duration: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(
                        duration.coerceAtLeast(10L),
                        VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(duration.coerceAtLeast(10L))
            }
        } catch (e: Exception) {
            // Ignored
        }
    }

    private fun vibratePattern(vibrator: Vibrator, pattern: LongArray, repeat: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, repeat))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, repeat)
            }
        } catch (e: Exception) {
            // Ignored
        }
    }
}
