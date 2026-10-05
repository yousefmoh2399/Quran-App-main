package com.example.quran_app_android.util

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object NativeUrlBridge : MethodChannel.MethodCallHandler {
    private const val CHANNEL = "com.taqarrab.quran/url_launcher"
    private var activity: Activity? = null

    fun register(messenger: BinaryMessenger, activity: Activity) {
        this.activity = activity
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }

        when (call.method) {
            "launchUrl" -> {
                val urlString = call.argument<String>("url") ?: run {
                    result.error("INVALID_URL", "URL string cannot be null", null)
                    return
                }
                val packageName = call.argument<String>("packageName")
                try {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(urlString)).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        if (!packageName.isNullOrEmpty()) {
                            setPackage(packageName)
                        }
                    }
                    act.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    if (!packageName.isNullOrEmpty()) {
                        try {
                            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(urlString)).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            act.startActivity(fallbackIntent)
                            result.success(true)
                            return
                        } catch (_: Exception) {}
                    }
                    result.success(false)
                }
            }
            "canLaunchUrl" -> {
                val urlString = call.argument<String>("url") ?: run {
                    result.success(false)
                    return
                }
                try {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(urlString))
                    val activities = act.packageManager.queryIntentActivities(intent, 0)
                    result.success(activities.isNotEmpty())
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }
}
