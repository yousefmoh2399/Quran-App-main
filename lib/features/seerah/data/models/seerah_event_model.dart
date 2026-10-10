enum SeerahPeriod {
  preProphethood, // ما قبل البعثة
  makkan, // العهد المكي
  madinan, // العهد المدني
  majorBattles, // الغزوات الكبرى
}

extension SeerahPeriodExtension on SeerahPeriod {
  String get displayName {
    switch (this) {
      case SeerahPeriod.preProphethood:
        return 'ما قبل البعثة';
      case SeerahPeriod.makkan:
        return 'العهد المكي';
      case SeerahPeriod.madinan:
        return 'العهد المدني';
      case SeerahPeriod.majorBattles:
        return 'الغزوات الكبرى';
    }
  }
}

class SeerahEvent {
  final int id;
  final String yearLabel;
  final String title;
  final SeerahPeriod period;
  final String whatHappened; // ماذا حدث؟
  final List<String> keyFigures; // أبطال الموقف
  final String lifeLesson; // الدرس المستفاد لحياتنا اليوم
  final String? quranOrHadithReference;

  const SeerahEvent({
    required this.id,
    required this.yearLabel,
    required this.title,
    required this.period,
    required this.whatHappened,
    required this.keyFigures,
    required this.lifeLesson,
    this.quranOrHadithReference,
  });
}

class PropheticDayHabit {
  final String timeOfDay;
  final String title;
  final String description;
  final String hadithReference;
  final String practicalApplication;

  const PropheticDayHabit({
    required this.timeOfDay,
    required this.title,
    required this.description,
    required this.hadithReference,
    required this.practicalApplication,
  });
}
