package com.example.quran_app_android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.quran_app_android.permissions.PermissionsBridge
import com.example.quran_app_android.adhan.NativeAdhanBridge
import com.example.quran_app_android.azkar.NativeAzkarBridge

import com.example.quran_app_android.adhan.PrayerScheduler
import com.example.quran_app_android.adhan.NativePrayerManager
import com.example.quran_app_android.vibration.NativeVibrationBridge

class MainActivity : FlutterActivity() {

    companion object {
        const val NAV_CHANNEL = "com.taqarrab.quran/app_navigation"
    }

    private var navChannel: MethodChannel? = null
    private var initialNavData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractNavData(intent)?.let {
            initialNavData = it
        }
        createAdhanNotificationChannel()
        Thread {
            try {
                if (NativePrayerManager.hasValidLocation(this)) {
                    PrayerScheduler.scheduleRollingWindow(this)
                }
                com.example.quran_app_android.widgets.WidgetUpdateManager.updateAll(this)
                com.example.quran_app_android.reminders.ReminderChannels.createChannels(this)
                com.example.quran_app_android.reminders.UnifiedReminderScheduler.scheduleNext(this)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Background startup tasks error", e)
            }
        }.start()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractNavData(intent)?.let { navData ->
            navChannel?.invokeMethod("onNavigationIntent", navData)
        }
    }

    private fun extractNavData(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val extras = intent.extras ?: return null

        val targetScreen = extras.getString("target_screen")
        val route = extras.getString("route")

        if (targetScreen == null && route == null && !extras.containsKey("open_page")) {
            return null
        }

        val map = mutableMapOf<String, Any?>()
        targetScreen?.let { map["target_screen"] = it }
        route?.let { map["route"] = it }
        if (extras.containsKey("open_page")) {
            map["open_page"] = extras.getInt("open_page")
        }
        if (extras.containsKey("commute_mode")) {
            map["commute_mode"] = extras.getBoolean("commute_mode")
        }
        if (extras.containsKey("target_pages")) {
            map["target_pages"] = extras.getInt("target_pages")
        }
        if (extras.containsKey("slot_id")) {
            map["slot_id"] = extras.getString("slot_id")
        }
        if (extras.containsKey("count_towards_main")) {
            map["count_towards_main"] = extras.getBoolean("count_towards_main")
        }
        if (extras.containsKey("page")) {
            map["page"] = extras.getInt("page")
        }
        if (extras.containsKey("category")) {
            map["category"] = extras.getString("category")
        }
        return map
    }

    private fun createAdhanNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "adhan_channel"
            val channel = NotificationChannel(
                channelId,
                "الأذان والتنبيهات",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "قناة إشعارات وتنبيهات الأذان"
                setShowBadge(true)
            }
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        NativeAdhanBridge.register(flutterEngine, this)
        PermissionsBridge.register(flutterEngine, this)
        NativeAzkarBridge.register(flutterEngine, this)
        NativeVibrationBridge.register(flutterEngine, this)
        com.example.quran_app_android.reminders.NativeRemindersBridge.registerWith(flutterEngine.dartExecutor.binaryMessenger, this)
        com.example.quran_app_android.util.NativeUrlBridge.register(flutterEngine.dartExecutor.binaryMessenger, this)

        navChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NAV_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialNavigation" -> {
                        val data = initialNavData
                        initialNavData = null
                        result.success(data)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        super.configureFlutterEngine(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        navChannel?.setMethodCallHandler(null)
        navChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
