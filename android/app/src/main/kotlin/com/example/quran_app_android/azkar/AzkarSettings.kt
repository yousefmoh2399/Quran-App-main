package com.example.quran_app_android.azkar

import android.content.Context
import android.content.SharedPreferences

data class AzkarNativeSettings(
    val enabled: Boolean = true,
    val intervalMinutes: Int = 60,
    val activeFromHour: Int = 8,
    val activeFromMinute: Int = 0,
    val activeToHour: Int = 22,
    val activeToMinute: Int = 0,
    val quietPrayerWindow: Boolean = true,
    val selectedCategories: Set<String> = setOf("morning_evening", "quranic", "prophetic", "tasbeeh", "istighfar", "general"),
    val soundEnabled: Boolean = true,
    val vibrationEnabled: Boolean = true
)

object AzkarSettingsManager {
    private const val PREFS_NAME = "azkar_native_settings"

    private const val KEY_ENABLED = "azkar_enabled"
    private const val KEY_INTERVAL = "azkar_interval_minutes"
    private const val KEY_FROM_HOUR = "azkar_from_hour"
    private const val KEY_FROM_MIN = "azkar_from_min"
    private const val KEY_TO_HOUR = "azkar_to_hour"
    private const val KEY_TO_MIN = "azkar_to_min"
    private const val KEY_QUIET_PRAYER = "azkar_quiet_prayer_window"
    private const val KEY_CATEGORIES = "azkar_selected_categories"
    private const val KEY_SOUND = "azkar_sound_enabled"
    private const val KEY_VIBRATION = "azkar_vibration_enabled"

    fun getSettings(context: Context): AzkarNativeSettings {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val defaultCategories = setOf("morning_evening", "quranic", "prophetic", "tasbeeh", "istighfar", "general")
        return AzkarNativeSettings(
            enabled = prefs.getBoolean(KEY_ENABLED, true),
            intervalMinutes = prefs.getInt(KEY_INTERVAL, 60),
            activeFromHour = prefs.getInt(KEY_FROM_HOUR, 8),
            activeFromMinute = prefs.getInt(KEY_FROM_MIN, 0),
            activeToHour = prefs.getInt(KEY_TO_HOUR, 22),
            activeToMinute = prefs.getInt(KEY_TO_MIN, 0),
            quietPrayerWindow = prefs.getBoolean(KEY_QUIET_PRAYER, true),
            selectedCategories = prefs.getStringSet(KEY_CATEGORIES, defaultCategories) ?: defaultCategories,
            soundEnabled = prefs.getBoolean(KEY_SOUND, true),
            vibrationEnabled = prefs.getBoolean(KEY_VIBRATION, true)
        )
    }

    fun saveSettings(context: Context, settings: AzkarNativeSettings) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_ENABLED, settings.enabled)
            .putInt(KEY_INTERVAL, settings.intervalMinutes)
            .putInt(KEY_FROM_HOUR, settings.activeFromHour)
            .putInt(KEY_FROM_MIN, settings.activeFromMinute)
            .putInt(KEY_TO_HOUR, settings.activeToHour)
            .putInt(KEY_TO_MIN, settings.activeToMinute)
            .putBoolean(KEY_QUIET_PRAYER, settings.quietPrayerWindow)
            .putStringSet(KEY_CATEGORIES, settings.selectedCategories)
            .putBoolean(KEY_SOUND, settings.soundEnabled)
            .putBoolean(KEY_VIBRATION, settings.vibrationEnabled)
            .apply()
    }
}
