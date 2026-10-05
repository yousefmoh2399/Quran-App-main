import 'package:flutter/material.dart';

enum ZikrContextType {
  morning('أذكار الصباح', Icons.wb_twilight_rounded, Color(0xFFD35400)),
  evening('أذكار المساء', Icons.nights_stay_rounded, Color(0xFF16253D)),
  sleep('أذكار النوم', Icons.bedtime_rounded, Color(0xFF4A148C)),
  wakeUp('الاستيقاظ من النوم', Icons.wb_sunny_rounded, Color(0xFFB8892B)),
  travel('ركوب الدابة والسفر', Icons.directions_car_rounded, Color(0xFF0F5C4A)),
  rain('عند نزول المطر', Icons.water_drop_rounded, Color(0xFF1976D2)),
  distress('تفريج الهم والكرب', Icons.healing_rounded, Color(0xFF00796B));

  final String title;
  final IconData icon;
  final Color color;

  const ZikrContextType(this.title, this.icon, this.color);
}

class ContextualZikr {
  final ZikrContextType type;
  final String text;
  final String? virture;
  final int count;

  const ContextualZikr({
    required this.type,
    required this.text,
    this.virture,
    this.count = 1,
  });
}

class SmartAzkarService {
  SmartAzkarService._();
  static final SmartAzkarService instance = SmartAzkarService._();

  static const List<ContextualZikr> _library = [
    // Morning
    ContextualZikr(
      type: ZikrContextType.morning,
      text: 'أَصْبَحْنَا وَأَصْبَحَ المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      virture: 'من أذكار الصباح المباركة',
      count: 1,
    ),
    ContextualZikr(
      type: ZikrContextType.morning,
      text: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ',
      virture: 'سيد الاستغفار: من قاله موقناً به فمات من يومه دخل الجنة',
      count: 1,
    ),

    // Evening
    ContextualZikr(
      type: ZikrContextType.evening,
      text: 'أَمْسَيْنَا وَأَمْسَى المُلْكُ لِلَّهِ، وَالحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      virture: 'من أذكار المساء المباركة',
      count: 1,
    ),
    ContextualZikr(
      type: ZikrContextType.evening,
      text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      virture: 'من قالها ثلاثاً لم يضره شيء حتى يصبح',
      count: 3,
    ),

    // Sleep
    ContextualZikr(
      type: ZikrContextType.sleep,
      text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
      virture: 'سنة نبوية قبل النوم',
      count: 1,
    ),

    // Wake up
    ContextualZikr(
      type: ZikrContextType.wakeUp,
      text: 'الحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      virture: 'ذكر الاستيقاظ من النوم',
      count: 1,
    ),

    // Travel / Riding
    ContextualZikr(
      type: ZikrContextType.travel,
      text: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ',
      virture: 'دعاء ركوب الدابة أو السيارة والسفر',
      count: 1,
    ),

    // Rain
    ContextualZikr(
      type: ZikrContextType.rain,
      text: 'اللَّهُمَّ صَيِّبًا نَافِعًا',
      virture: 'عند نزول الغيث والمطر مستجاب الدعاء',
      count: 1,
    ),

    // Distress
    ContextualZikr(
      type: ZikrContextType.distress,
      text: 'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      virture: 'دعوة ذي النون: ما دعا بها مسلم في كرب إلا استجاب الله له',
      count: 1,
    ),
  ];

  /// Suggests a zikr based on the current time of day
  ContextualZikr getZikrForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return _library.firstWhere((z) => z.type == ZikrContextType.morning);
    } else if (hour >= 16 && hour < 21) {
      return _library.firstWhere((z) => z.type == ZikrContextType.evening);
    } else if (hour >= 21 || hour < 5) {
      return _library.firstWhere((z) => z.type == ZikrContextType.sleep);
    } else {
      return _library.firstWhere((z) => z.type == ZikrContextType.wakeUp);
    }
  }

  /// Get azkar for a given context type
  List<ContextualZikr> getAzkarForType(ZikrContextType type) {
    return _library.where((z) => z.type == type).toList();
  }
}
