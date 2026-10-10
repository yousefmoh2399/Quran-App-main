import 'package:flutter/material.dart';

enum ZikrType {
  tasbeeh, // سبحان الله
  tahmeed, // الحمد لله
  tahlil, // لا إله إلا الله
  takbeer, // الله أكبر
  salawat, // الصلاة على النبي ﷺ
  istighfar, // أستغفر الله
  hawqalah, // لا حول ولا قوة إلا بالله
}

extension ZikrTypeExtension on ZikrType {
  String get id => name;

  String get displayName {
    switch (this) {
      case ZikrType.tasbeeh:
        return 'التسبيح';
      case ZikrType.tahmeed:
        return 'التحميد';
      case ZikrType.tahlil:
        return 'التهليل';
      case ZikrType.takbeer:
        return 'التكبير';
      case ZikrType.salawat:
        return 'الصلاة على النبي ﷺ';
      case ZikrType.istighfar:
        return 'الاستغفار';
      case ZikrType.hawqalah:
        return 'الحوقلة';
    }
  }

  String get zikrText {
    switch (this) {
      case ZikrType.tasbeeh:
        return 'سُبْحَانَ اللَّهِ';
      case ZikrType.tahmeed:
        return 'الْحَمْدُ لِلَّهِ';
      case ZikrType.tahlil:
        return 'لَا إِلَهَ إِلَّا اللَّهُ';
      case ZikrType.takbeer:
        return 'اللَّهُ أَكْبَرُ';
      case ZikrType.salawat:
        return 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ';
      case ZikrType.istighfar:
        return 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ';
      case ZikrType.hawqalah:
        return 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ';
    }
  }

  String get virtue {
    switch (this) {
      case ZikrType.tasbeeh:
        return 'تُغرس بها شجرة في الجنة وتُحط الخطايا وإن كانت مثل زبد البحر';
      case ZikrType.tahmeed:
        return 'تملأ الميزان بالحنث والخيرات، وأحب الكلام إلى الله';
      case ZikrType.tahlil:
        return 'أفضل ما قال النبيون، وعروة التوحيد الوثقى ونجاة من النار';
      case ZikrType.takbeer:
        return 'ترفع الدرجات وتكبر شأن العبد عند مولاه في السماوات';
      case ZikrType.salawat:
        return 'من صلى على النبي ﷺ واحدة صلى الله عليه بها عشراً وحُطت خطاياه';
      case ZikrType.istighfar:
        return 'جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً ورزقه من حيث لا يحتسب';
      case ZikrType.hawqalah:
        return 'كنز من كنوز الجنة ودواء لتسعة وتسعين داء أيسرها الهم';
    }
  }

  IconData get icon {
    switch (this) {
      case ZikrType.tasbeeh:
        return Icons.eco_rounded;
      case ZikrType.tahmeed:
        return Icons.favorite_rounded;
      case ZikrType.tahlil:
        return Icons.lightbulb_rounded;
      case ZikrType.takbeer:
        return Icons.military_tech_rounded;
      case ZikrType.salawat:
        return Icons.star_rounded;
      case ZikrType.istighfar:
        return Icons.water_drop_rounded;
      case ZikrType.hawqalah:
        return Icons.shield_rounded;
    }
  }
}

class SpiritualBadge {
  final String id;
  final String title;
  final String description;
  final int requiredCount;
  final ZikrType? specificType; // null means total lifetime zikr
  final IconData icon;

  const SpiritualBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredCount,
    this.specificType,
    required this.icon,
  });

  bool isUnlocked(int currentCount) => currentCount >= requiredCount;
}

class SpiritualGardenSummary {
  final int totalCount;
  final int treesCount; // totalCount ~/ 1000
  final int nextTreeProgress; // totalCount % 1000
  final Map<ZikrType, int> counts;

  const SpiritualGardenSummary({
    required this.totalCount,
    required this.treesCount,
    required this.nextTreeProgress,
    required this.counts,
  });
}
