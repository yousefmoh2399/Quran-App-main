package com.example.quran_app_android.azkar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.quran_app_android.R
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.InputStreamReader
import kotlin.random.Random

class AzkarReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            Log.i("AzkarReceiver", "📿 Received scheduled Azkar trigger")

            // ✅ قراءة ملف الأذكار من مجلد assets
            val inputStream = context.assets.open("azkar.json")
            val reader = InputStreamReader(inputStream, "UTF-8")

            val type = object : TypeToken<List<Map<String, Any>>>() {}.type
            val azkarList: List<Map<String, Any>> = Gson().fromJson(reader, type)

            // ✅ اختيار ذكر عشوائي من أي فئة
            val category = azkarList[Random.nextInt(azkarList.size)]
            val array = category["array"] as List<Map<String, Any>>
            val randomZikr = array[Random.nextInt(array.size)]
            val zikrText = randomZikr["text"] as String

            reader.close()
            inputStream.close()

            // ✅ إرسال إشعار نظام قياسي (بدون نافذة عائمة ولا SYSTEM_ALERT_WINDOW)
            val channelId = "azkar_channel"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "الأذكار اليومية",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "تنبيهات الأذكار والتسبيح اليومية"
                }
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.createNotificationChannel(channel)
            }

            val notification = NotificationCompat.Builder(context, channelId)
                .setContentTitle("📿 ذكر وتذكير")
                .setContentText(zikrText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(zikrText))
                .setSmallIcon(R.drawable.ic_mosque)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()

            val notificationManager = NotificationManagerCompat.from(context)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ActivityCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                notificationManager.notify(Random.nextInt(1000, 9999), notification)
                Log.i("AzkarReceiver", "✅ تم عرض إشعار الذكر بنجاح")
            } else {
                Log.w("AzkarReceiver", "⚠️ تم إلغاء عرض الإشعار لعدم منح إذن POST_NOTIFICATIONS")
            }

        } catch (e: Exception) {
            Log.e("AzkarReceiver", "❌ Error showing Azkar: ${e.message}")
            e.printStackTrace()
        }
    }
}
