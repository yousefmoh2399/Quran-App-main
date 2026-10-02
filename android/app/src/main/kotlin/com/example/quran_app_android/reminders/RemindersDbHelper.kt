package com.example.quran_app_android.reminders

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class RemindersDbHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val TAG = "RemindersDbHelper"
        const val DATABASE_NAME = "native_reminders.db"
        const val DATABASE_VERSION = 1

        const val TABLE_REMINDERS = "reminders"
        const val COL_ID = "id"
        const val COL_TYPE = "type"
        const val COL_SCHEDULE_JSON = "schedule_json"
        const val COL_PAYLOAD_JSON = "payload_json"
        const val COL_ENABLED = "enabled"
        const val COL_LAST_TRIGGERED = "last_triggered"

        const val TABLE_SADAQAH_LOG = "sadaqah_log"
        const val COL_SADAQAH_ID = "id"
        const val COL_SADAQAH_DATE = "date"
        const val COL_SADAQAH_AMOUNT = "amount"
        const val COL_SADAQAH_NOTE = "note"
        const val COL_SADAQAH_CREATED_AT = "created_at"

        @Volatile
        private var instance: RemindersDbHelper? = null

        fun getInstance(context: Context): RemindersDbHelper {
            return instance ?: synchronized(this) {
                instance ?: RemindersDbHelper(context.applicationContext).also { instance = it }
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_REMINDERS (
                $COL_ID TEXT PRIMARY KEY,
                $COL_TYPE TEXT NOT NULL,
                $COL_SCHEDULE_JSON TEXT NOT NULL,
                $COL_PAYLOAD_JSON TEXT NOT NULL,
                $COL_ENABLED INTEGER NOT NULL DEFAULT 1,
                $COL_LAST_TRIGGERED INTEGER NOT NULL DEFAULT 0
            )
        """.trimIndent())

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_SADAQAH_LOG (
                $COL_SADAQAH_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COL_SADAQAH_DATE TEXT NOT NULL,
                $COL_SADAQAH_AMOUNT REAL,
                $COL_SADAQAH_NOTE TEXT,
                $COL_SADAQAH_CREATED_AT INTEGER NOT NULL
            )
        """.trimIndent())

        Log.i(TAG, "Native reminders database created")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Future migrations if schema changes
    }

    fun getAllReminders(): List<ReminderItem> {
        val list = mutableListOf<ReminderItem>()
        val db = readableDatabase
        val cursor = db.query(TABLE_REMINDERS, null, null, null, null, null, null)
        cursor.use {
            while (it.moveToNext()) {
                val item = ReminderItem(
                    id = it.getString(it.getColumnIndexOrThrow(COL_ID)),
                    type = it.getString(it.getColumnIndexOrThrow(COL_TYPE)),
                    scheduleJson = it.getString(it.getColumnIndexOrThrow(COL_SCHEDULE_JSON)),
                    payloadJson = it.getString(it.getColumnIndexOrThrow(COL_PAYLOAD_JSON)),
                    enabled = it.getInt(it.getColumnIndexOrThrow(COL_ENABLED)) == 1,
                    lastTriggered = it.getLong(it.getColumnIndexOrThrow(COL_LAST_TRIGGERED))
                )
                list.add(item)
            }
        }
        return list
    }

    fun getEnabledReminders(): List<ReminderItem> {
        val list = mutableListOf<ReminderItem>()
        val db = readableDatabase
        val cursor = db.query(
            TABLE_REMINDERS,
            null,
            "$COL_ENABLED = 1",
            null,
            null,
            null,
            null
        )
        cursor.use {
            while (it.moveToNext()) {
                val item = ReminderItem(
                    id = it.getString(it.getColumnIndexOrThrow(COL_ID)),
                    type = it.getString(it.getColumnIndexOrThrow(COL_TYPE)),
                    scheduleJson = it.getString(it.getColumnIndexOrThrow(COL_SCHEDULE_JSON)),
                    payloadJson = it.getString(it.getColumnIndexOrThrow(COL_PAYLOAD_JSON)),
                    enabled = true,
                    lastTriggered = it.getLong(it.getColumnIndexOrThrow(COL_LAST_TRIGGERED))
                )
                list.add(item)
            }
        }
        return list
    }

    fun getReminder(id: String): ReminderItem? {
        val db = readableDatabase
        val cursor = db.query(
            TABLE_REMINDERS,
            null,
            "$COL_ID = ?",
            arrayOf(id),
            null,
            null,
            null
        )
        cursor.use {
            if (it.moveToFirst()) {
                return ReminderItem(
                    id = it.getString(it.getColumnIndexOrThrow(COL_ID)),
                    type = it.getString(it.getColumnIndexOrThrow(COL_TYPE)),
                    scheduleJson = it.getString(it.getColumnIndexOrThrow(COL_SCHEDULE_JSON)),
                    payloadJson = it.getString(it.getColumnIndexOrThrow(COL_PAYLOAD_JSON)),
                    enabled = it.getInt(it.getColumnIndexOrThrow(COL_ENABLED)) == 1,
                    lastTriggered = it.getLong(it.getColumnIndexOrThrow(COL_LAST_TRIGGERED))
                )
            }
        }
        return null
    }

    fun saveReminder(item: ReminderItem) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_ID, item.id)
            put(COL_TYPE, item.type)
            put(COL_SCHEDULE_JSON, item.scheduleJson)
            put(COL_PAYLOAD_JSON, item.payloadJson)
            put(COL_ENABLED, if (item.enabled) 1 else 0)
            put(COL_LAST_TRIGGERED, item.lastTriggered)
        }
        db.insertWithOnConflict(TABLE_REMINDERS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun setReminderEnabled(id: String, enabled: Boolean) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_ENABLED, if (enabled) 1 else 0)
        }
        db.update(TABLE_REMINDERS, values, "$COL_ID = ?", arrayOf(id))
    }

    fun updateLastTriggered(id: String, timestamp: Long) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_LAST_TRIGGERED, timestamp)
        }
        db.update(TABLE_REMINDERS, values, "$COL_ID = ?", arrayOf(id))
    }

    fun deleteReminder(id: String): Boolean {
        val db = writableDatabase
        return db.delete(TABLE_REMINDERS, "$COL_ID = ?", arrayOf(id)) > 0
    }

    // Sadaqah Log Operations
    fun addSadaqahLog(date: String, amount: Double?, note: String?): Long {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_SADAQAH_DATE, date)
            if (amount != null) put(COL_SADAQAH_AMOUNT, amount) else putNull(COL_SADAQAH_AMOUNT)
            if (note != null) put(COL_SADAQAH_NOTE, note) else putNull(COL_SADAQAH_NOTE)
            put(COL_SADAQAH_CREATED_AT, System.currentTimeMillis())
        }
        return db.insert(TABLE_SADAQAH_LOG, null, values)
    }

    fun getSadaqahLogs(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        val db = readableDatabase
        val cursor = db.query(TABLE_SADAQAH_LOG, null, null, null, null, null, "$COL_SADAQAH_CREATED_AT DESC")
        cursor.use {
            while (it.moveToNext()) {
                val map = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(COL_SADAQAH_ID)),
                    "date" to it.getString(it.getColumnIndexOrThrow(COL_SADAQAH_DATE)),
                    "amount" to if (it.isNull(it.getColumnIndexOrThrow(COL_SADAQAH_AMOUNT))) null else it.getDouble(it.getColumnIndexOrThrow(COL_SADAQAH_AMOUNT)),
                    "note" to it.getString(it.getColumnIndexOrThrow(COL_SADAQAH_NOTE)),
                    "created_at" to it.getLong(it.getColumnIndexOrThrow(COL_SADAQAH_CREATED_AT))
                )
                list.add(map)
            }
        }
        return list
    }
}
