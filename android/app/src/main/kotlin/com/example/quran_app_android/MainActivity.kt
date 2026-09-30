package com.example.quran_app_android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.quran_app_android.permissions.PermissionsBridge
import com.example.quran_app_android.adhan.NativeAdhanBridge
import com.example.quran_app_android.azkar.NativeAzkarBridge

import com.example.quran_app_android.adhan.PrayerScheduler
import com.example.quran_app_android.adhan.NativePrayerManager

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAdhanNotificationChannel()
        if (NativePrayerManager.hasValidLocation(this)) {
            PrayerScheduler.scheduleRollingWindow(this)
        }
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
        super.configureFlutterEngine(flutterEngine)
    }
}
