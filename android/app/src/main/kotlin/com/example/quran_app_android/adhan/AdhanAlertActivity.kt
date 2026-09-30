package com.example.quran_app_android.adhan

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.quran_app_android.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class AdhanAlertActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "AdhanAlertActivity"
        private const val AUTO_DISMISS_DELAY_MS = 5 * 60 * 1000L // 5 minutes
    }

    private var crescentAnimator: ObjectAnimator? = null
    private var nextPrayerTimer: CountDownTimer? = null
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var gestureDetector: GestureDetector

    private var adhanCompletedReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Setup lock screen presentation
        setupLockScreenPresentation()

        setContentView(R.layout.activity_adhan_alert)

        // 2. Parse intent parameters
        val prayerKey = intent.getStringExtra("prayer_key") ?: "fajr"
        val prayerName = intent.getStringExtra("prayer_name") ?: "الصلاة"
        val cityName = intent.getStringExtra("city_name") ?: ""
        val scheduledMillis = intent.getLongExtra("scheduled_millis", System.currentTimeMillis())

        // 3. Bind and format UI components
        setupViews(prayerKey, prayerName, cityName, scheduledMillis)

        // 4. Start serene crescent floating animation
        startCrescentAnimation()

        // 5. Setup live countdown to next prayer
        setupNextPrayerCountdown(scheduledMillis)

        // 6. Setup gestures (swipe down to dismiss)
        setupSwipeToDismiss()

        // 7. Register receiver for audio completion to reveal Du'a
        registerAdhanCompletionReceiver()

        // 8. Auto-dismiss timeout
        handler.postDelayed(autoDismissRunnable, AUTO_DISMISS_DELAY_MS)
    }

    private val autoDismissRunnable = Runnable {
        Log.i(TAG, "Auto-dismissing adhan alert after 5 minutes timeout")
        stopAdhanService()
        if (!isFinishing) finish()
    }

    private fun setupLockScreenPresentation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Android 14 (API 34) verification
        if (Build.VERSION.SDK_INT >= 34) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!nm.canUseFullScreenIntent()) {
                Log.w(TAG, "NotificationManager: canUseFullScreenIntent is false on Android 14+")
            }
        }
    }

    private fun setupViews(
        prayerKey: String,
        prayerName: String,
        cityName: String,
        scheduledMillis: Long
    ) {
        val tvLocationAndDate = findViewById<TextView>(R.id.tvLocationAndDate)
        val tvHijriDate = findViewById<TextView>(R.id.tvHijriDate)
        val tvAdhanSubtitle = findViewById<TextView>(R.id.tvAdhanSubtitle)
        val tvPrayerName = findViewById<TextView>(R.id.tvPrayerName)
        val tvPrayerTime = findViewById<TextView>(R.id.tvPrayerTime)
        val btnStopAdhan = findViewById<Button>(R.id.btnStopAdhan)
        val btnPrayed = findViewById<Button>(R.id.btnPrayed)
        val cardDua = findViewById<View>(R.id.cardDua)

        // Arabic formatting
        val arLocale = Locale("ar", "EG")
        val dateFmt = SimpleDateFormat("EEEE d MMMM yyyy", arLocale)
        val timeFmt = SimpleDateFormat("hh:mm a", arLocale)

        val locationText = if (cityName.isNotEmpty()) "$cityName • " else ""
        tvLocationAndDate.text = "$locationText${dateFmt.format(Date(scheduledMillis))}"

        tvHijriDate.text = getApproxHijriDate(arLocale)

        tvAdhanSubtitle.text = "🕌 حان الآن موعد أذان $prayerName"
        tvPrayerName.text = "صلاة $prayerName"
        tvPrayerTime.text = timeFmt.format(Date(scheduledMillis))

        // Buttons listeners
        btnStopAdhan.setOnClickListener {
            stopAdhanService()
            revealDuaCard(cardDua)
            btnStopAdhan.isEnabled = false
            btnStopAdhan.text = "تم إيقاف الصوت"
            btnStopAdhan.alpha = 0.6f
        }

        btnPrayed.setOnClickListener {
            stopAdhanService()
            recordPrayerCompleted(prayerKey, prayerName)
            Toast.makeText(this, "تقبل الله طاعتكم وصالح أعمالكم 🤲", Toast.LENGTH_LONG).show()
            handler.removeCallbacks(autoDismissRunnable)
            finish()
        }
    }

    private fun recordPrayerCompleted(prayerKey: String, prayerName: String) {
        try {
            val prefs = getSharedPreferences("prayer_logs", Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val key = "${today}_${prayerKey}"
            prefs.edit().putBoolean(key, true).putLong("${key}_timestamp", System.currentTimeMillis()).apply()
            Log.i(TAG, "Recorded prayer completed: $key ($prayerName)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record prayer: ${e.message}")
        }
    }

    private fun startCrescentAnimation() {
        val ivCrescent = findViewById<ImageView>(R.id.ivCrescent)
        val scaleDownX = PropertyValuesHolder.ofFloat(View.SCALE_X, 1.0f, 1.08f, 1.0f)
        val scaleDownY = PropertyValuesHolder.ofFloat(View.SCALE_Y, 1.0f, 1.08f, 1.0f)
        val translateY = PropertyValuesHolder.ofFloat(View.TRANSLATION_Y, 0f, -8f, 0f)

        crescentAnimator = ObjectAnimator.ofPropertyValuesHolder(ivCrescent, scaleDownX, scaleDownY, translateY).apply {
            duration = 3200
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            start()
        }
    }

    private fun setupNextPrayerCountdown(currentAdhanMillis: Long) {
        val cardNextPrayer = findViewById<View>(R.id.cardNextPrayer)
        val tvNextPrayerTitle = findViewById<TextView>(R.id.tvNextPrayerTitle)
        val tvNextPrayerCountdown = findViewById<TextView>(R.id.tvNextPrayerCountdown)

        val upcomingList = NativePrayerManager.calculateRollingWindow(this, 3)
            .filter { it.timeMillis > currentAdhanMillis + 60_000L }

        val next = upcomingList.firstOrNull()
        if (next == null) {
            cardNextPrayer.visibility = View.GONE
            return
        }

        tvNextPrayerTitle.text = "الصلاة القادمة: صلاة ${next.nameAr}"

        val diff = next.timeMillis - System.currentTimeMillis()
        if (diff <= 0) {
            cardNextPrayer.visibility = View.GONE
            return
        }

        nextPrayerTimer = object : CountDownTimer(diff, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val sec = (millisUntilFinished / 1000) % 60
                val min = (millisUntilFinished / (1000 * 60)) % 60
                val hours = (millisUntilFinished / (1000 * 60 * 60))

                val ar = Locale("ar", "EG")
                tvNextPrayerCountdown.text = String.format(ar, "متبقي %02d:%02d:%02d", hours, min, sec)
            }

            override fun onFinish() {
                tvNextPrayerCountdown.text = "حان وقت الصلاة القادمة"
            }
        }.start()
    }

    private fun revealDuaCard(cardDua: View) {
        if (cardDua.visibility != View.VISIBLE) {
            cardDua.alpha = 0f
            cardDua.visibility = View.VISIBLE
            cardDua.animate().alpha(1.0f).setDuration(600).start()
        }
    }

    private fun registerAdhanCompletionReceiver() {
        adhanCompletedReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                Log.i(TAG, "Received adhan audio completion broadcast, showing Du'a")
                val cardDua = findViewById<View>(R.id.cardDua)
                revealDuaCard(cardDua)
                val btnStop = findViewById<Button>(R.id.btnStopAdhan)
                btnStop.isEnabled = false
                btnStop.text = "انتهى الأذان"
                btnStop.alpha = 0.5f
            }
        }
        val filter = IntentFilter(AdhanService.ACTION_ADHAN_COMPLETED)
        androidx.core.content.ContextCompat.registerReceiver(
            this,
            adhanCompletedReceiver,
            filter,
            androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    private fun setupSwipeToDismiss() {
        gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(
                e1: MotionEvent?,
                e2: MotionEvent,
                velocityX: Float,
                velocityY: Float
            ): Boolean {
                if (e1 != null && e2.y - e1.y > 150 && Math.abs(velocityY) > 100) {
                    Log.i(TAG, "Dismissed via swipe down")
                    stopAdhanService()
                    finish()
                    return true
                }
                return false
            }
        })

        findViewById<View>(R.id.adhanRootView).setOnTouchListener { _, event ->
            gestureDetector.onTouchEvent(event)
            true
        }
    }

    private fun stopAdhanService() {
        val stopIntent = Intent(this, AdhanService::class.java).apply {
            action = AdhanService.ACTION_STOP_ADHAN
        }
        try {
            startService(stopIntent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not send stop intent to AdhanService: ${e.message}")
        }
    }

    private fun getApproxHijriDate(locale: Locale): String {
        // Approximate / standard Hijri date string fallback
        val cal = Calendar.getInstance()
        val year = cal.get(Calendar.YEAR)
        // 2026 is ~ 1448 AH
        val hijriYear = year - 578
        return "تقويم أم القرى • سنة $hijriYear هـ"
    }

    override fun onDestroy() {
        crescentAnimator?.cancel()
        nextPrayerTimer?.cancel()
        handler.removeCallbacks(autoDismissRunnable)
        adhanCompletedReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        super.onDestroy()
    }
}
