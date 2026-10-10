import 'package:flutter/material.dart';

enum PropheticFoodCategory {
  quranic, // مذكورة في القرآن
  sunnah, // مأثورة في السنة النبوية
  remedy, // علاج واستشفاء نبوي
}

extension PropheticFoodCategoryExtension on PropheticFoodCategory {
  String get displayName {
    switch (this) {
      case PropheticFoodCategory.quranic:
        return 'أغذية قرآنية';
      case PropheticFoodCategory.sunnah:
        return 'هدي نبوي وسنة';
      case PropheticFoodCategory.remedy:
        return 'استشفاء وعلاج';
    }
  }
}

class PropheticRecipe {
  final String title;
  final String bestTimeToConsume; // أفضل وقت للتناول (مثال: على الريق صباحاً)
  final List<String> ingredients; // المكونات
  final List<String> steps; // خطوات التحضير
  final String healthBenefit; // الفائدة الصحية المستهدفة

  const PropheticRecipe({
    required this.title,
    required this.bestTimeToConsume,
    required this.ingredients,
    required this.steps,
    required this.healthBenefit,
  });
}

class PropheticFood {
  final int id;
  final String name;
  final PropheticFoodCategory category;
  final IconData icon;
  final String quranOrHadithText;
  final String reference;
  final String propheticGuidance; // الهدي النبوي في تناوله
  final List<String> scientificBenefits; // الفوائد الطبية المثبتة علمياً
  final List<PropheticRecipe> recipes; // وصفات منزلية مجربة

  const PropheticFood({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.quranOrHadithText,
    required this.reference,
    required this.propheticGuidance,
    required this.scientificBenefits,
    this.recipes = const [],
  });
}
