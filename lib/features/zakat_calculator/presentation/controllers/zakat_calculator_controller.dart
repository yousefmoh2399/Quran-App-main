import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/util/routes/routes.dart';
import '../../data/models/salary_zakat_model.dart';
import '../../data/services/zakat_calculator_service.dart';

class ZakatCalculatorController extends GetxController {
  final ZakatCalculatorService _service = ZakatCalculatorService.instance;

  // Controllers for Salary tab
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController goldPriceController = TextEditingController(text: '3600');
  final TextEditingController debtsController = TextEditingController();

  // Controllers for Comprehensive Mal tab
  final TextEditingController cashController = TextEditingController();
  final TextEditingController goldValueController = TextEditingController();
  final TextEditingController tradeGoodsController = TextEditingController();
  final TextEditingController malDebtsController = TextEditingController();
  final TextEditingController malGoldPriceController = TextEditingController(text: '3600');

  // Controllers for Fitr tab
  final TextEditingController fitrPriceController = TextEditingController(text: '35');
  final RxInt fitrFamilyMembers = 4.obs;

  // Observables
  final Rx<GoldKarat> selectedKarat = GoldKarat.karat21.obs;
  final Rx<SalaryCalculationType> calculationType = SalaryCalculationType.yearlySavings.obs;
  late final Rx<SalaryZakatResult> salaryResult;
  final RxDouble customCharityAmount = 50.0.obs;
  final RxInt selectedCharityChoice = 1.obs; // 1: 1%, 2: 2%, 3: 2.5%, 4: custom

  @override
  void onInit() {
    super.onInit();
    salaryResult = _service.calculateSalaryZakat(
      amountEntered: 0,
      calculationType: calculationType.value,
      goldKarat: selectedKarat.value,
      goldPricePerGram: double.tryParse(goldPriceController.text) ?? 3600.0,
      deductibleDebts: 0,
    ).obs;

    _loadSavedSettings();

    salaryController.addListener(recalculateSalaryZakat);
    goldPriceController.addListener(recalculateSalaryZakat);
    debtsController.addListener(recalculateSalaryZakat);
  }

  @override
  void onClose() {
    salaryController.dispose();
    goldPriceController.dispose();
    debtsController.dispose();
    cashController.dispose();
    goldValueController.dispose();
    tradeGoodsController.dispose();
    malDebtsController.dispose();
    malGoldPriceController.dispose();
    fitrPriceController.dispose();
    super.onClose();
  }

  Future<void> _loadSavedSettings() async {
    final settings = await _service.loadSettings();
    final price = settings['goldPrice'] as double;
    final karat = settings['goldKarat'] as GoldKarat;
    final salary = settings['salary'] as double;

    selectedKarat.value = karat;
    goldPriceController.text = price.toStringAsFixed(0);
    malGoldPriceController.text = price.toStringAsFixed(0);
    if (salary > 0) {
      salaryController.text = salary.toStringAsFixed(0);
    }
    recalculateSalaryZakat();
  }

  void recalculateSalaryZakat() {
    final amount = double.tryParse(salaryController.text.trim()) ?? 0.0;
    final goldPrice = double.tryParse(goldPriceController.text.trim()) ?? 3600.0;
    final debts = double.tryParse(debtsController.text.trim()) ?? 0.0;

    salaryResult.value = _service.calculateSalaryZakat(
      amountEntered: amount,
      calculationType: calculationType.value,
      goldKarat: selectedKarat.value,
      goldPricePerGram: goldPrice,
      deductibleDebts: debts,
    );

    // Update custom charity default when amount changes
    if (salaryResult.value.recommendedMonthlyAmount > 0) {
      customCharityAmount.value = salaryResult.value.recommendedMonthlyAmount;
    }

    // Persist settings in background
    _service.saveSettings(
      goldPrice: goldPrice,
      goldKarat: selectedKarat.value,
      salary: amount,
    );
  }

  void setGoldKarat(GoldKarat karat) {
    selectedKarat.value = karat;
    // Suggest appropriate default price for 24k vs 21k if price is default
    if (karat == GoldKarat.karat24 && goldPriceController.text == '3600') {
      goldPriceController.text = '4114';
    } else if (karat == GoldKarat.karat21 && goldPriceController.text == '4114') {
      goldPriceController.text = '3600';
    }
    recalculateSalaryZakat();
  }

  void setCalculationType(SalaryCalculationType type) {
    calculationType.value = type;
    recalculateSalaryZakat();
  }

  void selectCharityChoice(int choice) {
    selectedCharityChoice.value = choice;
  }

  void setCustomCharityAmount(double amount) {
    customCharityAmount.value = amount;
    selectedCharityChoice.value = 4;
  }

  void incrementFitrMembers() {
    fitrFamilyMembers.value++;
  }

  void decrementFitrMembers() {
    if (fitrFamilyMembers.value > 1) {
      fitrFamilyMembers.value--;
    }
  }

  Map<String, dynamic> getComprehensiveMalResult() {
    final cash = double.tryParse(cashController.text.trim()) ?? 0.0;
    final gold = double.tryParse(goldValueController.text.trim()) ?? 0.0;
    final trade = double.tryParse(tradeGoodsController.text.trim()) ?? 0.0;
    final debts = double.tryParse(malDebtsController.text.trim()) ?? 0.0;
    final price = double.tryParse(malGoldPriceController.text.trim()) ?? 3600.0;

    return _service.calculateComprehensiveMal(
      cashAndSavings: cash,
      goldAndSilverValue: gold,
      tradeGoodsValue: trade,
      deductibleDebts: debts,
      goldGramPrice: price,
      goldKarat: selectedKarat.value,
    );
  }

  Map<String, dynamic> getFitrResult() {
    final price = double.tryParse(fitrPriceController.text.trim()) ?? 35.0;
    return _service.calculateFitr(
      familyMembers: fitrFamilyMembers.value,
      pricePerPerson: price,
    );
  }

  Future<void> copySummary() async {
    final res = salaryResult.value;
    final String summary;
    if (res.isZakatObligatory) {
      summary = 'حاسبة الزكاة الذكية - تطبيق تقرّب\n'
          'الوعاء الزكوي: ${res.netWealthSubjectToZakat.toStringAsFixed(0)}\n'
          'قيمة النصاب (85 جرام ذهب): ${res.nisabThresholdAmount.toStringAsFixed(0)}\n'
          'الزكاة المستحقة شرعاً (2.5%): ${res.zakatDue.toStringAsFixed(2)}\n'
          '«خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِم بِهَا»';
    } else {
      summary = 'حاسبة الزكاة والصدقات - تطبيق تقرّب\n'
          'المبلغ المدخل: ${res.amountEntered.toStringAsFixed(0)}\n'
          'النصاب الشرعي (85 جرام ذهب): ${res.nisabThresholdAmount.toStringAsFixed(0)}\n'
          'الحالة: المال لم يبلغ النصاب، ولا تجب الزكاة شرعاً.\n'
          'مقترح الصدقة الشهرية لبركة المال: ${res.suggestedCharity1Percent.toStringAsFixed(0)} إلى ${res.recommendedMonthlyAmount.toStringAsFixed(0)}\n'
          '«مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ»';
    }
    await Clipboard.setData(ClipboardData(text: summary));
    Get.snackbar(
      'تم النسخ بنجاح 📋',
      'تم نسخ ملخص الحساب الشرعي للحافظة',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void navigateToSadaqahReminders() {
    Get.toNamed(AppRoutes.sadaqahSettings);
  }
}
