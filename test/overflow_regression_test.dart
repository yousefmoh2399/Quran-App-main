import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_debug_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';
import 'package:quran_app_android/features/reminders/presentation/views/reminders_debug_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('native_adhan_bridge'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getUpcomingPrayers') {
          return [
            {
              'prayerName': 'الفجر',
              'epochMillis': DateTime.now().add(const Duration(hours: 4)).millisecondsSinceEpoch,
              'formattedTime': '04:30 AM',
            },
            {
              'prayerName': 'الظهر',
              'epochMillis': DateTime.now().add(const Duration(hours: 10)).millisecondsSinceEpoch,
              'formattedTime': '12:15 PM',
            },
          ];
        }
        if (methodCall.method == 'getSettings') {
          return {
            'calculationMethod': 'Egyptian General Authority of Survey',
            'madhab': 'Shafi',
            'timeZoneId': 'Africa/Cairo',
            'adhanSound': 'makkah',
          };
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.taqarrab.quran/native_reminders'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getUpcomingAlarms') {
          return [
            {
              'id': 'morning_azkar_main',
              'type': 'azkar',
              'triggerEpoch': DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch,
              'channel': 'taqarrab_azkar_channel',
              'conditionSatisfied': false,
              'isNextActive': true,
            },
            {
              'id': 'daily_wird_night_reminder',
              'type': 'wird',
              'triggerEpoch': DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch,
              'channel': 'taqarrab_wird_channel',
              'conditionSatisfied': true,
              'isNextActive': false,
            },
          ];
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('native_adhan_bridge'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.taqarrab.quran/native_reminders'),
      null,
    );
  });

  Widget buildTestWidget({
    required Widget child,
    required double width,
    required double height,
    double textScale = 1.0,
  }) {
    return GetMaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('RenderFlex Overflow Regression Tests', () {
    testWidgets('ZikrImageShareDialog renders without overflow on 320dp width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const ZikrImageShareDialog(
            zikrText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            categoryTitle: 'أذكار الصباح والمساء',
            virtue: 'كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
          ),
          width: 320,
          height: 640,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تصميم بطاقة الذكر'), findsOneWidget);
      expect(find.text('كحلي إسلامي'), findsOneWidget);
      expect(find.text('مخطوطة عتيقة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ZikrImageShareDialog renders without overflow with large text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const ZikrImageShareDialog(
            zikrText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            categoryTitle: 'أذكار الصباح والمساء',
            virtue: 'كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
          ),
          width: 360,
          height: 640,
          textScale: 1.4,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdhanDebugView renders without overflow on 320dp width and textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const AdhanDebugView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RemindersDebugView renders without overflow on 320dp width and textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RemindersDebugView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
