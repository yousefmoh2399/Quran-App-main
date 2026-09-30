package com.example.quran_app_android.reminders

import org.json.JSONObject

/**
 * Represents a single unified reminder item in the native reminders engine.
 */
data class ReminderItem(
    val id: String,
    val type: String, // "wird_daily", "wird_commute", "sadaqah_monthly", "azkar_periodic"
    val scheduleJson: String,
    val payloadJson: String,
    val enabled: Boolean,
    val lastTriggered: Long = 0L
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "type" to type,
            "schedule_json" to scheduleJson,
            "payload_json" to payloadJson,
            "enabled" to if (enabled) 1 else 0,
            "last_triggered" to lastTriggered
        )
    }

    companion object {
        const val TYPE_WIRD_DAILY = "wird_daily"
        const val TYPE_WIRD_COMMUTE = "wird_commute"
        const val TYPE_SADAQAH_MONTHLY = "sadaqah_monthly"
        const val TYPE_AZKAR_PERIODIC = "azkar_periodic"

        fun fromMap(map: Map<String, Any?>): ReminderItem {
            val enabledVal = map["enabled"]
            val isEnabled = when (enabledVal) {
                is Boolean -> enabledVal
                is Number -> enabledVal.toInt() == 1
                else -> true
            }
            return ReminderItem(
                id = map["id"] as? String ?: "",
                type = map["type"] as? String ?: TYPE_WIRD_DAILY,
                scheduleJson = map["schedule_json"] as? String ?: "{}",
                payloadJson = map["payload_json"] as? String ?: "{}",
                enabled = isEnabled,
                lastTriggered = (map["last_triggered"] as? Number)?.toLong() ?: 0L
            )
        }
    }
}
