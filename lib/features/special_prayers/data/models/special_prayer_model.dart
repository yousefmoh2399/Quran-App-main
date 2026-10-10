import 'package:flutter/material.dart';

enum SpecialPrayerCategory {
  occasional, // صلوات المناسبات والنوازل (جنازة، كسوف وخسوف)
  personal, // صلوات الحاجات والتوبة (استخارة، توبة، حاجة)
  sujood, // سجدات الشكر والتلاوة والسهو
}

extension SpecialPrayerCategoryExtension on SpecialPrayerCategory {
  String get displayName {
    switch (this) {
      case SpecialPrayerCategory.occasional:
        return 'الجنائز والمناسبات';
      case SpecialPrayerCategory.personal:
        return 'الاستخارة والحاجات';
      case SpecialPrayerCategory.sujood:
        return 'أحكام السجدات';
    }
  }
}

class PrayerStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? detailedDua;
  final String? reference;

  const PrayerStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.detailedDua,
    this.reference,
  });
}

class SpecialPrayer {
  final int id;
  final String title;
  final String subtitle;
  final SpecialPrayerCategory category;
  final IconData icon;
  final String definitionAndVirtue;
  final List<String> conditionsAndRulings;
  final List<PrayerStep> steps;
  final List<String> commonMistakes;

  const SpecialPrayer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.definitionAndVirtue,
    required this.conditionsAndRulings,
    required this.steps,
    this.commonMistakes = const [],
  });
}
