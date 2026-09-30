package com.example.quran_app_android.reminders

import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.chrono.HijrahChronology
import java.time.chrono.HijrahDate
import java.time.temporal.ChronoField
import java.time.temporal.TemporalAdjusters
import java.util.Calendar

object HijriCalendarHelper {

    /**
     * Calculates the next trigger timestamp for a monthly reminder.
     * Supports Gregorian and Hijri calendars, and day types:
     * - "day_of_month": specific day (1..31), clamped if month is shorter
     * - "last_thursday": last Thursday of the month
     * - "last_working_day": last working day (Sun-Thu, step back from Fri/Sat)
     */
    fun calculateNextMonthlyTrigger(
        calendarType: String, // "gregorian" or "hijri"
        dayType: String,      // "day_of_month", "last_thursday", "last_working_day"
        targetDay: Int,       // 1..31 (used if dayType == "day_of_month")
        hour: Int,
        minute: Int,
        currentTimeMillis: Long = System.currentTimeMillis()
    ): Long {
        return if (calendarType.equals("hijri", ignoreCase = true)) {
            calculateNextHijriTrigger(dayType, targetDay, hour, minute, currentTimeMillis)
        } else {
            calculateNextGregorianTrigger(dayType, targetDay, hour, minute, currentTimeMillis)
        }
    }

    /**
     * Gregorian monthly calculation.
     */
    fun calculateNextGregorianTrigger(
        dayType: String,
        targetDay: Int,
        hour: Int,
        minute: Int,
        currentTimeMillis: Long
    ): Long {
        val cal = Calendar.getInstance().apply {
            timeInMillis = currentTimeMillis
        }

        // Try current month first
        val currentMonthCandidate = getGregorianDayForMonth(
            year = cal.get(Calendar.YEAR),
            month = cal.get(Calendar.MONTH),
            dayType = dayType,
            targetDay = targetDay,
            hour = hour,
            minute = minute
        )

        if (currentMonthCandidate > currentTimeMillis) {
            return currentMonthCandidate
        }

        // Advance to next month
        cal.add(Calendar.MONTH, 1)
        return getGregorianDayForMonth(
            year = cal.get(Calendar.YEAR),
            month = cal.get(Calendar.MONTH),
            dayType = dayType,
            targetDay = targetDay,
            hour = hour,
            minute = minute
        )
    }

    /**
     * Finds the timestamp for a specific month/year in Gregorian calendar.
     */
    fun getGregorianDayForMonth(
        year: Int,
        month: Int,
        dayType: String,
        targetDay: Int,
        hour: Int,
        minute: Int
    ): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val maxDay = cal.getActualMaximum(Calendar.DAY_OF_MONTH)

        when (dayType) {
            "last_thursday" -> {
                // Start from the last day of month and search backwards for Thursday
                cal.set(Calendar.DAY_OF_MONTH, maxDay)
                while (cal.get(Calendar.DAY_OF_WEEK) != Calendar.THURSDAY) {
                    cal.add(Calendar.DAY_OF_MONTH, -1)
                }
            }
            "last_working_day" -> {
                // In Arab/Islamic working week (Sun-Thu): working days are NOT Friday (6) and NOT Saturday (7)
                cal.set(Calendar.DAY_OF_MONTH, maxDay)
                while (cal.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY || cal.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY) {
                    cal.add(Calendar.DAY_OF_MONTH, -1)
                }
            }
            else -> {
                // "day_of_month": clamp targetDay to maxDay of this month
                val clampedDay = targetDay.coerceIn(1, maxDay)
                cal.set(Calendar.DAY_OF_MONTH, clampedDay)
            }
        }

        return cal.timeInMillis
    }

    /**
     * Hijri monthly calculation using java.time HijrahChronology with safe fallback.
     */
    fun calculateNextHijriTrigger(
        dayType: String,
        targetDay: Int,
        hour: Int,
        minute: Int,
        currentTimeMillis: Long
    ): Long {
        try {
            val nowZone = ZoneId.systemDefault()
            val nowLocal = LocalDate.ofInstant(java.time.Instant.ofEpochMilli(currentTimeMillis), nowZone)
            var hDate = HijrahDate.from(nowLocal)

            // Try current Hijri month
            val candidateMillis = getHijriDayForMonth(hDate, dayType, targetDay, hour, minute, nowZone)
            if (candidateMillis > currentTimeMillis) {
                return candidateMillis
            }

            // Advance to next Hijri month
            val nextHDate = hDate.plus(1, java.time.temporal.ChronoUnit.MONTHS) as HijrahDate
            return getHijriDayForMonth(nextHDate, dayType, targetDay, hour, minute, nowZone)

        } catch (e: Throwable) {
            // Algorithmic fallback if HijrahChronology is unavailable
            return calculateNextGregorianTrigger(dayType, targetDay, hour, minute, currentTimeMillis)
        }
    }

    private fun getHijriDayForMonth(
        baseHDate: HijrahDate,
        dayType: String,
        targetDay: Int,
        hour: Int,
        minute: Int,
        zone: ZoneId
    ): Long {
        val hYear = baseHDate.get(ChronoField.YEAR)
        val hMonth = baseHDate.get(ChronoField.MONTH_OF_YEAR)
        val monthLength = baseHDate.lengthOfMonth() // 29 or 30

        val resolvedHDate: HijrahDate = when (dayType) {
            "last_thursday" -> {
                var d = HijrahDate.of(hYear, hMonth, monthLength)
                while (LocalDate.from(d).dayOfWeek != java.time.DayOfWeek.THURSDAY) {
                    d = d.minus(1, java.time.temporal.ChronoUnit.DAYS) as HijrahDate
                }
                d
            }
            "last_working_day" -> {
                var d = HijrahDate.of(hYear, hMonth, monthLength)
                while (LocalDate.from(d).dayOfWeek == java.time.DayOfWeek.FRIDAY || LocalDate.from(d).dayOfWeek == java.time.DayOfWeek.SATURDAY) {
                    d = d.minus(1, java.time.temporal.ChronoUnit.DAYS) as HijrahDate
                }
                d
            }
            else -> {
                val clamped = targetDay.coerceIn(1, monthLength)
                HijrahDate.of(hYear, hMonth, clamped)
            }
        }

        val gLocalDate = LocalDate.from(resolvedHDate)
        val gLocalDateTime = gLocalDate.atTime(LocalTime.of(hour, minute, 0))
        return gLocalDateTime.atZone(zone).toInstant().toEpochMilli()
    }
}
