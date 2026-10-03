package com.example.quran_app_android.azkar

import android.content.Context
import android.util.Log
import com.example.quran_app_android.R
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.InputStreamReader
import java.util.concurrent.Executors
import kotlin.random.Random

data class AzkarItem(
    val id: Int,
    val text: String,
    val category: String,
    val category_name: String,
    val source: String,
    val count: Int
)

object AzkarDataRepository {
    private const val TAG = "AzkarDataRepo"

    @Volatile
    private var cachedAzkar: List<AzkarItem>? = null
    private val executor = Executors.newSingleThreadExecutor()

    fun initAsync(context: Context, onLoaded: ((List<AzkarItem>) -> Unit)? = null) {
        val current = cachedAzkar
        if (current != null) {
            onLoaded?.invoke(current)
            return
        }
        executor.execute {
            val list = loadFromRaw(context)
            cachedAzkar = list
            onLoaded?.invoke(list)
        }
    }

    @Synchronized
    fun getAll(context: Context): List<AzkarItem> {
        cachedAzkar?.let { return it }
        val list = loadFromRaw(context)
        cachedAzkar = list
        return list
    }

    private val FALLBACK_AZKAR = listOf(
        AzkarItem(1, "سُبْحَانَ اللهِ وَبِحَمْدِهِ ، سُبْحَانَ اللهِ الْعَظِيمِ", "tasbeeh", "تسابيح وتحميد", "صحيح البخاري", 100),
        AzkarItem(2, "أَصْبَحْنَا وَأَصْبَحَ المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ", "morning_evening", "أذكار الصباح والمساء", "صحيح مسلم", 1),
        AzkarItem(3, "أَمْسَيْنَا وَأَمْسَى المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ", "morning_evening", "أذكار الصباح والمساء", "صحيح مسلم", 1),
        AzkarItem(4, "اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ", "istighfar", "استغفار وتوبة", "صحيح البخاري", 1),
        AzkarItem(5, "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", "quranic", "أدعية قرآنية", "سورة البقرة", 1),
        AzkarItem(6, "اللَّهُمَّ إِنِّي أَسْأَلُكَ العَفْوَ وَالعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ", "prophetic", "أدعية نبوية مأثورة", "سنن أبي داود", 1),
        AzkarItem(7, "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ العَلِيِّ العَظِيمِ", "tasbeeh", "تسابيح وتحميد", "متفق عليه", 100),
        AzkarItem(8, "أَسْتَغْفِرُ اللَّهَ العَظِيمَ الَّذِي لاَ إِلَهَ إِلاَّ هُوَ الحَيُّ القَيُّومُ وَأَتُوبُ إِلَيْهِ", "istighfar", "استغفار وتوبة", "سنن الترمذي", 3),
        AzkarItem(9, "اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ", "salawat", "الصلاة على النبي", "حصن المسلم", 10),
        AzkarItem(10, "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", "quranic", "أدعية قرآنية", "سورة طه", 1)
    )

    private const val PREFS_AZKAR_ROTATION = "azkar_rotation_prefs"
    private const val KEY_RECENT_IDS = "recent_azkar_ids"
    private const val MAX_RECENT_HISTORY = 25

    private fun loadFromRaw(context: Context): List<AzkarItem> {
        return try {
            val inputStream = context.resources.openRawResource(R.raw.azkar_widget_data)
            val reader = InputStreamReader(inputStream, "UTF-8")
            val type = object : TypeToken<List<AzkarItem>>() {}.type
            val list: List<AzkarItem> = Gson().fromJson(reader, type)
            reader.close()
            inputStream.close()
            Log.i(TAG, "Loaded ${list.size} azkar items successfully from raw json")
            if (list.isNotEmpty()) list else FALLBACK_AZKAR
        } catch (e: Exception) {
            Log.e(TAG, "Error loading azkar from raw: ${e.message}", e)
            FALLBACK_AZKAR
        }
    }

    /**
     * Pick a random dhikr matching selected categories.
     */
    fun getRandom(context: Context, selectedCategories: Set<String>? = null): AzkarItem {
        val all = getAll(context)
        val expandedCategories = expandCategories(selectedCategories)
        val filtered = if (!expandedCategories.isNullOrEmpty()) {
            all.filter { expandedCategories.contains(it.category) }
        } else {
            all
        }
        val targetList = if (filtered.isNotEmpty()) filtered else all
        return targetList[Random.nextInt(targetList.size)]
    }

    /**
     * Intelligently picks a rotating dhikr that changes on every trigger,
     * respects active categories, adapts to the time of day, and avoids consecutive repetition.
     */
    fun getRotatingZikr(context: Context, selectedCategories: Set<String>? = null): AzkarItem {
        val all = getAll(context)
        if (all.isEmpty()) {
            return FALLBACK_AZKAR[0]
        }

        val expandedCategories = expandCategories(selectedCategories)
        val filtered = if (!expandedCategories.isNullOrEmpty()) {
            all.filter { expandedCategories.contains(it.category) }
        } else {
            all
        }
        val pool = if (filtered.isNotEmpty()) filtered else all

        val cal = java.util.Calendar.getInstance()
        val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)

        // Time-appropriate category preference:
        val timeFavored = when {
            hour in 5..11 && pool.any { it.category == "morning_evening" } ->
                pool.filter { it.category == "morning_evening" }
            hour in 15..20 && pool.any { it.category == "morning_evening" } ->
                pool.filter { it.category == "morning_evening" }
            (hour >= 21 || hour < 5) && pool.any { it.category == "sleep_wake" || it.category == "istighfar" } ->
                pool.filter { it.category == "sleep_wake" || it.category == "istighfar" || it.category == "tasbeeh" }
            else -> pool
        }

        val candidates = if (timeFavored.isNotEmpty()) timeFavored else pool

        // Read recent history to avoid repetition
        val prefs = context.getSharedPreferences(PREFS_AZKAR_ROTATION, Context.MODE_PRIVATE)
        val recentStr = prefs.getString(KEY_RECENT_IDS, "") ?: ""
        val recentIds = if (recentStr.isNotEmpty()) {
            recentStr.split(",").mapNotNull { it.toIntOrNull() }.toMutableList()
        } else {
            mutableListOf()
        }

        var available = candidates.filterNot { recentIds.contains(it.id) }
        if (available.isEmpty()) {
            val trimmed = recentIds.takeLast(3)
            recentIds.clear()
            recentIds.addAll(trimmed)
            available = candidates.filterNot { recentIds.contains(it.id) }
            if (available.isEmpty()) {
                available = candidates
            }
        }

        val chosen = available[Random.nextInt(available.size)]

        recentIds.add(chosen.id)
        while (recentIds.size > MAX_RECENT_HISTORY) {
            recentIds.removeAt(0)
        }
        prefs.edit().putString(KEY_RECENT_IDS, recentIds.joinToString(",")).apply()

        Log.i(TAG, "Selected rotating dhikr [id=${chosen.id}, cat=${chosen.category}]")
        return chosen
    }

    /**
     * Generates a context-aware title based on dhikr and current time.
     */
    fun getTitleForDhikr(dhikr: AzkarItem, hour: Int = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)): String {
        return when (dhikr.category) {
            "morning_evening" -> {
                when {
                    hour in 4..11 -> "☀️ أذكار الصباح المأثورة"
                    hour in 12..21 -> "🌙 أذكار المساء المأثورة"
                    else -> "📿 أذكار اليوم والليلة"
                }
            }
            "istighfar" -> "🤲 استغفار وتوبة"
            "tasbeeh" -> "📿 تسبيح وتحميد وتهليل"
            "quranic" -> "📖 دعاء من القرآن الكريم"
            "prophetic" -> "✨ دعاء نبوي شريف"
            "sleep_wake" -> {
                if (hour >= 20 || hour < 5) "🌙 أذكار النوم والسكينة" else "🌿 ذكر وتذكير"
            }
            "relief" -> "🤲 تفريج الهم والكرب"
            "salawat" -> "💚 الصلاة على النبي ﷺ"
            "prayer" -> "🕌 أذكار ما بعد الصلاة"
            else -> "🌿 ذكر وتذكير"
        }
    }

    private fun expandCategories(categories: Set<String>?): Set<String>? {
        if (categories.isNullOrEmpty()) return null
        return categories.flatMap { cat ->
            when (cat) {
                "general" -> listOf("general", "prayer", "relief", "travel", "sleep_wake", "salawat")
                else -> listOf(cat)
            }
        }.toSet()
    }

    /**
     * Deterministic dhikr for 10-minute widget slots.
     * index = (timeMillis / (10 * 60 * 1000L) + manualOffset) % totalAzkar
     */
    fun getDeterministic(context: Context, timeMillis: Long = System.currentTimeMillis(), manualOffset: Int = 0): AzkarItem {
        val all = getAll(context)
        if (all.isEmpty()) {
            return FALLBACK_AZKAR[0]
        }
        val slot = timeMillis / (10 * 60 * 1000L)
        val index = (((slot + manualOffset) % all.size + all.size) % all.size).toInt()
        return all[index]
    }
}
