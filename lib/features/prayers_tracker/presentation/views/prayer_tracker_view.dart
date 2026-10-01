import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/components/app_card.dart';
import 'post_prayer_azkar_view.dart';

class PrayerTrackerView extends StatefulWidget {
  const PrayerTrackerView({super.key});

  @override
  State<PrayerTrackerView> createState() => _PrayerTrackerViewState();
}

class _PrayerTrackerViewState extends State<PrayerTrackerView> {
  final UserRepository _userRepo = UserRepository();
  late DateTime _selectedDate;
  Map<String, PrayerLog> _todayLogs = {};
  Map<String, int> _qadaaCounts = {};
  List<PrayerLog> _weeklyLogs = [];
  bool _isLoading = true;

  final List<Map<String, String>> _prayers = [
    {'key': 'fajr', 'name': 'صلاة الفجر', 'icon': 'wb_twilight'},
    {'key': 'dhuhr', 'name': 'صلاة الظهر', 'icon': 'wb_sunny'},
    {'key': 'asr', 'name': 'صلاة العصر', 'icon': 'wb_cloudy'},
    {'key': 'maghrib', 'name': 'صلاة المغرب', 'icon': 'nights_stay'},
    {'key': 'isha', 'name': 'صلاة العشاء', 'icon': 'bedtime'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final logs = await _userRepo.getPrayerLogsForDate(dateStr);
    final qadaa = await _userRepo.getQadaaCounts();

    final now = DateTime.now();
    final weekStart = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 6)));
    final weekEnd = DateFormat('yyyy-MM-dd').format(now);
    final weekly = await _userRepo.getPrayerLogsBetween(weekStart, weekEnd);

    if (mounted) {
      setState(() {
        _todayLogs = logs;
        _qadaaCounts = qadaa;
        _weeklyLogs = weekly;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrayerStatus(String prayerKey, PrayerStatus status) async {
    HapticFeedback.selectionClick();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final log = PrayerLog(
      date: dateStr,
      prayer: prayerKey,
      status: status,
    );
    await _userRepo.savePrayerLog(log);
    await _loadData();
  }

  Future<void> _modifyQadaa(String prayerKey, int delta) async {
    HapticFeedback.selectionClick();
    final current = _qadaaCounts[prayerKey] ?? 0;
    final updated = (current + delta).clamp(0, 99999);
    await _userRepo.setQadaaCount(prayerKey, updated);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

    final completedCount = _todayLogs.values.where((l) => l.status == PrayerStatus.onTime || l.status == PrayerStatus.jamaah).length;
    final totalWeeklyPrayers = _weeklyLogs.where((l) => l.status == PrayerStatus.onTime || l.status == PrayerStatus.jamaah).length;
    final weeklyPercent = ((totalWeeklyPrayers / 35) * 100).clamp(0, 100).toInt();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('سجل الصلوات والفوائت'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.touch_app_outlined),
            tooltip: 'أذكار بعد الصلاة',
            onPressed: () => Get.to(() => const PostPrayerAzkarView()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Switcher Header
                  _buildDateSwitcher(colors, isToday),
                  AppSpacing.verticalMd,

                  // Daily Completion Card
                  _buildDailyProgressCard(completedCount, colors),
                  AppSpacing.verticalLg,

                  // Daily 5 Prayers List
                  Text(
                    'صلوات اليوم',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.verticalSm,
                  ..._prayers.map((p) {
                    final log = _todayLogs[p['key']!];
                    return _buildPrayerItemCard(p, log, colors);
                  }),
                  AppSpacing.verticalLg,

                  // Weekly Stats Card
                  _buildWeeklyStatsCard(weeklyPercent, totalWeeklyPrayers, colors),
                  AppSpacing.verticalLg,

                  // Qadaa Counter Section
                  _buildQadaaSection(colors, textTheme),
                ],
              ),
            ),
    );
  }

  Widget _buildDateSwitcher(AppColorsExtension colors, bool isToday) {
    String formatted;
    try {
      formatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate);
    } catch (_) {
      formatted = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    }

    return AppCard(
      variant: AppCardVariant.flat,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              _loadData();
            },
          ),
          Column(
            children: [
              Text(
                isToday ? 'اليوم' : formatted,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isToday)
                Text(
                  formatted,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: isToday
                ? null
                : () {
                    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                    _loadData();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard(int completedCount, AppColorsExtension colors) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المحافظة على الصلوات',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'أديت $completedCount من 5 صلوات في وقتها اليوم',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$completedCount/5',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerItemCard(Map<String, String> prayer, PrayerLog? log, AppColorsExtension colors) {
    final status = log?.status;

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            status == PrayerStatus.jamaah
                ? Icons.groups_rounded
                : status == PrayerStatus.onTime
                    ? Icons.check_circle_rounded
                    : status == PrayerStatus.late
                        ? Icons.hourglass_bottom_rounded
                        : status == PrayerStatus.missed
                            ? Icons.cancel_rounded
                            : Icons.radio_button_unchecked,
            color: status?.color ?? Colors.grey.shade400,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  status != null ? status.labelAr : 'لم تسجل بعد',
                  style: TextStyle(fontSize: 11, color: status?.color ?? colors.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<PrayerStatus>(
            tooltip: 'تغيير الحالة',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (context) => PrayerStatus.values.map((s) {
              return PopupMenuItem<PrayerStatus>(
                value: s,
                child: Row(
                  children: [
                    Icon(
                      s == PrayerStatus.jamaah ? Icons.groups_rounded : Icons.circle,
                      color: s.color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(s.labelAr),
                  ],
                ),
              );
            }).toList(),
            onSelected: (newStatus) => _updatePrayerStatus(prayer['key']!, newStatus),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status != null ? status.color.withOpacity(0.12) : colors.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: status?.color.withOpacity(0.5) ?? colors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status?.labelAr ?? 'تسجيل',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status?.color ?? colors.text,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(int weeklyPercent, int totalWeekly, AppColorsExtension colors) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إحصاء الأسبوع الأخير',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '$weeklyPercent% التزام',
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: weeklyPercent / 100,
              backgroundColor: colors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalWeekly صلاة مؤداة في وقتها من أصل 35 صلاة خلال الأيام الـ 7 الماضية',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildQadaaSection(AppColorsExtension colors, TextTheme textTheme) {
    final totalQadaa = _qadaaCounts.values.fold(0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'حاسبة قضاء الفوائت',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'إجمالي: $totalQadaa',
                style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        AppSpacing.verticalSm,
        AppCard(
          variant: AppCardVariant.elevated,
          padding: AppSpacing.paddingMd,
          child: Column(
            children: _prayers.map((p) {
              final count = _qadaaCounts[p['key']!] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.teal),
                      onPressed: count > 0 ? () => _modifyQadaa(p['key']!, -1) : null,
                    ),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.purple),
                      onPressed: () => _modifyQadaa(p['key']!, 1),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
