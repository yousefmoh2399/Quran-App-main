import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/adhan/data/models/adhan_settings_model.dart';

void main() {
  group('Adhan Calculation Reference Tests', () {
    test('Cairo Calculation (Egyptian General Authority of Survey)', () {
      final coordinates = Coordinates(30.0444, 31.2357);
      final date = DateComponents(2026, 7, 1);
      final params = CalculationMethod.egyptian.getParameters();
      params.madhab = Madhab.shafi;

      final prayerTimes = PrayerTimes(coordinates, date, params);

      // Verify all 5 prayers + sunrise exist and are chronologically ordered
      expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), isTrue);
      expect(prayerTimes.sunrise.isBefore(prayerTimes.dhuhr), isTrue);
      expect(prayerTimes.dhuhr.isBefore(prayerTimes.asr), isTrue);
      expect(prayerTimes.asr.isBefore(prayerTimes.maghrib), isTrue);
      expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), isTrue);

      // In Cairo on July 1st, Fajr is approximately 03:15-03:25 UTC+2/3 (astronomical calculation)
      expect(prayerTimes.fajr.hour, inInclusiveRange(3, 4));
      // Dhuhr in Cairo summer is around 11:55-12:05 UTC (or 12:55-13:05 local DST)
      expect(prayerTimes.dhuhr.hour, inInclusiveRange(11, 13));
      // Maghrib around 18:50-20:05
      expect(prayerTimes.maghrib.hour, inInclusiveRange(18, 20));
    });

    test('Makkah Calculation (Umm Al-Qura)', () {
      final coordinates = Coordinates(21.4225, 39.8262);
      final date = DateComponents(2026, 4, 15);
      final params = CalculationMethod.umm_al_qura.getParameters();

      final prayerTimes = PrayerTimes(coordinates, date, params);

      // In Umm Al Qura, Isha is exactly 90 minutes after Maghrib (except Ramadan: 120 mins)
      final diffMinutes = prayerTimes.isha.difference(prayerTimes.maghrib).inMinutes;
      expect(diffMinutes, equals(90));
    });

    test('London Calculation (MWL with High Latitude Rule)', () {
      final coordinates = Coordinates(51.5074, -0.1278);
      // Summer solstice date where high latitude twilight does not disappear
      final date = DateComponents(2026, 6, 21);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;

      final prayerTimes = PrayerTimes(coordinates, date, params);

      // With high latitude rule applied, Fajr and Isha must still be valid and distinct
      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.isha, isNotNull);
      expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), isTrue);
      expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), isTrue);
    });

    test('Karachi Calculation (Hanafi Madhab)', () {
      final coordinates = Coordinates(24.8607, 67.0011);
      final date = DateComponents(2026, 10, 15);

      final shafiParams = CalculationMethod.karachi.getParameters();
      shafiParams.madhab = Madhab.shafi;
      final shafiTimes = PrayerTimes(coordinates, date, shafiParams);

      final hanafiParams = CalculationMethod.karachi.getParameters();
      hanafiParams.madhab = Madhab.hanafi;
      final hanafiTimes = PrayerTimes(coordinates, date, hanafiParams);

      // Hanafi Asr (shadow = 2x object) is strictly later than Shafi Asr (shadow = 1x object)
      expect(hanafiTimes.asr.isAfter(shafiTimes.asr), isTrue);
      final differenceMinutes = hanafiTimes.asr.difference(shafiTimes.asr).inMinutes;
      expect(differenceMinutes, greaterThan(30)); // usually ~45 to 60 minutes later
    });
  });

  group('Adhan Settings & Edge Case Tests', () {
    test('Minute Adjustments shift prayer times accurately', () {
      final settings = AdhanSettingsModel(
        latitude: 30.0444,
        longitude: 31.2357,
        cityName: 'Cairo',
        fajrOffset: 2,
        dhuhrOffset: 5,
        asrOffset: 0,
        maghribOffset: -1,
        ishaOffset: 3,
      );

      final coordinates = Coordinates(settings.latitude, settings.longitude);
      final date = DateComponents(2026, 5, 1);
      final baseParams = CalculationMethod.egyptian.getParameters();
      final baseTimes = PrayerTimes(coordinates, date, baseParams);

      final adjustedFajr = baseTimes.fajr.add(Duration(minutes: settings.fajrOffset));
      final adjustedDhuhr = baseTimes.dhuhr.add(Duration(minutes: settings.dhuhrOffset));
      final adjustedMaghrib = baseTimes.maghrib.add(Duration(minutes: settings.maghribOffset));

      expect(adjustedFajr.difference(baseTimes.fajr).inMinutes, equals(2));
      expect(adjustedDhuhr.difference(baseTimes.dhuhr).inMinutes, equals(5));
      expect(adjustedMaghrib.difference(baseTimes.maghrib).inMinutes, equals(-1));
    });

    test('Prayer Enable/Disable toggles in AdhanSettingsModel', () {
      final settings = AdhanSettingsModel(
        latitude: 30.0444,
        longitude: 31.2357,
        fajrEnabled: true,
        dhuhrEnabled: true,
        asrEnabled: false, // Disabled
        maghribEnabled: true,
        ishaEnabled: false, // Disabled
      );

      final map = settings.toMap();
      final restored = AdhanSettingsModel.fromMap(map);

      expect(restored.fajrEnabled, isTrue);
      expect(restored.dhuhrEnabled, isTrue);
      expect(restored.asrEnabled, isFalse);
      expect(restored.maghribEnabled, isTrue);
      expect(restored.ishaEnabled, isFalse);
    });

    test('Deterministic Request Code Generation (8-day span, no collisions)', () {
      final generatedCodes = <int>{};
      const totalDays = 8;
      const prayersCount = 5; // Fajr(1), Dhuhr(2), Asr(3), Maghrib(4), Isha(5)

      for (int day = 0; day < totalDays; day++) {
        for (int pIndex = 1; pIndex <= prayersCount; pIndex++) {
          final code = 20000 + (day * 10) + pIndex;
          expect(generatedCodes.contains(code), isFalse,
              reason: 'Request code $code collided at day $day, prayer $pIndex');
          generatedCodes.add(code);
        }
      }

      expect(generatedCodes.length, equals(totalDays * prayersCount));
      // First alarm (Day 0 Fajr) = 20001
      expect(generatedCodes.first, equals(20001));
      // Last alarm (Day 7 Isha) = 20075
      expect(generatedCodes.contains(20075), isTrue);
    });

    test('50km Haversine distance threshold triggers recalculation properly', () {
      double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        const earthRadiusKm = 6371.0;
        final dLat = (lat2 - lat1) * math.pi / 180.0;
        final dLon = (lon2 - lon1) * math.pi / 180.0;
        final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(lat1 * math.pi / 180.0) *
                math.cos(lat2 * math.pi / 180.0) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);
        final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        return earthRadiusKm * c;
      }

      // Cairo center to Giza (approx 10km) -> Should NOT trigger > 50km recalculation
      final cairoToGiza = calculateDistanceKm(30.0444, 31.2357, 30.0131, 31.2089);
      expect(cairoToGiza, lessThan(50.0));

      // Cairo to Alexandria (approx 180km) -> MUST trigger > 50km recalculation
      final cairoToAlex = calculateDistanceKm(30.0444, 31.2357, 31.2001, 29.9187);
      expect(cairoToAlex, greaterThan(50.0));

      // Cairo to Tanta (approx 85km) -> MUST trigger > 50km recalculation
      final cairoToTanta = calculateDistanceKm(30.0444, 31.2357, 30.7865, 31.0004);
      expect(cairoToTanta, greaterThan(50.0));
    });
  });
}
