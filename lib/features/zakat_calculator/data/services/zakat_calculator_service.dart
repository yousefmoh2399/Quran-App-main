import 'package:shared_preferences/shared_preferences.dart';
import '../models/salary_zakat_model.dart';

class ZakatCalculatorService {
  ZakatCalculatorService._();
  static final ZakatCalculatorService instance = ZakatCalculatorService._();

  static const String _kLastGoldPrice = 'zakat_last_gold_price';
  static const String _kLastGoldKarat = 'zakat_last_gold_karat';
  static const String _kLastSalary = 'zakat_last_salary';

  /// Default baseline gold price per gram in EGP/local unit
  static const double defaultGoldGramPrice21 = 3600.0;
  static const double defaultGoldGramPrice24 = 4114.0;

  /// Calculate Salary / Income Zakat
  SalaryZakatResult calculateSalaryZakat({
    required double amountEntered,
    required SalaryCalculationType calculationType,
    required GoldKarat goldKarat,
    required double goldPricePerGram,
    double deductibleDebts = 0.0,
  }) {
    final effectivePrice = goldPricePerGram > 0
        ? goldPricePerGram
        : (goldKarat == GoldKarat.karat24 ? defaultGoldGramPrice24 : defaultGoldGramPrice21);

    // Calculate Nisab based on Karat purity (85g pure 24k gold standard)
    // For 21k: 85 * (24/21) = ~97.14 grams
    final nisabGrams = goldKarat.nisabGrams;
    final nisabThresholdAmount = nisabGrams * effectivePrice;

    // Deduct debts from wealth
    final netWealth = (amountEntered - deductibleDebts).clamp(0.0, double.infinity);

    // Obligation check
    final isZakatObligatory = netWealth >= nisabThresholdAmount && nisabThresholdAmount > 0;
    final zakatDue = isZakatObligatory ? (netWealth * 0.025) : 0.0;

    // Smart Voluntary Charity (الصدقة المستحبة) calculations
    final baseAmountForCharity = amountEntered.clamp(0.0, double.infinity);
    final charity1Percent = baseAmountForCharity * 0.01;
    final charity2Percent = baseAmountForCharity * 0.02;
    final charity2HalfPercent = baseAmountForCharity * 0.025;

    // Recommended rounded monthly amount
    double recommended = 50.0;
    if (baseAmountForCharity > 0) {
      if (baseAmountForCharity <= 3000) {
        recommended = 30.0;
      } else if (baseAmountForCharity <= 6000) {
        recommended = 50.0;
      } else if (baseAmountForCharity <= 12000) {
        recommended = 100.0;
      } else if (baseAmountForCharity <= 25000) {
        recommended = 200.0;
      } else {
        recommended = (charity1Percent / 10).round() * 10.0;
      }
    }

    return SalaryZakatResult(
      amountEntered: amountEntered,
      calculationType: calculationType,
      goldKarat: goldKarat,
      goldPricePerGram: effectivePrice,
      nisabThresholdAmount: nisabThresholdAmount,
      isZakatObligatory: isZakatObligatory,
      zakatDue: zakatDue,
      netWealthSubjectToZakat: netWealth,
      deductibleDebts: deductibleDebts,
      suggestedCharity1Percent: charity1Percent,
      suggestedCharity2Percent: charity2Percent,
      suggestedCharity2HalfPercent: charity2HalfPercent,
      recommendedMonthlyAmount: recommended,
    );
  }

  /// Comprehensive Zakat al-Mal (Cash, Gold, Trade, Debts)
  Map<String, dynamic> calculateComprehensiveMal({
    required double cashAndSavings,
    required double goldAndSilverValue,
    required double tradeGoodsValue,
    required double deductibleDebts,
    required double goldGramPrice,
    GoldKarat goldKarat = GoldKarat.karat21,
  }) {
    final effectivePrice = goldGramPrice > 0 ? goldGramPrice : defaultGoldGramPrice21;
    final nisabThreshold = goldKarat.nisabGrams * effectivePrice;
    final totalAssets = cashAndSavings + goldAndSilverValue + tradeGoodsValue;
    final netWealth = (totalAssets - deductibleDebts).clamp(0.0, double.infinity);

    final isEligible = netWealth >= nisabThreshold && nisabThreshold > 0;
    final zakatDue = isEligible ? (netWealth * 0.025) : 0.0;

    return {
      'totalAssets': totalAssets,
      'netWealth': netWealth,
      'nisabThreshold': nisabThreshold,
      'isEligible': isEligible,
      'zakatDue': zakatDue,
      'goldGramPrice': effectivePrice,
      'goldKarat': goldKarat,
    };
  }

  /// Zakat al-Fitr (Per Person)
  Map<String, dynamic> calculateFitr({
    required int familyMembers,
    required double pricePerPerson,
  }) {
    final total = familyMembers * pricePerPerson;
    return {
      'familyMembers': familyMembers,
      'pricePerPerson': pricePerPerson,
      'totalZakat': total,
    };
  }

  // --------------------------------------------------------------------------
  // Preferences persistence
  // --------------------------------------------------------------------------

  Future<void> saveSettings({
    required double goldPrice,
    required GoldKarat goldKarat,
    required double salary,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastGoldPrice, goldPrice);
    await prefs.setString(_kLastGoldKarat, goldKarat.name);
    await prefs.setDouble(_kLastSalary, salary);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final goldPrice = prefs.getDouble(_kLastGoldPrice) ?? defaultGoldGramPrice21;
    final karatString = prefs.getString(_kLastGoldKarat) ?? GoldKarat.karat21.name;
    final salary = prefs.getDouble(_kLastSalary) ?? 0.0;

    final karat = GoldKarat.values.firstWhere(
      (k) => k.name == karatString,
      orElse: () => GoldKarat.karat21,
    );

    return {
      'goldPrice': goldPrice,
      'goldKarat': karat,
      'salary': salary,
    };
  }
}
