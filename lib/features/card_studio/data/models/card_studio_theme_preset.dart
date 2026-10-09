import 'package:flutter/material.dart';

/// Aspect ratio formats for generating social cards
enum CardAspectRatio {
  story(
    ratio: 9 / 16,
    label: 'حالة / ستوري',
    sublabel: '9:16 (واتساب، إنستغرام)',
    icon: Icons.stay_current_portrait_rounded,
    targetWidth: 1080,
    targetHeight: 1920,
  ),
  square(
    ratio: 1 / 1,
    label: 'مربع',
    sublabel: '1:1 (منشور، بروفايل)',
    icon: Icons.crop_square_rounded,
    targetWidth: 1080,
    targetHeight: 1080,
  ),
  card(
    ratio: 4 / 5,
    label: 'بطاقة طولية',
    sublabel: '4:5 (محادثات ومنشورات)',
    icon: Icons.crop_portrait_rounded,
    targetWidth: 1080,
    targetHeight: 1350,
  );

  final double ratio;
  final String label;
  final String sublabel;
  final IconData icon;
  final double targetWidth;
  final double targetHeight;

  const CardAspectRatio({
    required this.ratio,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.targetWidth,
    required this.targetHeight,
  });
}

/// Islamic vector decorative frame styles
enum CardIslamicFrameStyle {
  andalusian('أندلسي ملكي', 'نجوم ثمانية وزخارف أندلسية بالأركان'),
  mihrab('محراب عثماني', 'قوس المحراب مع حلية علوية مذهبة'),
  classic('كلاسيكي مذهب', 'إطار ذهبي مزدوج مع زوايا هندسية'),
  none('عصري هادئ', 'تركيز كامل على جمال الخط والآية');

  final String title;
  final String description;

  const CardIslamicFrameStyle(this.title, this.description);
}

/// Available typography font families
enum CardStudioFontFamily {
  uthman('خط المصحف', 'uthman'),
  amiri('خط الثلث والنسخ', 'Amiri'),
  cairo('خط كوفي عصري', 'Cairo');

  final String label;
  final String fontName;

  const CardStudioFontFamily(this.label, this.fontName);
}

/// Rich offline visual presets for Islamic card studio
class CardStudioThemePreset {
  final String id;
  final String title;
  final String description;
  final List<Color> bgGradient;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color borderColor;
  final bool isDark;

  const CardStudioThemePreset({
    required this.id,
    required this.title,
    required this.description,
    required this.bgGradient,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.borderColor,
    this.isDark = true,
  });

  /// 1. Warm Antique Parchment (الورق الدافئ القديم)
  static const parchment = CardStudioThemePreset(
    id: 'parchment',
    title: 'ورق دافئ قديم',
    description: 'مخطوطات عتيقة مريحة للعين',
    bgGradient: [Color(0xFFF7F1DF), Color(0xFFEADFCA)],
    textColor: Color(0xFF2C2016),
    secondaryTextColor: Color(0xFF735C45),
    accentColor: Color(0xFFB8892B),
    borderColor: Color(0xFFB8892B),
    isDark: false,
  );

  /// 2. Royal Islamic Emerald (الزمردي الملكي المذهب)
  static const emerald = CardStudioThemePreset(
    id: 'emerald',
    title: 'زمردي ملكي',
    description: 'أخضر الحرمين مع لمسات ذهبية',
    bgGradient: [Color(0xFF0C3829), Color(0xFF041811)],
    textColor: Color(0xFFFAF7EF),
    secondaryTextColor: Color(0xFFDFD7C2),
    accentColor: Color(0xFFE5C058),
    borderColor: Color(0xFFD4AF37),
    isDark: true,
  );

  /// 3. Midnight Celestial (كحلي ليلي نجمي)
  static const midnight = CardStudioThemePreset(
    id: 'midnight',
    title: 'كحلي ليلي',
    description: 'سماء صافية وهدوء روحاني',
    bgGradient: [Color(0xFF0F223D), Color(0xFF060E1A)],
    textColor: Color(0xFFF8FAFC),
    secondaryTextColor: Color(0xFFCBD5E1),
    accentColor: Color(0xFF7DD3FC),
    borderColor: Color(0xFF38BDF8),
    isDark: true,
  );

  /// 4. Pure Haramain Marble (رخام الحرمين الشريفين)
  static const marble = CardStudioThemePreset(
    id: 'marble',
    title: 'رخام الحرمين',
    description: 'أبيض ناصع مع زخرفة ذهبية فاخرة',
    bgGradient: [Color(0xFFFFFFFF), Color(0xFFF5F2EA)],
    textColor: Color(0xFF1E2824),
    secondaryTextColor: Color(0xFF637069),
    accentColor: Color(0xFFB8892B),
    borderColor: Color(0xFFD9C38F),
    isDark: false,
  );

  /// 5. Obsidian Charcoal (فحم أندلسي معتق)
  static const charcoal = CardStudioThemePreset(
    id: 'charcoal',
    title: 'فحم أندلسي',
    description: 'أسود فاحم ملوكي مع ذهب دافئ',
    bgGradient: [Color(0xFF1C1B1A), Color(0xFF0B0B0A)],
    textColor: Color(0xFFEDE8DF),
    secondaryTextColor: Color(0xFFA89F91),
    accentColor: Color(0xFFF5BE47),
    borderColor: Color(0xFFD4AF37),
    isDark: true,
  );

  static const List<CardStudioThemePreset> presets = [
    parchment,
    emerald,
    midnight,
    marble,
    charcoal,
  ];

  static CardStudioThemePreset fromId(String id) {
    return presets.firstWhere(
      (p) => p.id == id,
      orElse: () => parchment,
    );
  }
}
