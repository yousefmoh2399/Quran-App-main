import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/calendar/data/islamic_calendar_service.dart';
import '../../adhan/presentation/view_model/adhan_view_model.dart';

class RamadanDayInfo {
  final int dayNumber;
  final DateTime gregorianDate;
  final String imsakTime;
  final String fajrTime;
  final String sunriseTime;
  final String dhuhrTime;
  final String asrTime;
  final String maghribTime;
  final String ishaTime;
  final DateTime fajrDateTime;
  final DateTime maghribDateTime;
  final DateTime imsakDateTime;
  final bool isToday;

  const RamadanDayInfo({
    required this.dayNumber,
    required this.gregorianDate,
    required this.imsakTime,
    required this.fajrTime,
    required this.sunriseTime,
    required this.dhuhrTime,
    required this.asrTime,
    required this.maghribTime,
    required this.ishaTime,
    required this.fajrDateTime,
    required this.maghribDateTime,
    required this.imsakDateTime,
    required this.isToday,
  });
}

class RamadanDuaItem {
  final int day;
  final String title;
  final String arabicText;
  final String? virtureOrReference;
  final String category; // 'daily', 'last_ten', 'qunut', 'fasting_sunnah'

  const RamadanDuaItem({
    required this.day,
    required this.title,
    required this.arabicText,
    this.virtureOrReference,
    required this.category,
  });
}

class RamadanService {
  RamadanService._();
  static final RamadanService instance = RamadanService._();

  static const String _kKhatmaTarget = 'ramadan_khatma_target';
  static const String _kKhatmaCompletedPages = 'ramadan_khatma_completed_pages';
  static const String _kKhatmaCurrentPage = 'ramadan_khatma_current_page';
  static const String _kIftarCannonEnabled = 'ramadan_iftar_cannon_enabled';
  static const String _kSuhoorAlertEnabled = 'ramadan_suhoor_alert_enabled';
  static const String _kSuhoorMinutes = 'ramadan_suhoor_minutes_before_fajr';
  static const String _kTaraweehTarget = 'ramadan_taraweeh_target';
  static const String _kTaraweehCurrent = 'ramadan_taraweeh_current';
  static const String _kTaraweehWitr = 'ramadan_taraweeh_witr_done';

  // --------------------------------------------------------------------------
  // 1. Imsakia & Prayer Times Calculations (100% Offline)
  // --------------------------------------------------------------------------

  int getRamadanYear() {
    final todayHijri = IslamicCalendarService.instance.getTodayHijri();
    return (todayHijri.hMonth > 9) ? todayHijri.hYear + 1 : todayHijri.hYear;
  }

  DateTime getRamadanStartDate(int ramadanYear) {
    return IslamicCalendarService.instance.toGregorian(ramadanYear, 9, 1);
  }

  List<RamadanDayInfo> calculate30DaysImsakia({int imsakMinutesBeforeFajr = 15}) {
    final ramadanYear = getRamadanYear();
    final startDate = getRamadanStartDate(ramadanYear);

    double lat = 30.0444;
    double lng = 31.2357;
    try {
      if (Get.isRegistered<AdhanViewModel>()) {
        final adhanVM = Get.find<AdhanViewModel>();
        if (adhanVM.latitude != null && adhanVM.longitude != null) {
          lat = adhanVM.latitude!;
          lng = adhanVM.longitude!;
        }
      }
    } catch (_) {}

    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final now = DateTime.now();
    final list = <RamadanDayInfo>[];

    for (int day = 1; day <= 30; day++) {
      final date = startDate.add(Duration(days: day - 1));
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final pt = PrayerTimes(coordinates, dateComponents, params);

      final imsakDt = pt.fajr.subtract(Duration(minutes: imsakMinutesBeforeFajr));
      final isToday = (now.year == date.year && now.month == date.month && now.day == date.day);

      list.add(RamadanDayInfo(
        dayNumber: day,
        gregorianDate: date,
        imsakTime: _formatTime(imsakDt),
        fajrTime: _formatTime(pt.fajr),
        sunriseTime: _formatTime(pt.sunrise),
        dhuhrTime: _formatTime(pt.dhuhr),
        asrTime: _formatTime(pt.asr),
        maghribTime: _formatTime(pt.maghrib),
        ishaTime: _formatTime(pt.isha),
        fajrDateTime: pt.fajr,
        maghribDateTime: pt.maghrib,
        imsakDateTime: imsakDt,
        isToday: isToday,
      ));
    }

    return list;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = isPm ? 'م' : 'ص';
    return '$h12:$minute $period';
  }

  /// Calculates countdown to next Iftar or Imsak today
  Map<String, dynamic> getNextRamadanEvent() {
    final days = calculate30DaysImsakia();
    final now = DateTime.now();

    final todayInfo = days.firstWhere(
      (d) => d.isToday,
      orElse: () => days.first,
    );

    // If now before today's Imsak -> next is Imsak
    if (now.isBefore(todayInfo.imsakDateTime)) {
      final diff = todayInfo.imsakDateTime.difference(now);
      return {
        'title': 'متبقي على موعد الإمساك',
        'targetTime': todayInfo.imsakDateTime,
        'diff': diff,
        'type': 'imsak',
        'isRamadanToday': true,
      };
    }

    // If now between Imsak and Maghrib -> next is Iftar
    if (now.isBefore(todayInfo.maghribDateTime)) {
      final diff = todayInfo.maghribDateTime.difference(now);
      return {
        'title': 'متبقي على موعد الإفطار',
        'targetTime': todayInfo.maghribDateTime,
        'diff': diff,
        'type': 'iftar',
        'isRamadanToday': true,
      };
    }

    // If now after Maghrib, next is tomorrow's Imsak
    final tomorrowDay = todayInfo.dayNumber < 30 ? days[todayInfo.dayNumber] : days.first;
    final nextImsak = tomorrowDay.imsakDateTime.isAfter(now)
        ? tomorrowDay.imsakDateTime
        : todayInfo.imsakDateTime.add(const Duration(days: 1));
    final diff = nextImsak.difference(now);

    return {
      'title': 'متبقي على موعد إمساك الغد',
      'targetTime': nextImsak,
      'diff': diff,
      'type': 'imsak',
      'isRamadanToday': true,
    };
  }

  // --------------------------------------------------------------------------
  // 2. Khatma Planner Persistence
  // --------------------------------------------------------------------------

  Future<int> getKhatmaTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kKhatmaTarget) ?? 1; // 1 khatma default (20 pages/day)
  }

  Future<void> setKhatmaTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKhatmaTarget, target);
  }

  Future<int> getKhatmaCompletedPages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kKhatmaCompletedPages) ?? 0;
  }

  Future<void> saveKhatmaCompletedPages(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKhatmaCompletedPages, pages.clamp(0, 604 * 5));
  }

  Future<int> getKhatmaCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kKhatmaCurrentPage) ?? 1;
  }

  Future<void> saveKhatmaCurrentPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKhatmaCurrentPage, page.clamp(1, 604));
  }

  // --------------------------------------------------------------------------
  // 3. Iftar Cannon & Suhoor Alert Settings
  // --------------------------------------------------------------------------

  Future<bool> isIftarCannonEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIftarCannonEnabled) ?? true;
  }

  Future<void> setIftarCannonEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIftarCannonEnabled, enabled);
  }

  Future<bool> isSuhoorAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSuhoorAlertEnabled) ?? true;
  }

  Future<void> setSuhoorAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSuhoorAlertEnabled, enabled);
  }

  Future<int> getSuhoorMinutesBeforeFajr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSuhoorMinutes) ?? 45;
  }

  Future<void> setSuhoorMinutesBeforeFajr(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSuhoorMinutes, minutes);
  }

  // --------------------------------------------------------------------------
  // 4. Taraweeh & Tahajjud Counter Persistence
  // --------------------------------------------------------------------------

  Future<int> getTaraweehTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTaraweehTarget) ?? 8; // Default 8 rakats
  }

  Future<void> setTaraweehTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTaraweehTarget, target);
  }

  Future<int> getTaraweehCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTaraweehCurrent) ?? 0;
  }

  Future<void> setTaraweehCurrent(int current) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTaraweehCurrent, current);
  }

  Future<bool> getTaraweehWitrCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTaraweehWitr) ?? false;
  }

  Future<void> setTaraweehWitrCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTaraweehWitr, completed);
  }

  // --------------------------------------------------------------------------
  // 5. Curated Offline Duas Database
  // --------------------------------------------------------------------------

  static const List<RamadanDuaItem> allDuas = [
    // Sunnah Duas (Iftar, Suhoor, Crescent)
    RamadanDuaItem(
      day: 0,
      title: 'دعاء الإفطار المأثور',
      arabicText: 'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ.',
      virtureOrReference: 'رواه أبو داود (حديث صحيح)',
      category: 'fasting_sunnah',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'دعاء الصائم إذا أفطر عند قوم',
      arabicText: 'أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ، وَأَكَلَ طَعَامَكُمُ الأَبْرَارُ، وَصَلَّتْ عَلَيْكُمُ الْمَلائِكَةُ.',
      virtureOrReference: 'رواه أبو داود والنسائي',
      category: 'fasting_sunnah',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'دعاء رؤية هلال شهر رمضان',
      arabicText: 'اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْيُمْنِ وَالإِيمَانِ، وَالسَّلامَةِ وَالإِسْلامِ، رَبِّي وَرَبُّكَ اللَّهُ.',
      virtureOrReference: 'رواه الترمذي وحسنه',
      category: 'fasting_sunnah',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'دعاء الصائم إذا شاتمه أحد',
      arabicText: 'إِنِّي صَائِمٌ.. إِنِّي صَائِمٌ.',
      virtureOrReference: 'متفق عليه في الصحيحين',
      category: 'fasting_sunnah',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'دعاء وقت السحور والاستغفار بالأسحار',
      arabicText: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لا إِلَهَ إِلا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ، اللَّهُمَّ بَارِكْ لَنَا فِي سَحُورِنَا وَقَوِّنَا عَلَى صِيَامِ يَوْمِنَا وَطَاعَتِكَ.',
      virtureOrReference: 'قال تعالى: {وَالْمُسْتَغْفِرِينَ بِالْأَسْحَارِ}',
      category: 'fasting_sunnah',
    ),

    // Last Ten Nights & Laylat Al-Qadr
    RamadanDuaItem(
      day: 21,
      title: 'دعاء ليلة القدر المأثور عن النبي ﷺ',
      arabicText: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي.',
      virtureOrReference: 'عن عائشة رضي الله عنها - رواه الترمذي وصححه',
      category: 'last_ten',
    ),
    RamadanDuaItem(
      day: 22,
      title: 'دعاء العتق من النيران في العشر الأواخر',
      arabicText: 'اللَّهُمَّ أَعْتِقْ رِقَابَنَا وَرِقَابَ آبَائِنَا وَأُمَّهَاتِنَا وَأَزْوَاجِنَا وَذُرِّيَّاتِنَا وَمَنْ أَحَبَّنَا فِيكَ مِنَ النَّارِ يَا رَبَّ الْعَالَمِينَ.',
      virtureOrReference: 'من جوامع أدعية التابعين والصالحين',
      category: 'last_ten',
    ),
    RamadanDuaItem(
      day: 23,
      title: 'دعاء التهجد وقيام الليل',
      arabicText: 'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، وَلَكَ الْحَمْدُ أَنْتَ قَيِّمُ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، وَلَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ.',
      virtureOrReference: 'صحيح البخاري - دعاء قيام النبي ﷺ',
      category: 'last_ten',
    ),
    RamadanDuaItem(
      day: 25,
      title: 'دعاء الرضا وحسن الخاتمة',
      arabicText: 'اللَّهُمَّ اجْعَلْ خَيْرَ أَعْمَارِنَا أَوَاخِرَهَا، وَخَيْرَ أَعْمَالِنَا خَوَاتِيمَهَا، وَخَيْرَ أَيَّامِنَا يَوْمَ نَلْقَاكَ، وَتَوَفَّنَا مُسْلِمِينَ وَأَلْحِقْنَا بِالصَّالِحِينَ.',
      virtureOrReference: 'مأثور حسن',
      category: 'last_ten',
    ),
    RamadanDuaItem(
      day: 27,
      title: 'دعاء ليلة السابع والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ مَا قَسَمْتَ فِي هَذِهِ اللَّيْلَةِ الْمُبَارَكَةِ مِنْ خَيْرٍ وَعَافِيَةٍ وَرِزْقٍ وَمَغْفِرَةٍ فَاجْعَلْ لَنَا مِنْهُ أَوْفَرَ الْحَظِّ وَالنَّصِيبِ، وَمَا أَنْزَلْتَ فِيهَا مِنْ سُوءٍ وَبَلاءٍ فَاصْرِفْهُ عَنَّا وَعَنِ الْمُسْلِمِينَ.',
      virtureOrReference: 'من أرجى ليالي القدر',
      category: 'last_ten',
    ),

    // Qunut & Witr
    RamadanDuaItem(
      day: 0,
      title: 'دعاء قنوت الوتر المأثور',
      arabicText: 'اللَّهُمَّ اهْدِنَا فِيمَنْ هَدَيْتَ، وَعَافِنَا فِيمَنْ عَافَيْتَ، وَتَوَلَّنَا فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لَنَا فِيمَا أَعْطَيْتَ، وَقِنَا شَرَّ مَا قَضَيْتَ، فَإِنَّكَ تَقْضِي وَلا يُقْضَى عَلَيْكَ، إِنَّهُ لا يَذِلُّ مَنْ وَالَيْتَ، وَلا يَعِزُّ مَنْ عَادَيْتَ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ.',
      virtureOrReference: 'عن الحسن بن علي رضي الله عنهما - رواه أبو داود والترمذي',
      category: 'qunut',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'الذكر المستحب عقب صلاة الوتر',
      arabicText: 'سُبْحَانَ الْمَلِكِ الْقُدُّوسِ (ثلاث مرات، يمد صوته في الثالثة ويقول: رَبِّ الْمَلائِكَةِ وَالرُّوحِ).',
      virtureOrReference: 'سنن أبي داود والنسائي بإسناد صحيح',
      category: 'qunut',
    ),
    RamadanDuaItem(
      day: 0,
      title: 'تسبيح وذكر ما بين ركعات التراويح (الترويحات)',
      arabicText: 'سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ، سُبْحَانَ ذِي الْعِزَّةِ وَالْعَظَمَةِ وَالْقُدْرَةِ وَالْكِبْرِيَاءِ وَالْجَبَرُوتِ، سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لا يَمُوتُ، سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلائِكَةِ وَالرُّوحِ.',
      virtureOrReference: 'مستحب عند علماء الأمة في الاستراحة بين ركعات التراويح',
      category: 'qunut',
    ),

    // 30 Daily Duas for each day of Ramadan
    RamadanDuaItem(
      day: 1,
      title: 'دعاء اليوم الأول من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْ صِيَامِي فِيهِ صِيَامَ الصَّائِمِينَ، وَقِيَامِي فِيهِ قِيَامَ الْقَائِمِينَ، وَنَبِّهْنِي فِيهِ عَنْ نَوْمَةِ الْغَافِلِينَ، وَهَبْ لِي جُرْمِي فِيهِ يَا إِلَهَ الْعَالَمِينَ، وَاعْفُ عَنِّي يَا عَافِياً عَنِ الْمُجْرِمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 2,
      title: 'دعاء اليوم الثاني من رمضان',
      arabicText: 'اللَّهُمَّ قَرِّبْنِي فِيهِ إِلَى مَرْضَاتِكَ، وَجَنِّبْنِي فِيهِ مِنْ سَخَطِكَ وَنَقِمَاتِكَ، وَوَفِّقْنِي فِيهِ لِقِرَاءَةِ آيَاتِكَ، بِرَحْمَتِكَ يَا أَرْحَمَ الرَّاحِمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 3,
      title: 'دعاء اليوم الثالث من رمضان',
      arabicText: 'اللَّهُمَّ ارْزُقْنِي فِيهِ الذِّهْنَ وَالتَّنْبِيهَ، وَبَاعِدْنِي فِيهِ مِنَ السَّفَاهَةِ وَالتَّمْوِيهِ، وَاجْعَلْ لِي نَصِيباً مِنْ كُلِّ خَيْرٍ تُنْزِلُ فِيهِ، بِجُودِكَ يَا أَجْوَدَ الأَجْوَدِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 4,
      title: 'دعاء اليوم الرابع من رمضان',
      arabicText: 'اللَّهُمَّ قَوِّنِي فِيهِ عَلَى إِقَامَةِ أَمْرِكَ، وَأَذِقْنِي فِيهِ حَلاوَةَ ذِكْرِكَ، وَأَوْزِعْنِي فِيهِ لأَدَاءِ شُكْرِكَ بِكَرَمِكَ، وَاحْفَظْنِي فِيهِ بِحِفْظِكَ وَسِتْرِكَ يَا أَبْصَرَ النَّاظِرِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 5,
      title: 'دعاء اليوم الخامس من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْنِي فِيهِ مِنَ الْمُسْتَغْفِرِينَ، وَاجْعَلْنِي فِيهِ مِنْ عِبَادِكَ الصَّالِحِينَ الْقَانِتِينَ، وَاجْعَلْنِي فِيهِ مِنْ أَوْلِيَائِكَ الْمُقَرَّبِينَ، بِرَأْفَتِكَ يَا أَرْحَمَ الرَّاحِمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 6,
      title: 'دعاء اليوم السادس من رمضان',
      arabicText: 'اللَّهُمَّ لا تَخْذُلْنِي فِيهِ لِتَعَرُّضِ مَعْصِيَتِكَ، وَلا تَضْرِبْنِي بِسِيَاطِ نَقِمَتِكَ، وَزَحْزِحْنِي فِيهِ مِنْ مُوجِبَاتِ سَخَطِكَ، بِمَنِّكَ وَأَيَادِيكَ يَا مُنْتَهَى رَغْبَةِ الرَّاغِبِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 7,
      title: 'دعاء اليوم السابع من رمضان',
      arabicText: 'اللَّهُمَّ أَعِنِّي فِيهِ عَلَى صِيَامِهِ وَقِيَامِهِ، وَجَنِّبْنِي فِيهِ مِنْ هَفَوَاتِهِ وَآثَامِهِ، وَارْزُقْنِي فِيهِ ذِكْرَكَ بِدَوَامِهِ، بِتَوْفِيقِكَ يَا هَادِيَ الْمُضِلِّينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 8,
      title: 'دعاء اليوم الثامن من رمضان',
      arabicText: 'اللَّهُمَّ ارْزُقْنِي فِيهِ رَحْمَةَ الأَيْتَامِ، وَإِطْعَامَ الطَّعَامِ، وَإِفْشَاءَ السَّلامِ، وَصُحْبَةَ الْكِرَامِ، بِطَوْلِكَ يَا مَلْجَأَ الآمِلِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 9,
      title: 'دعاء اليوم التاسع من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْ لِي فِيهِ نَصِيباً مِنْ رَحْمَتِكَ الْوَاسِعَةِ، وَاهْدِنِي فِيهِ لِبَرَاهِينِكَ السَّاطِعَةِ، وَخُذْ بِنَاصِيَتِي إِلَى مَرْضَاتِكَ الْجَامِعَةِ، بِمَحَبَّتِكَ يَا أَمَلَ الْمُشْتَاقِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 10,
      title: 'دعاء اليوم العاشر من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْنِي فِيهِ مِنَ الْمُتَوَكِّلِينَ عَلَيْكَ، وَاجْعَلْنِي فِيهِ مِنَ الْفَائِزِينَ لَدَيْكَ، وَاجْعَلْنِي فِيهِ مِنَ الْمُقَرَّبِينَ إِلَيْكَ، بِإِحْسَانِكَ يَا غَايَةَ الطَّالِبِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 11,
      title: 'دعاء اليوم الحادي عشر من رمضان',
      arabicText: 'اللَّهُمَّ حَبِّبْ إِلَيَّ فِيهِ الإِحْسَانَ، وَكَرِّهْ إِلَيَّ فِيهِ الْفُسُوقَ وَالْعِصْيَانَ، وَحَرِّمْ عَلَيَّ فِيهِ السَّخَطَ وَالنِّيرَانَ، بِعَوْنِكَ يَا غِيَاثَ الْمُسْتَغِيثِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 12,
      title: 'دعاء اليوم الثاني عشر من رمضان',
      arabicText: 'اللَّهُمَّ زَيِّنِّي فِيهِ بِالسِّتْرِ وَالْعَفَافِ، وَاسْتُرْنِي فِيهِ بِلِبَاسِ الْقُنُوعِ وَالْكَفَافِ، وَاحْمِلْنِي فِيهِ عَلَى الْعَدْلِ وَالإِنْصَافِ، وَآمِنِّي فِيهِ مِنْ كُلِّ مَا أَخَافُ، بِعِصْمَتِكَ يَا عِصْمَةَ الْخَائِفِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 13,
      title: 'دعاء اليوم الثالث عشر من رمضان',
      arabicText: 'اللَّهُمَّ طَهِّرْنِي فِيهِ مِنَ الدَّنَسِ وَالأَقْذَارِ، وَصَبِّرْنِي فِيهِ عَلَى كَائِنَاتِ الأَقْدَارِ، وَوَفِّقْنِي فِيهِ لِلتُّقَى وَصُحْبَةِ الأَبْرَارِ، بِعَوْنِكَ يَا قُرَّةَ عَيْنِ الْمَسَاكِينِ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 14,
      title: 'دعاء اليوم الرابع عشر من رمضان',
      arabicText: 'اللَّهُمَّ لا تُؤَاخِذْنِي فِيهِ بِالْعَثَرَاتِ، وَأَقِلْنِي فِيهِ مِنَ الْخَطَايَا وَالْهَفَوَاتِ، وَلا تَجْعَلْنِي فِيهِ غَرَضاً لِلْبَلايَا وَالآفَاتِ، بِعِزَّتِكَ يَا عِزَّ الْمُسْلِمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 15,
      title: 'دعاء اليوم الخامس عشر من رمضان',
      arabicText: 'اللَّهُمَّ ارْزُقْنِي فِيهِ طَاعَةَ الْخَاشِعِينَ، وَاشْرَحْ فِيهِ صَدْرِي بِإِنَابَةِ الْمُخْبِتِينَ، بِأَمَانِكَ يَا أَمَانَ الْخَائِفِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 16,
      title: 'دعاء اليوم السادس عشر من رمضان',
      arabicText: 'اللَّهُمَّ وَفِّقْنِي فِيهِ لِمُوَافَقَةِ الأَبْرَارِ، وَجَنِّبْنِي فِيهِ مُرَافَقَةَ الأَشْرَارِ، وَآوِنِي فِيهِ بِرَحْمَتِكَ إِلَى دَارِ الْقَرَارِ، بِإِلَهِيَّتِكَ يَا إِلَهَ الْعَالَمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 17,
      title: 'دعاء اليوم السابع عشر من رمضان',
      arabicText: 'اللَّهُمَّ اهْدِنِي فِيهِ لِصَالِحِ الأَعْمَالِ، وَاقْضِ لِي فِيهِ الْحَوَائِجَ وَالآمالَ، يَا مَنْ لا يَحْتَاجُ إِلَى التَّفْسِيرِ وَالسُّؤَالِ، يَا عَالِماً بِمَا فِي صُدُورِ الْعَالَمِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 18,
      title: 'دعاء اليوم الثامن عشر من رمضان',
      arabicText: 'اللَّهُمَّ نَبِّهْنِي فِيهِ لِبَرَكَاتِ أَسْحَارِهِ، وَنَوِّرْ فِيهِ قَلْبِي بِضِيَاءِ أَنْوَارِهِ، وَخُذْ بِكُلِّ أَعْضَائِي إِلَى اتِّبَاعِ آثَارِهِ، بِنُورِكَ يَا مُنَوِّرَ قُلُوبِ الْعَارِفِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 19,
      title: 'دعاء اليوم التاسع عشر من رمضان',
      arabicText: 'اللَّهُمَّ وَفِّرْ فِيهِ حَظِّي مِنْ بَرَكَاتِهِ، وَسَهِّلْ سَبِيلِي إِلَى خَيْرَاتِهِ، وَلا تَحْرِمْنِي قَبُولَ حَسَنَاتِهِ، يَا هَادِياً إِلَى الْحَقِّ الْمُبِينِ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 20,
      title: 'دعاء اليوم العشرين من رمضان',
      arabicText: 'اللَّهُمَّ افْتَحْ لِي فِيهِ أَبْوَابَ الْجِنَانِ، وَأَغْلِقْ عَنِّي فِيهِ أَبْوَابَ النِّيرَانِ، وَوَفِّقْنِي فِيهِ لِتِلاوَةِ الْقُرْآنِ، يَا مُنْزِلَ السَّكِينَةِ فِي قُلُوبِ الْمُؤْمِنِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 21,
      title: 'دعاء اليوم الحادي والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْ لِي فِيهِ إِلَى مَرْضَاتِكَ دَلِيلاً، وَلا تَجْعَلْ لِلشَّيْطَانِ فِيهِ عَلَيَّ سَبِيلاً، وَاجْعَلِ الْجَنَّةَ لِي مَنْزِلاً وَمَقِيلاً، يَا قَاضِيَ حَوَائِجِ الطَّالِبِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 22,
      title: 'دعاء اليوم الثاني والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ افْتَحْ لِي فِيهِ أَبْوَابَ فَضْلِكَ، وَأَنْزِلْ عَلَيَّ فِيهِ بَرَكَاتِكَ، وَوَفِّقْنِي فِيهِ لِمُوجِبَاتِ مَرْضَاتِكَ، وَأَسْكِنِّي فِيهِ بُحْبُوحَاتِ جَنَّاتِكَ، يَا مُجِيبَ دَعْوَةِ الْمُضْطَرِّينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 23,
      title: 'دعاء اليوم الثالث والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ اغْسِلْنِي فِيهِ مِنَ الذُّنُوبِ، وَطَهِّرْنِي فِيهِ مِنَ الْعُيُوبِ، وَامْتَحِنْ قَلْبِي فِيهِ بِتَقْوَى الْقُلُوبِ، يَا مُقِيلَ عَثَرَاتِ الْمُذْنِبِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 24,
      title: 'دعاء اليوم الرابع والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ فِيهِ مَا يُرْضِيكَ، وَأَعُوذُ بِكَ مِمَّا يُؤْذِيكَ، وَأَسْأَلُكَ التَّوْفِيقَ فِيهِ لأَنْ أُطِيعَكَ وَلا أَعْصِيَكَ، يَا جَوَادَ السَّائِلِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 25,
      title: 'دعاء اليوم الخامس والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْنِي فِيهِ مُحِبّاً لأَوْلِيَائِكَ، وَمُعَادِياً لأَعْدَائِكَ، مُسْتَنّاً بِسُنَّةِ خَاتَمِ أَنْبِيَائِكَ، يَا عَاصِمَ قُلُوبِ النَّبِيِّينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 26,
      title: 'دعاء اليوم السادس والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ اجْعَلْ سَعْيِي فِيهِ مَشْكُوراً، وَذَنْبِي فِيهِ مَغْفُوراً، وَعَمَلِي فِيهِ مَقْبُولاً، وَعَيْبِي فِيهِ مَسْتُوراً، يَا أَسْمَعَ السَّامِعِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 27,
      title: 'دعاء اليوم السابع والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ ارْزُقْنِي فِيهِ فَضْلَ لَيْلَةِ الْقَدْرِ، وَصَيِّرْ أُمُورِي فِيهِ مِنَ الْعُسْرِ إِلَى الْيُسْرِ، وَاقْبَلْ مَعَاذِيرِي وَحُطَّ عَنِّي الذَّنْبَ وَالْوِزْرَ، يَا رَؤُوفاً بِعِبَادِهِ الصَّالِحِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 28,
      title: 'دعاء اليوم الثامن والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ وَفِّرْ حَظِّي فِيهِ مِنَ النَّوَافِلِ، وَأَكْرِمْنِي فِيهِ بِإِحْضَارِ الْمَسَائِلِ، وَقَرِّبْ فِيهِ وَسِيلَتِي إِلَيْكَ مِنْ بَيْنِ الْوَسَائِلِ، يَا مَنْ لا يَشْغَلُهُ إِلْحَاحُ الْمُلِحِّينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 29,
      title: 'دعاء اليوم التاسع والعشرين من رمضان',
      arabicText: 'اللَّهُمَّ غَشِّنِي فِيهِ بِالرَّحْمَةِ، وَارْزُقْنِي فِيهِ التَّوْفِيقَ وَالْعِصْمَةَ، وَطَهِّرْ قَلْبِي مِنْ غَيَاهِبِ التُّهَمَةِ، يَا رَحِيماً بِعِبَادِهِ الْمُؤْمِنِينَ.',
      category: 'daily',
    ),
    RamadanDuaItem(
      day: 30,
      title: 'دعاء اليوم الثلاثين من رمضان وختام الشهر',
      arabicText: 'اللَّهُمَّ اجْعَلْ صِيَامِي فِيهِ بِالشُّكْرِ وَالْقَبُولِ عَلَى مَا تَرْضَاهُ وَيَرْضَاهُ الرَّسُولُ، مُحْكَمَةً فُرُوعُهُ بِالأُصُولِ، بِحَقِّ سَيِّدِنَا مُحَمَّدٍ وَآلِهِ الطَّاهِرِينَ، وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ.',
      category: 'daily',
    ),
  ];

  List<RamadanDuaItem> getDuasByCategory(String category) {
    return allDuas.where((d) => d.category == category).toList();
  }

  RamadanDuaItem getTodayDua() {
    final todayHijri = IslamicCalendarService.instance.getTodayHijri();
    final dayNum = (todayHijri.hMonth == 9) ? todayHijri.hDay.clamp(1, 30) : 1;
    return allDuas.firstWhere(
      (d) => d.category == 'daily' && d.day == dayNum,
      orElse: () => allDuas.firstWhere((d) => d.category == 'daily'),
    );
  }

  // --------------------------------------------------------------------------
  // 6. Offline Zakat Calculator Logic
  // --------------------------------------------------------------------------

  /// Zakat al-Fitr Calculation
  Map<String, dynamic> calculateZakatFitr({
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

  /// Zakat al-Mal Calculation (2.5% = 1/40)
  Map<String, dynamic> calculateZakatMal({
    required double cashAndSavings,
    required double goldAndSilverValue,
    required double tradeGoodsValue,
    required double immediateDebtsToDeduct,
    required double goldGramPrice21k,
  }) {
    // Nisab = 85 grams of gold
    final nisabThreshold = 85.0 * goldGramPrice21k;
    final totalWealth = (cashAndSavings + goldAndSilverValue + tradeGoodsValue);
    final netWealth = (totalWealth - immediateDebtsToDeduct).clamp(0.0, double.infinity);

    final isEligible = netWealth >= nisabThreshold && nisabThreshold > 0;
    final zakatDue = isEligible ? (netWealth * 0.025) : 0.0;

    return {
      'totalWealth': totalWealth,
      'netWealth': netWealth,
      'nisabThreshold': nisabThreshold,
      'isEligible': isEligible,
      'zakatDue': zakatDue,
    };
  }
}
