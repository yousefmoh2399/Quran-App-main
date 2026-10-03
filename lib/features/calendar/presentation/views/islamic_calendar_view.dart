import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../data/islamic_calendar_service.dart';
import 'ramadan_imsakia_view.dart';

class IslamicCalendarView extends StatefulWidget {
  const IslamicCalendarView({super.key});

  @override
  State<IslamicCalendarView> createState() => _IslamicCalendarViewState();
}

class _IslamicCalendarViewState extends State<IslamicCalendarView> {
  final IslamicCalendarService _calendarService = IslamicCalendarService.instance;
  final UserRepository _userRepo = UserRepository();

  late HijriCalendar _displayedHijri;
  late DateTime _selectedGregorian;
  Set<String> _fastedDaysInMonth = {};

  @override
  void initState() {
    super.initState();
    _displayedHijri = _calendarService.getTodayHijri();
    _selectedGregorian = DateTime.now();
    _loadFastingData();
  }

  Future<void> _loadFastingData() async {
    final prefix = '${_selectedGregorian.year}-${_selectedGregorian.month.toString().padLeft(2, '0')}';
    final logs = await _userRepo.getFastingLogsForMonth(prefix);
    if (mounted) {
      setState(() {
        _fastedDaysInMonth = logs.where((l) => l.completed).map((l) => l.date).toSet();
      });
    }
  }

  void _nextMonth() {
    setState(() {
      int nextM = _displayedHijri.hMonth + 1;
      int nextY = _displayedHijri.hYear;
      if (nextM > 12) {
        nextM = 1;
        nextY += 1;
      }
      _displayedHijri = HijriCalendar()
        ..hYear = nextY
        ..hMonth = nextM
        ..hDay = 1;
    });
  }

  void _prevMonth() {
    setState(() {
      int prevM = _displayedHijri.hMonth - 1;
      int prevY = _displayedHijri.hYear;
      if (prevM < 1) {
        prevM = 12;
        prevY -= 1;
      }
      _displayedHijri = HijriCalendar()
        ..hYear = prevY
        ..hMonth = prevM
        ..hDay = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final monthName = IslamicCalendarService.hijriMonthNames[_displayedHijri.hMonth];
    final todayHijri = _calendarService.getTodayHijri();
    final todayEvent = _calendarService.getEventForDate(todayHijri.hMonth, todayHijri.hDay);
    final fastingAdvice = _calendarService.getFastingRecommendation(DateTime.now());

    return AppScaffold(
      title: 'التقويم الهجري والمناسبات',
      constrainContentWidth: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'محول التاريخ',
          onPressed: () => _showDateConverterDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.nightlight_outlined),
          tooltip: 'إمساكية رمضان',
          onPressed: () => Get.to(() => const RamadanImsakiaView()),
        ),
      ],
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Day Banner
            _buildTodayCard(todayHijri, todayEvent, fastingAdvice, colors),
            AppSpacing.verticalLg,

            // Month Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: _prevMonth,
                  tooltip: 'الشهر السابق',
                ),
                Text(
                  '$monthName ${_displayedHijri.hYear} هـ',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTypography.decorativeFont,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  onPressed: _nextMonth,
                  tooltip: 'الشهر القادم',
                ),
              ],
            ),
            AppSpacing.verticalSm,

            // Hijri Calendar Month Grid
            _buildMonthGrid(colors),
            AppSpacing.verticalLg,

            // Quick Legend / Key
            _buildLegend(colors),
            AppSpacing.verticalLg,

            // Upcoming Islamic Occasions
            _buildOccasionsList(colors, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(
    HijriCalendar today,
    IslamicEvent? event,
    String? fastingAdvice,
    AppColorsExtension colors,
  ) {
    final monthName = IslamicCalendarService.hijriMonthNames[today.hMonth];
    final now = DateTime.now();
    final gDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isFasted = _fastedDaysInMonth.contains(gDateStr);

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.85)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اليوم المبارك',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
              if (event != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${today.hDay} $monthName ${today.hYear} هـ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: AppTypography.decorativeFont,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الموافق: ${now.day}/${now.month}/${now.year} م',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          if (fastingAdvice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fastingAdvice,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (isFasted) {
                        await _userRepo.deleteFastingLog(gDateStr);
                      } else {
                        await _userRepo.saveFastingLog(FastingLog(
                          date: gDateStr,
                          type: FastingType.voluntary,
                          completed: true,
                        ));
                      }
                      _loadFastingData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFasted ? Colors.amber : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isFasted ? 'صائم ✓' : 'سجّل صيامك',
                        style: TextStyle(
                          color: isFasted ? Colors.black87 : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthGrid(AppColorsExtension colors) {
    const daysInHijri = 30; // standard display month length
    final today = _calendarService.getTodayHijri();

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: AppSpacing.paddingMd,
      child: Column(
        children: [
          // Weekday Labels (Sat to Fri)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('سبت', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('أحد', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('إثنين', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('ثلاثاء', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('أربعاء', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('خميس', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('جمعة', style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInHijri,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isToday = today.hYear == _displayedHijri.hYear &&
                  today.hMonth == _displayedHijri.hMonth &&
                  today.hDay == day;

              final isWhiteDay = day == 13 || day == 14 || day == 15;
              final event = _calendarService.getEventForDate(_displayedHijri.hMonth, day);

              Color bgColor = Colors.transparent;
              Color textColor = colors.text;
              Border? border;

              if (isToday) {
                bgColor = colors.primary;
                textColor = Colors.white;
              } else if (event != null) {
                bgColor = event.color.withOpacity(0.15);
                border = Border.all(color: event.color, width: 1);
                textColor = event.color;
              } else if (isWhiteDay) {
                bgColor = Colors.amber.withOpacity(0.12);
                border = Border.all(color: Colors.amber.shade700, width: 0.8);
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: border,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isToday || isWhiteDay || event != null) ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                    if (event != null)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? Colors.white : event.color,
                        ),
                      )
                    else if (isWhiteDay)
                      const Text(
                        'بيض',
                        style: TextStyle(fontSize: 8, color: Colors.amber),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(AppColorsExtension colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(colors.primary, 'اليوم الحالي'),
        _buildLegendItem(Colors.amber.shade700, 'الأيام البيض (13-15)'),
        _buildLegendItem(Colors.purple, 'مناسبة إسلامية'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOccasionsList(AppColorsExtension colors, TextTheme textTheme) {
    final events = IslamicCalendarService.majorOccasions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المناسبات والأيام المباركة',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.celebration_outlined, size: 18, color: Colors.grey),
          ],
        ),
        AppSpacing.verticalSm,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ev = events[index];
            final mName = IslamicCalendarService.hijriMonthNames[ev.hijriMonth];

            return AppCard(
              variant: AppCardVariant.flat,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ev.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(ev.icon, color: ev.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ev.description,
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text(
                      '${ev.hijriDay} $mName',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ev.color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDateConverterDialog(BuildContext context) {
    final colors = context.appColors;
    DateTime selectedGreg = DateTime.now();
    HijriCalendar convertedHijri = _calendarService.fromGregorian(selectedGreg);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'محوّل التاريخ الهجري والميلادي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.text,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.text),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Divider(color: colors.divider),
                  const SizedBox(height: 8),

                  // Pick Gregorian date
                  ListTile(
                    title: Text(
                      'التاريخ الميلادي',
                      style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${selectedGreg.day}/${selectedGreg.month}/${selectedGreg.year}',
                      style: TextStyle(color: colors.textMuted),
                    ),
                    leading: Icon(Icons.calendar_month_rounded, color: colors.primary),
                    trailing: Icon(Icons.edit_calendar_rounded, color: colors.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedGreg,
                        firstDate: DateTime(1920),
                        lastDate: DateTime(2099),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedGreg = picked;
                          convertedHijri = _calendarService.fromGregorian(picked);
                        });
                      }
                    },
                  ),
                  Divider(color: colors.divider),

                  // Result Hijri Date
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.primary.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'التاريخ الهجري المقابل',
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${convertedHijri.hDay} ${IslamicCalendarService.hijriMonthNames[convertedHijri.hMonth]} ${convertedHijri.hYear} هـ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            fontFamily: AppTypography.decorativeFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
