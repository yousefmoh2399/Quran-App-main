package com.example.quran_app_android.adhan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.quran_app_android.R

class AdhanService : Service(), AudioManager.OnAudioFocusChangeListener {

    companion object {
        const val ACTION_START_ADHAN = "START_ADHAN"
        const val ACTION_STOP_ADHAN = "STOP_ADHAN"
        const val ACTION_PRAYED = "PRAYED"
        const val ACTION_ADHAN_COMPLETED = "com.example.quran_app_android.ADHAN_COMPLETED"
        const val ACTION_ADHAN_SILENCED = "com.example.quran_app_android.ADHAN_SILENCED"
        const val CHANNEL_ID = "adhan_playback_channel"
        private const val NOTIFICATION_ID = 1001
        private const val TAG = "AdhanService"
    }

    private var player: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
        Log.i(TAG, "AdhanService created")
    }

    private var currentPrayerKey: String = "fajr"
    private var currentPrayerName: String = "الصلاة"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_ADHAN

        when (action) {
            ACTION_STOP_ADHAN -> {
                Log.i(TAG, "Stop adhan action received")
                stopPlayback()
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PRAYED -> {
                Log.i(TAG, "Prayed action received from notification button")
                val key = intent?.getStringExtra("prayer_key") ?: currentPrayerKey
                val name = intent?.getStringExtra("prayer_name") ?: currentPrayerName
                recordPrayerCompleted(key, name)
                stopPlayback()
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START_ADHAN -> {
                val prayerKey = intent?.getStringExtra("prayer_key") ?: "fajr"
                val prayerName = intent?.getStringExtra("prayer_name") ?: "الصلاة"
                currentPrayerKey = prayerKey
                currentPrayerName = prayerName
                val adhanSound = intent?.getStringExtra("adhan_sound") ?: "default"
                val cityName = intent?.getStringExtra("city_name") ?: ""
                val scheduledMillis = intent?.getLongExtra("scheduled_millis", System.currentTimeMillis()) ?: System.currentTimeMillis()

                val notification = buildForegroundNotification(prayerKey, prayerName, cityName, scheduledMillis)
                startForeground(NOTIFICATION_ID, notification)

                requestAudioFocusAndPlay(adhanSound)
                return START_NOT_STICKY
            }
            else -> return START_NOT_STICKY
        }
    }

    private fun requestAudioFocusAndPlay(adhanSound: String) {
        val am = audioManager ?: return

        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setUsage(AudioAttributes.USAGE_ALARM)
            .build()

        val focusGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusReq = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(audioAttributes)
                .setOnAudioFocusChangeListener(this)
                .build()
            audioFocusRequest = focusReq
            am.requestAudioFocus(focusReq) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(this, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }

        hasAudioFocus = focusGranted

        startPlayback(adhanSound, audioAttributes)
    }

    private fun startPlayback(soundChoice: String, audioAttributes: AudioAttributes) {
        try {
            stopPlayback()

            // Map sound choice to raw resource safely (with adhan.ogg as solid fallback)
            val resId = R.raw.adhan

            player = MediaPlayer.create(this, resId).apply {
                setAudioAttributes(audioAttributes)
                isLooping = false
                setOnCompletionListener {
                    Log.i(TAG, "Adhan audio playback finished smoothly")
                    unregisterHardwareButtonReceiver()
                    try {
                        sendBroadcast(Intent(ACTION_ADHAN_COMPLETED).apply { setPackage(packageName) })
                    } catch (_: Exception) {}
                    abandonAudioFocus()
                    stopForeground(false)
                    stopSelf()
                }
                playbackStartTime = System.currentTimeMillis()
                start()
                registerHardwareButtonReceiver()
            }
            Log.i(TAG, "Playback started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start media player: ${e.message}", e)
            unregisterHardwareButtonReceiver()
            abandonAudioFocus()
            stopForeground(false)
            stopSelf()
        }
    }

    private var hardwareButtonReceiver: BroadcastReceiver? = null
    private var playbackStartTime: Long = 0L

    private fun registerHardwareButtonReceiver() {
        if (hardwareButtonReceiver != null) return

        hardwareButtonReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                val elapsed = System.currentTimeMillis() - playbackStartTime
                if (elapsed < 400L) {
                    // Ignore startup volume events in first 400ms
                    return
                }

                if (action == "android.media.VOLUME_CHANGED_ACTION" ||
                    action == Intent.ACTION_SCREEN_OFF ||
                    action == Intent.ACTION_SCREEN_ON) {
                    Log.i(TAG, "🔕 Hardware button press detected via broadcast [$action] -> Silencing Adhan")
                    silenceAdhan()
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction("android.media.VOLUME_CHANGED_ACTION")
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }

        try {
            androidx.core.content.ContextCompat.registerReceiver(
                this,
                hardwareButtonReceiver,
                filter,
                androidx.core.content.ContextCompat.RECEIVER_EXPORTED
            )
            Log.i(TAG, "Hardware button receiver registered successfully in AdhanService")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to register hardware button receiver in AdhanService: ${e.message}")
        }
    }

    private fun unregisterHardwareButtonReceiver() {
        hardwareButtonReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
            hardwareButtonReceiver = null
        }
    }

    private fun silenceAdhan() {
        stopPlayback()
        try {
            sendBroadcast(Intent(ACTION_ADHAN_SILENCED).apply { setPackage(packageName) })
        } catch (_: Exception) {}
        stopForeground(true)
        stopSelf()
    }

    private fun stopPlayback() {
        try {
            unregisterHardwareButtonReceiver()
            player?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.reset()
                it.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping media player: ${e.message}")
        } finally {
            player = null
            abandonAudioFocus()
        }
    }

    private fun abandonAudioFocus() {
        if (!hasAudioFocus) return
        val am = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(this)
        }
        hasAudioFocus = false
    }

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.w(TAG, "Audio focus lost completely — stopping adhan")
                stopPlayback()
                stopForeground(true)
                stopSelf()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.w(TAG, "Audio focus lost transiently — pausing")
                player?.pause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.i(TAG, "Audio focus ducking — lowering volume")
                player?.setVolume(0.2f, 0.2f)
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                Log.i(TAG, "Audio focus regained — restoring volume")
                player?.setVolume(1.0f, 1.0f)
                if (player?.isPlaying == false) {
                    player?.start()
                }
            }
        }
    }

    private fun buildForegroundNotification(
        prayerKey: String,
        prayerName: String,
        cityName: String,
        scheduledMillis: Long
    ): Notification {
        // Full screen Intent to launch over lockscreen
        val fullScreenIntent = Intent(this, AdhanAlertActivity::class.java).apply {
            putExtra("prayer_key", prayerKey)
            putExtra("prayer_name", prayerName)
            putExtra("city_name", cityName)
            putExtra("scheduled_millis", scheduledMillis)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val fullScreenPending = PendingIntent.getActivity(
            this,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Stop Audio
        val stopIntent = Intent(this, AdhanService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Prayed
        val prayedIntent = Intent(this, AdhanService::class.java).apply {
            action = ACTION_PRAYED
            putExtra("prayer_key", prayerKey)
            putExtra("prayer_name", prayerName)
        }
        val prayedPending = PendingIntent.getService(
            this,
            2,
            prayedIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val citySuffix = if (cityName.isNotEmpty()) " • $cityName" else ""

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🕌 حان الآن وقت $prayerName")
            .setContentText("حي على الصلاة • حي على الفلاح$citySuffix")
            .setSmallIcon(R.drawable.ic_mosque)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPending, true)
            .setContentIntent(fullScreenPending)
            .setOngoing(true)
            .addAction(R.drawable.ic_mosque, "إيقاف", stopPending)
            .addAction(R.drawable.ic_mosque, "صلّيت", prayedPending)
            .build()
    }

    private fun recordPrayerCompleted(prayerKey: String, prayerName: String) {
        try {
            val prefs = getSharedPreferences("prayer_logs", Context.MODE_PRIVATE)
            val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
            val key = "${today}_${prayerKey}"
            prefs.edit().putBoolean(key, true).putLong("${key}_timestamp", System.currentTimeMillis()).apply()
            Log.i(TAG, "Recorded prayer completed from notification: $key ($prayerName)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record prayer from notification: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "خدمة تشغيل الأذان",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "قناة تشغيل صوت وتنبيه الأذان التفاعلي"
                setSound(null, null) // Audio is managed by MediaPlayer
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
        Log.i(TAG, "AdhanService destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
