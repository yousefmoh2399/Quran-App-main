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
        if (cachedAzkar != null) {
            onLoaded?.invoke(cachedAzkar!)
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

    private fun loadFromRaw(context: Context): List<AzkarItem> {
        return try {
            val inputStream = context.resources.openRawResource(R.raw.azkar_widget_data)
            val reader = InputStreamReader(inputStream, "UTF-8")
            val type = object : TypeToken<List<AzkarItem>>() {}.type
            val list: List<AzkarItem> = Gson().fromJson(reader, type)
            reader.close()
            inputStream.close()
            Log.i(TAG, "Loaded ${list.size} azkar items successfully from raw json")
            list
        } catch (e: Exception) {
            Log.e(TAG, "Error loading azkar from raw: ${e.message}", e)
            listOf(
                AzkarItem(
                    1,
                    "سُبْحَانَ اللهِ وَبِحَمْدِهِ ، سُبْحَانَ اللهِ الْعَظِيمِ",
                    "tasbeeh",
                    "تسابيح وتحميد",
                    "صحيح البخاري",
                    100
                )
            )
        }
    }

    /**
     * Pick a random dhikr matching selected categories.
     */
    fun getRandom(context: Context, selectedCategories: Set<String>? = null): AzkarItem {
        val all = getAll(context)
        val filtered = if (!selectedCategories.isNullOrEmpty()) {
            all.filter { selectedCategories.contains(it.category) }
        } else {
            all
        }
        val targetList = if (filtered.isNotEmpty()) filtered else all
        return targetList[Random.nextInt(targetList.size)]
    }

    /**
     * Deterministic dhikr for 10-minute widget slots.
     * index = (timeMillis / (10 * 60 * 1000L) + manualOffset) % totalAzkar
     */
    fun getDeterministic(context: Context, timeMillis: Long = System.currentTimeMillis(), manualOffset: Int = 0): AzkarItem {
        val all = getAll(context)
        if (all.isEmpty()) {
            return AzkarItem(1, "سُبْحَانَ اللهِ وَبِحَمْدِهِ", "tasbeeh", "تسابيح", "البخاري", 100)
        }
        val slot = timeMillis / (10 * 60 * 1000L)
        val index = (((slot + manualOffset) % all.size + all.size) % all.size).toInt()
        return all[index]
    }
}
