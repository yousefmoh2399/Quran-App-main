import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/nameOfAllah/data/models/names_of_allah_model.dart';
import 'package:quran_app_android/features/onboarding/data/models/onboarding_model.dart';

void main() {
  group('Unit Tests', () {
    test('NamesOfAllahModel correctly parses json', () {
      final json = {
        'name': 'الله',
        'text': 'هو الاسم الجامع لمعاني الألوهية',
      };
      final model = NamesOfAllahModel.fromJson(json);
      expect(model.name, equals('الله'));
      expect(model.text, equals('هو الاسم الجامع لمعاني الألوهية'));
    });

    test('onboardingData list contains expected items', () {
      expect(onboardingData, isNotEmpty);
      expect(onboardingData.length, greaterThanOrEqualTo(3));
      expect(onboardingData.first.title, contains('تلاوة'));
    });
  });

  group('Widget Tests', () {
    testWidgets('Smoke test renders widget without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'تطبيق تقرّب',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      );

      expect(find.text('تطبيق تقرّب'), findsOneWidget);
    });
  });
}
