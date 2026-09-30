

package com.example.quran_app_android

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader

open class MyHomeWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        super.onUpdate(context, manager, ids)
        Log.i("MyHomeWidget", "🔁 تم تحديث الويدجت يدويًا")

        for (id in ids) updateWidget(context, manager, id)

        scheduleNextUpdate(context) // إعادة الجدولة
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_WIDGET) {
            Log.i("MyHomeWidget", "⏰ تم تشغيل التحديث التلقائي")
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(Intent(context, MyHomeWidget::class.java).component)
            for (id in ids) updateWidget(context, manager, id)
            scheduleNextUpdate(context)
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.my_home_widget)
        val azkar = loadAzkar(context)
        val zekr = if (azkar.isNotEmpty()) azkar.random() else "سبحان الله"
        views.setTextViewText(R.id.widget_text, zekr)
        manager.updateAppWidget(widgetId, views)
    }

    private fun loadAzkar(context: Context): List<String> {
        val list = mutableListOf<String>()
        try {
            val inputStream = context.assets.open("azkar.json")
            val reader = BufferedReader(InputStreamReader(inputStream, "UTF-8"))
            val json = JSONArray(reader.readText())
            reader.close()

            for (i in 0 until json.length()) {
                val obj = json.getJSONObject(i)
                val arr = obj.getJSONArray("array")
                for (j in 0 until arr.length()) {
                    list.add(arr.getJSONObject(j).getString("text"))
                }
            }
        } catch (e: Exception) {
            Log.e("MyHomeWidget", "❌ فشل تحميل الأذكار: ${e.message}")
        }
        return list
    }

    private fun scheduleNextUpdate(context: Context) {
        val intent = Intent(context, MyHomeWidget::class.java).apply {
            action = ACTION_REFRESH_WIDGET
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val interval = 5 * 60 * 1000L // كل 3 دقائق
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + interval,
            pendingIntent
        )
        Log.i("MyHomeWidget", "📅 تم جدولة التحديث القادم بعد 3 دقائق")
    }

    companion object {
        const val ACTION_REFRESH_WIDGET = "com.example.quran_app_android.REFRESH_WIDGET"
    }
}
