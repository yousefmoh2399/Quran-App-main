import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_shadows.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';

class AdhanHeroCard extends StatefulWidget {
  final PrayerTimes prayerTimes;

  const AdhanHeroCard({
    super.key,
    required this.prayerTimes,
  });

  @override
  State<AdhanHeroCard> createState() => _AdhanHeroCardState();
}

class _AdhanHeroCardState extends State<AdhanHeroCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Prayer _getNextPrayer() {
    final next = widget.prayerTimes.nextPrayer();
    if (next == Prayer.none) {
      return Prayer.fajr;
    }
    return next;
  }

  DateTime _getNextPrayerTime(Prayer prayer) {
    final now = DateTime.now();
    DateTime time;
    switch (prayer) {
      case Prayer.fajr:
        time = widget.prayerTimes.fajr;
        break;
      case Prayer.sunrise:
        time = widget.prayerTimes.sunrise;
        break;
      case Prayer.dhuhr:
        time = widget.prayerTimes.dhuhr;
        break;
      case Prayer.asr:
        time = widget.prayerTimes.asr;
        break;
      case Prayer.maghrib:
        time = widget.prayerTimes.maghrib;
        break;
      case Prayer.isha:
        time = widget.prayerTimes.isha;
        break;
      case Prayer.none:
        time = widget.prayerTimes.fajr;
        break;
    }
    if (time.isBefore(now)) {
      return time.add(const Duration(days: 1));
    }
    return time;
  }

  String _prayerNameArabic(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'صلاة الفجر';
      case Prayer.sunrise:
        return 'شروق الشمس';
      case Prayer.dhuhr:
        return 'صلاة الظهر';
      case Prayer.asr:
        return 'صلاة العصر';
      case Prayer.maghrib:
        return 'صلاة المغرب';
      case Prayer.isha:
        return 'صلاة العشاء';
      case Prayer.none:
        return 'صلاة الفجر';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = isPm ? 'م' : 'ص';
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextPrayer = _getNextPrayer();
    final nextPrayerTime = _getNextPrayerTime(nextPrayer);
    final now = DateTime.now();
    final remaining = nextPrayerTime.difference(now);

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated(isDark),
      ),
      child: Stack(
        children: [
          // Background decorative mosque motif
          Positioned(
            left: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(
                Icons.mosque_rounded,
                size: 160,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                // Top label row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          AppSpacing.horizontalXs,
                          Text(
                            'الصلاة القادمة',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(nextPrayerTime),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLg,

                // Next Prayer Title
                Text(
                  _prayerNameArabic(nextPrayer),
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                AppSpacing.verticalMd,

                // Countdown Timer Boxes
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeSegment(hours, 'ساعة', Colors.white),
                      _buildSeparator(Colors.white),
                      _buildTimeSegment(minutes, 'دقيقة', Colors.white),
                      _buildSeparator(Colors.white),
                      _buildTimeSegment(seconds, 'ثانية', Colors.white),
                    ],
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  'الوقت المتبقي لرفع الأذان',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSegment(String value, String label, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 10,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: AppTypography.uiFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.6),
        ),
      ),
    );
  }
}
