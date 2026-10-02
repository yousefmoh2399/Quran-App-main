package com.example.quran_app_android.adhan

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object NativeAdhanBridge : MethodChannel.MethodCallHandler {

    private const val CHANNEL_NAME = "native_adhan_bridge"
    private const val TAG = "NativeAdhanBridge"

    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    fun register(engine: FlutterEngine, context: Context) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        appContext = context.applicationContext
        Log.i(TAG, "Registered native_adhan_bridge MethodChannel successfully")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext ?: return result.error("NO_CONTEXT", "Application context is null", null)

        when (call.method) {
            "saveSettings" -> {
                val args = call.arguments as? Map<String, Any?>
                if (args == null) {
                    return result.error("INVALID_ARGS", "Expected Map<String, Any?>", null)
                }

                try {
                    val settings = AdhanSettings(
                        latitude = (args["latitude"] as? Number)?.toDouble() ?: 0.0,
                        longitude = (args["longitude"] as? Number)?.toDouble() ?: 0.0,
                        cityName = (args["cityName"] as? String) ?: "",
                        calculationMethod = (args["calculationMethod"] as? String) ?: "EGYPTIAN",
                        madhab = (args["madhab"] as? String) ?: "SHAFI",
                        highLatitudeRule = (args["highLatitudeRule"] as? String) ?: "MIDDLE_OF_THE_NIGHT",
                        timeZoneId = (args["timeZoneId"] as? String) ?: "",
                        fajrOffset = (args["fajrOffset"] as? Number)?.toInt() ?: 0,
                        sunriseOffset = (args["sunriseOffset"] as? Number)?.toInt() ?: 0,
                        dhuhrOffset = (args["dhuhrOffset"] as? Number)?.toInt() ?: 0,
                        asrOffset = (args["asrOffset"] as? Number)?.toInt() ?: 0,
                        maghribOffset = (args["maghribOffset"] as? Number)?.toInt() ?: 0,
                        ishaOffset = (args["ishaOffset"] as? Number)?.toInt() ?: 0,
                        fajrEnabled = (args["fajrEnabled"] as? Boolean) ?: true,
                        dhuhrEnabled = (args["dhuhrEnabled"] as? Boolean) ?: true,
                        asrEnabled = (args["asrEnabled"] as? Boolean) ?: true,
                        maghribEnabled = (args["maghribEnabled"] as? Boolean) ?: true,
                        ishaEnabled = (args["ishaEnabled"] as? Boolean) ?: true,
                        fajrMode = (args["fajrMode"] as? String) ?: "adhan",
                        dhuhrMode = (args["dhuhrMode"] as? String) ?: "adhan",
                        asrMode = (args["asrMode"] as? String) ?: "adhan",
                        maghribMode = (args["maghribMode"] as? String) ?: "adhan",
                        ishaMode = (args["ishaMode"] as? String) ?: "adhan",
                        adhanSound = (args["adhanSound"] as? String) ?: "default"
                    )

                    NativePrayerManager.saveSettings(context, settings)
                    val scheduledCount = PrayerScheduler.scheduleRollingWindow(context)
                    result.success(mapOf("scheduledCount" to scheduledCount, "success" to true))
                } catch (e: Exception) {
                    Log.e(TAG, "Error in saveSettings: ${e.message}", e)
                    result.error("SAVE_SETTINGS_ERROR", e.message, null)
                }
            }

            "getSettings" -> {
                try {
                    val settings = NativePrayerManager.getSettings(context)
                    result.success(
                        mapOf(
                            "latitude" to settings.latitude,
                            "longitude" to settings.longitude,
                            "cityName" to settings.cityName,
                            "calculationMethod" to settings.calculationMethod,
                            "madhab" to settings.madhab,
                            "highLatitudeRule" to settings.highLatitudeRule,
                            "timeZoneId" to settings.timeZoneId,
                            "fajrOffset" to settings.fajrOffset,
                            "sunriseOffset" to settings.sunriseOffset,
                            "dhuhrOffset" to settings.dhuhrOffset,
                            "asrOffset" to settings.asrOffset,
                            "maghribOffset" to settings.maghribOffset,
                            "ishaOffset" to settings.ishaOffset,
                            "fajrEnabled" to settings.fajrEnabled,
                            "dhuhrEnabled" to settings.dhuhrEnabled,
                            "asrEnabled" to settings.asrEnabled,
                            "maghribEnabled" to settings.maghribEnabled,
                            "ishaEnabled" to settings.ishaEnabled,
                            "fajrMode" to settings.fajrMode,
                            "dhuhrMode" to settings.dhuhrMode,
                            "asrMode" to settings.asrMode,
                            "maghribMode" to settings.maghribMode,
                            "ishaMode" to settings.ishaMode,
                            "adhanSound" to settings.adhanSound
                        )
                    )
                } catch (e: Exception) {
                    result.error("GET_SETTINGS_ERROR", e.message, null)
                }
            }

            "getUpcomingPrayers" -> {
                try {
                    val prayers = PrayerScheduler.getUpcomingPrayersList(context)
                    result.success(prayers)
                } catch (e: Exception) {
                    result.error("GET_UPCOMING_ERROR", e.message, null)
                }
            }

            "scheduleTestAdhan" -> {
                val delaySeconds = (call.argument<Number>("delaySeconds"))?.toInt() ?: 10
                val prayerName = (call.argument<String>("prayerName")) ?: "الفجر"
                PrayerScheduler.scheduleTestAdhan(context, delaySeconds, prayerName)
                result.success(true)
            }

            "recalculateAndSchedule" -> {
                try {
                    val count = PrayerScheduler.scheduleRollingWindow(context)
                    result.success(count)
                } catch (e: Exception) {
                    result.error("SCHEDULE_ERROR", e.message, null)
                }
            }

            "hasLocation" -> {
                result.success(NativePrayerManager.hasValidLocation(context))
            }

            // Legacy compatibility
            "schedulePrayerTimes", "scheduleDailyReset" -> {
                val count = PrayerScheduler.scheduleRollingWindow(context)
                result.success(true)
            }

            "saveLocation" -> {
                val args = call.arguments as? Map<String, Double>
                val lat = args?.get("lat") ?: 0.0
                val lng = args?.get("lng") ?: 0.0
                val current = NativePrayerManager.getSettings(context)
                NativePrayerManager.saveSettings(context, current.copy(latitude = lat, longitude = lng))
                PrayerScheduler.scheduleRollingWindow(context)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }
}
