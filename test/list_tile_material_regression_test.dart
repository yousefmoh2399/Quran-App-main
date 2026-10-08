import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_view_data.dart';

void main() {
  group('ListTile Material Regression Tests', () {
    testWidgets('PrayerTimeItem renders without ListTile background assertion (isCurrent: true)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrayerTimeItem(
              title: 'الفجر',
              time: '04:30',
              isCurrent: true,
            ),
          ),
        ),
      );

      // Verify no assertion was thrown
      expect(tester.takeException(), isNull);
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('04:30'), findsOneWidget);
    });

    testWidgets('PrayerTimeItem renders without ListTile background assertion (isCurrent: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrayerTimeItem(
              title: 'الظهر',
              time: '12:00',
              isCurrent: false,
            ),
          ),
        ),
      );

      // Verify no assertion was thrown
      expect(tester.takeException(), isNull);
      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('CheckboxListTile inside DecoratedBox wrapped in Material passes framework check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16211D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  title: const Text('صلاة الشفع والوتر'),
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('صلاة الشفع والوتر'), findsOneWidget);
    });

    testWidgets('SwitchListTile inside DecoratedBox wrapped in Material passes framework check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16211D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  title: const Text('دعاء ما بعد الأذان'),
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('دعاء ما بعد الأذان'), findsOneWidget);
    });

    testWidgets('RadioListTile inside DecoratedBox wrapped in Material passes framework check', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16211D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: RadioListTile<String>(
                  value: 'adhan',
                  groupValue: 'adhan',
                  title: const Text('صوت الأذان'),
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('صوت الأذان'), findsOneWidget);
    });
  });
}
