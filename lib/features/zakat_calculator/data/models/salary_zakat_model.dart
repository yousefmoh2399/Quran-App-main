enum GoldKarat {
  karat24,
  karat21,
  karat18,
}

extension GoldKaratExtension on GoldKarat {
  String get displayName {
    switch (this) {
      case GoldKarat.karat24:
        return 'عيار 24 (الذهب الخالص)';
      case GoldKarat.karat21:
        return 'عيار 21 (الشائع)';
      case GoldKarat.karat18:
        return 'عيار 18';
    }
  }

  /// Purity factor compared to 24k
  double get purityFactor {
    switch (this) {
      case GoldKarat.karat24:
        return 1.0;
      case GoldKarat.karat21:
        return 21.0 / 24.0; // 0.875
      case GoldKarat.karat18:
        return 18.0 / 24.0; // 0.75
    }
  }

  /// Nisab weight in grams for this karat
  /// Standard Nisab is 85 grams of 24k pure gold.
  /// For 21k, it is 85 / (21/24) = ~97.14 grams.
  /// For 18k, it is 85 / (18/24) = ~113.33 grams.
  double get nisabGrams {
    return 85.0 / purityFactor;
  }
}

/// Mode of salary calculation
enum SalaryCalculationType {
  /// Accumulated yearly savings from salary that completed one lunar year (Hawl)
  yearlySavings,

  /// Direct monthly salary
  monthlySalary,
}

/// Result of Salary / Income Zakat calculation
class SalaryZakatResult {
  final double amountEntered;
  final SalaryCalculationType calculationType;
  final GoldKarat goldKarat;
  final double goldPricePerGram;
  final double nisabThresholdAmount;
  final bool isZakatObligatory;
  final double zakatDue; // 2.5% of net wealth if eligible, otherwise 0
  final double netWealthSubjectToZakat;
  final double deductibleDebts;

  // Voluntary Charity (الصدقة المستحبة) Suggestions when salary is below Nisab
  final double suggestedCharity1Percent;
  final double suggestedCharity2Percent;
  final double suggestedCharity2HalfPercent;
  final double recommendedMonthlyAmount;

  const SalaryZakatResult({
    required this.amountEntered,
    required this.calculationType,
    required this.goldKarat,
    required this.goldPricePerGram,
    required this.nisabThresholdAmount,
    required this.isZakatObligatory,
    required this.zakatDue,
    required this.netWealthSubjectToZakat,
    required this.deductibleDebts,
    required this.suggestedCharity1Percent,
    required this.suggestedCharity2Percent,
    required this.suggestedCharity2HalfPercent,
    required this.recommendedMonthlyAmount,
  });

  /// Short summary message
  String get statusTitle {
    if (amountEntered <= 0) {
      return 'أدخل المرتب أو المدخرات لحساب الزكاة';
    }
    if (isZakatObligatory) {
      return 'تجب عليك الزكاة شرعاً (2.5%)';
    }
    return 'المال دون النصاب • لا تجب الزكاة شرعاً 🌿';
  }

  /// Percentage of reaching Nisab
  double get nisabProgressPercentage {
    if (nisabThresholdAmount <= 0) return 0.0;
    return (netWealthSubjectToZakat / nisabThresholdAmount).clamp(0.0, 1.0);
  }

  /// Remaining amount to reach Nisab
  double get shortfallToNisab {
    if (isZakatObligatory) return 0.0;
    return (nisabThresholdAmount - netWealthSubjectToZakat).clamp(0.0, double.infinity);
  }
}
