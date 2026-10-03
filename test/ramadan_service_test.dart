import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/ramadan/data/ramadan_notification_service.dart';
import 'package:quran_app_android/features/ramadan/data/ramadan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RamadanService Offline Calculations Tests', () {
    final service = RamadanService.instance;

    test('calculate30DaysImsakia generates exactly 30 days', () {
      final days = service.calculate30DaysImsakia(imsakMinutesBeforeFajr: 15);
      expect(days.length, 30);
      expect(days.first.dayNumber, 1);
      expect(days.last.dayNumber, 30);

      // Verify imsak time is exactly 15 minutes before fajr
      for (final d in days) {
        expect(d.fajrDateTime.difference(d.imsakDateTime).inMinutes, 15);
        expect(d.imsakTime.isNotEmpty, true);
        expect(d.maghribTime.isNotEmpty, true);
      }
    });

    test('Zakat al-Fitr calculates correctly', () {
      final res = service.calculateZakatFitr(
        familyMembers: 5,
        pricePerPerson: 40.0,
      );
      expect(res['familyMembers'], 5);
      expect(res['pricePerPerson'], 40.0);
      expect(res['totalZakat'], 200.0);
    });

    test('Zakat al-Mal calculates eligible zakat and nisab correctly', () {
      // 85 grams * 3500 = 297,500 nisab
      final resEligible = service.calculateZakatMal(
        cashAndSavings: 300000,
        goldAndSilverValue: 50000,
        tradeGoodsValue: 0,
        immediateDebtsToDeduct: 10000,
        goldGramPrice21k: 3500,
      );
      // Net wealth = 340,000 >= 297,500
      expect(resEligible['isEligible'], true);
      expect(resEligible['netWealth'], 340000.0);
      expect(resEligible['nisabThreshold'], 297500.0);
      expect(resEligible['zakatDue'], 340000.0 * 0.025);

      // Below nisab
      final resIneligible = service.calculateZakatMal(
        cashAndSavings: 50000,
        goldAndSilverValue: 0,
        tradeGoodsValue: 0,
        immediateDebtsToDeduct: 0,
        goldGramPrice21k: 3500,
      );
      expect(resIneligible['isEligible'], false);
      expect(resIneligible['zakatDue'], 0.0);
    });

    test('Ramadan Duas database has all 30 daily duas', () {
      final dailyDuas = service.getDuasByCategory('daily');
      expect(dailyDuas.length, 30);
      for (int i = 1; i <= 30; i++) {
        expect(dailyDuas.any((d) => d.day == i), true);
      }

      final lastTen = service.getDuasByCategory('last_ten');
      expect(lastTen.isNotEmpty, true);

      final qunut = service.getDuasByCategory('qunut');
      expect(qunut.isNotEmpty, true);

      final fastingSunnah = service.getDuasByCategory('fasting_sunnah');
      expect(fastingSunnah.isNotEmpty, true);
    });

    test('Khatma and Taraweeh persistence works smoothly', () async {
      await service.setKhatmaTarget(2);
      expect(await service.getKhatmaTarget(), 2);

      await service.saveKhatmaCompletedPages(45);
      expect(await service.getKhatmaCompletedPages(), 45);

      await service.setTaraweehTarget(20);
      expect(await service.getTaraweehTarget(), 20);

      await service.setTaraweehCurrent(8);
      expect(await service.getTaraweehCurrent(), 8);
    });

    test('RamadanNotificationService constants and IDs are well defined', () {
      expect(RamadanNotificationService.channelId, 'ramadan_channel_v1');
      expect(RamadanNotificationService.idSuhoor, 7001);
      expect(RamadanNotificationService.idImsak, 7002);
      expect(RamadanNotificationService.idIftarCannon, 7003);
      expect(RamadanNotificationService.idKhatma, 7004);
      expect(RamadanNotificationService.instance, isNotNull);
    });
  });
}
