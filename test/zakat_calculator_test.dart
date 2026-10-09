import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/features/zakat_calculator/data/models/salary_zakat_model.dart';
import 'package:quran_app_android/features/zakat_calculator/data/services/zakat_calculator_service.dart';
import 'package:quran_app_android/features/zakat_calculator/presentation/controllers/zakat_calculator_controller.dart';
import 'package:quran_app_android/features/zakat_calculator/presentation/views/zakat_calculator_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('ZakatCalculatorService Logic Unit Tests', () {
    final service = ZakatCalculatorService.instance;

    test('24k Gold Nisab calculation and obligation threshold', () {
      // 85 grams of 24k gold at 4000 per gram = 340,000
      final resultObligatory = service.calculateSalaryZakat(
        amountEntered: 400000,
        calculationType: SalaryCalculationType.yearlySavings,
        goldKarat: GoldKarat.karat24,
        goldPricePerGram: 4000,
      );

      expect(resultObligatory.nisabThresholdAmount, equals(340000.0));
      expect(resultObligatory.isZakatObligatory, isTrue);
      expect(resultObligatory.zakatDue, equals(400000 * 0.025)); // 10,000
      expect(resultObligatory.netWealthSubjectToZakat, equals(400000.0));
    });

    test('21k Gold Nisab and Below-Nisab Charity Suggestions', () {
      // 21k Nisab is ~97.1428 grams. At 3600/g = ~349,714.28
      final resultBelowNisab = service.calculateSalaryZakat(
        amountEntered: 10000,
        calculationType: SalaryCalculationType.monthlySalary,
        goldKarat: GoldKarat.karat21,
        goldPricePerGram: 3600,
      );

      expect(resultBelowNisab.isZakatObligatory, isFalse);
      expect(resultBelowNisab.zakatDue, equals(0.0));
      expect(resultBelowNisab.shortfallToNisab, greaterThan(300000.0));

      // Voluntary Charity (الصدقة المستحبة)
      expect(resultBelowNisab.suggestedCharity1Percent, equals(100.0)); // 1% of 10,000
      expect(resultBelowNisab.suggestedCharity2Percent, equals(200.0)); // 2% of 10,000
      expect(resultBelowNisab.suggestedCharity2HalfPercent, equals(250.0)); // 2.5% of 10,000
      expect(resultBelowNisab.recommendedMonthlyAmount, equals(100.0));
    });

    test('Deductible debts properly lower net wealth below Nisab', () {
      // Wealth = 400,000, Debts = 100,000 -> Net = 300,000 (Below Nisab of 340,000)
      final resultWithDebts = service.calculateSalaryZakat(
        amountEntered: 400000,
        calculationType: SalaryCalculationType.yearlySavings,
        goldKarat: GoldKarat.karat24,
        goldPricePerGram: 4000,
        deductibleDebts: 100000,
      );

      expect(resultWithDebts.netWealthSubjectToZakat, equals(300000.0));
      expect(resultWithDebts.isZakatObligatory, isFalse);
      expect(resultWithDebts.zakatDue, equals(0.0));
    });

    test('Comprehensive Zakat al-Mal calculation', () {
      final mal = service.calculateComprehensiveMal(
        cashAndSavings: 200000,
        goldAndSilverValue: 150000,
        tradeGoodsValue: 50000,
        deductibleDebts: 20000,
        goldGramPrice: 3600,
        goldKarat: GoldKarat.karat21,
      );

      expect(mal['totalAssets'], equals(400000.0));
      expect(mal['netWealth'], equals(380000.0));
      expect(mal['isEligible'], isTrue);
      expect(mal['zakatDue'], equals(380000.0 * 0.025)); // 9,500
    });

    test('Zakat al-Fitr calculation', () {
      final fitr = service.calculateFitr(familyMembers: 5, pricePerPerson: 40);
      expect(fitr['familyMembers'], equals(5));
      expect(fitr['totalZakat'], equals(200.0));
    });
  });

  group('ZakatCalculatorController Unit Tests', () {
    test('recalculateSalaryZakat updates reactive state properly', () {
      final controller = Get.put(ZakatCalculatorController());

      controller.salaryController.text = '5000';
      controller.goldPriceController.text = '3600';
      controller.recalculateSalaryZakat();

      final res = controller.salaryResult.value;
      expect(res.amountEntered, equals(5000.0));
      expect(res.isZakatObligatory, isFalse);
      expect(res.suggestedCharity1Percent, equals(50.0));
      expect(res.suggestedCharity2Percent, equals(100.0));

      controller.setGoldKarat(GoldKarat.karat24);
      expect(controller.selectedKarat.value, equals(GoldKarat.karat24));

      controller.selectCharityChoice(2);
      expect(controller.selectedCharityChoice.value, equals(2));

      controller.setCustomCharityAmount(150.0);
      expect(controller.customCharityAmount.value, equals(150.0));
      expect(controller.selectedCharityChoice.value, equals(4));
    });
  });

  group('ZakatCalculatorView Widget Tests', () {
    testWidgets('renders all tabs and dynamic inputs cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ZakatCalculatorView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar title
      expect(find.text('حاسبة الزكاة والصدقات الذكية'), findsOneWidget);

      // Check Tabs
      expect(find.text('زكاة المرتب'), findsOneWidget);
      expect(find.text('زكاة المال والتجارة'), findsOneWidget);
      expect(find.text('زكاة الفطر'), findsOneWidget);

      // Check initial empty prompt card
      expect(find.text('حاسبة زكاة المرتب والمدخرات'), findsOneWidget);

      // Enter salary below nisab (e.g. 8000)
      final controller = Get.find<ZakatCalculatorController>();
      controller.salaryController.text = '8000';
      controller.goldPriceController.text = '3600';
      await tester.pumpAndSettle();

      // Must show Below Nisab message
      expect(find.text('المال دون النصاب الشرعي'), findsOneWidget);
      expect(find.text('لا تجب عليك الزكاة شرعاً بحمد الله'), findsOneWidget);

      // Must show the Charity Suggestion Card
      expect(find.text('باب الصدقة والبركة المفتوح 🌿'), findsOneWidget);
      expect(find.text('صدقة التيسير (1% من المرتب)'), findsOneWidget);
      expect(find.text('صدقة النماء والبركة (2% من المرتب)'), findsOneWidget);
      expect(find.text('ضبط تذكير شهري بالصدقة في التطبيق'), findsOneWidget);

      // Switch to obligatory amount (e.g. 500,000)
      controller.salaryController.text = '500000';
      await tester.pumpAndSettle();

      // Must show Obligatory Zakat message
      expect(find.text('بلغ مالك النصاب الشرعي'), findsOneWidget);
      expect(find.text('مقدار الزكاة الواجب إخراجها شرعاً (2.5% = ربع العُشر):'), findsOneWidget);
    });
  });
}
