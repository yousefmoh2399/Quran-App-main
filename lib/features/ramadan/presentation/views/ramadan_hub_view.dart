import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../../../core/util/routes/routes.dart';
import '../../../calendar/data/islamic_calendar_service.dart';
import '../../data/ramadan_notification_service.dart';
import '../../data/ramadan_service.dart';

class RamadanHubView extends StatefulWidget {
  const RamadanHubView({super.key});

  @override
  State<RamadanHubView> createState() => _RamadanHubViewState();
}

class _RamadanHubViewState extends State<RamadanHubView> {
  final RamadanService _ramadanService = RamadanService.instance;
  final IslamicCalendarService _calendarService = IslamicCalendarService.instance;

  Timer? _countdownTimer;
  String _countdownText = '';
  String _countdownTitle = 'متبقي على موعد الإفطار';
  int _ramadanYear = 1448;
  bool _isCurrentlyRamadan = false;
  int _currentRamadanDay = 1;

  @override
  void initState() {
    super.initState();
    _checkRamadanStatus();
    _startCountdown();
    RamadanNotificationService.instance.scheduleAll();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkRamadanStatus() {
    final todayHijri = _calendarService.getTodayHijri();
    _ramadanYear = _ramadanService.getRamadanYear();
    _isCurrentlyRamadan = (todayHijri.hMonth == 9);
    _currentRamadanDay = todayHijri.hDay.clamp(1, 30);
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final nextEvent = _ramadanService.getNextRamadanEvent();
    final diff = nextEvent['diff'] as Duration;
    final title = nextEvent['title'] as String;

    if (diff.isNegative) {
      setState(() {
        _countdownTitle = 'حان الآن الموعد مبارك 🌙';
        _countdownText = '00:00:00';
      });
      return;
    }

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

    setState(() {
      _countdownTitle = title;
      _countdownText = '$h:$m:$s';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'واحة رمضان المبارك',
      constrainContentWidth: true,
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Royal Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF09261E), Color(0xFF144D3E)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.borderLg,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF09261E).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCurrentlyRamadan
                                  ? 'اليوم $_currentRamadanDay من رمضان $_ramadanYear هـ'
                                  : 'رمضان المبارك $_ramadanYear هـ',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTypography.decorativeFont,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'مبارك عليكم الشهر الفضيل وتقبل الله طاعتكم 🌙',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('🏮', style: TextStyle(fontSize: 32)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Countdown Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final isNarrow = boxConstraints.maxWidth < 260;
                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _countdownTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _countdownText,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _countdownTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _countdownText,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Dua Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF132B23) : const Color(0xFFFBF8F0),
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.isDark ? const Color(0xFF1E463A) : const Color(0xFFE5D8B8)),
              ),
              child: Row(
                children: [
                  const Text('🤲', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دعاء الإفطار المأثور:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.isDark ? const Color(0xFFD4AF37) : const Color(0xFF09261E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '«ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ»',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.isDark ? Colors.white : const Color(0xFF09261E),
                            fontFamily: AppTypography.decorativeFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, size: 18, color: colors.isDark ? const Color(0xFFD4AF37) : const Color(0xFF09261E)),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                        text: 'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ.',
                      ));
                      Get.snackbar(
                        'تم النسخ',
                        'تم نسخ دعاء الإفطار إلى الحافظة',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6 Feature Cards Grid
            Text(
              'أقسام وميزات شهر رمضان المبارك',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final int crossAxisCount = width > 840
                    ? 4
                    : (width > 560 ? 3 : 2);
                final double aspectRatio = width < 360 ? 1.05 : (width > 560 ? 1.25 : 1.15);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                  children: [
                    _buildMenuCard(
                      title: 'إمساكية رمضان الذكية',
                      subtitle: 'جدول الـ 30 يوماً ومواعيد الإمساك والإفطار',
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.teal,
                      badgeEmoji: '🌙',
                      onTap: () => Get.toNamed(AppRoutes.ramadanImsakia),
                    ),
                    _buildMenuCard(
                      title: 'مخطط ختمة رمضان',
                      subtitle: 'متابعة الورد اليومي والصفحات والتقدم',
                      icon: Icons.auto_stories_rounded,
                      iconColor: Colors.amber.shade800,
                      badgeEmoji: '📖',
                      onTap: () => Get.toNamed(AppRoutes.ramadanKhatma),
                    ),
                    _buildMenuCard(
                      title: 'مدفع الإفطار وتنبيه السحور',
                      subtitle: 'مدفع رمضان التراثي ومنبه وقت السحور',
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.deepOrange,
                      badgeEmoji: '💥',
                      onTap: () => Get.toNamed(AppRoutes.ramadanCannonSuhoor),
                    ),
                    _buildMenuCard(
                      title: 'عدّاد صلاة التراويح',
                      subtitle: 'متابعة ركعات التراويح والشفع والوتر',
                      icon: Icons.fingerprint_rounded,
                      iconColor: Colors.indigo,
                      badgeEmoji: '📿',
                      onTap: () => Get.toNamed(AppRoutes.ramadanTaraweeh),
                    ),
                    _buildMenuCard(
                      title: 'أدعية رمضان وليلة القدر',
                      subtitle: 'أدعية الأيام الـ 30 والعشر الأواخر والقنوت',
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.purple,
                      badgeEmoji: '🤲',
                      onTap: () => Get.toNamed(AppRoutes.ramadanDuas),
                    ),
                    _buildMenuCard(
                      title: 'حاسبة الزكاة الذكية',
                      subtitle: 'حساب زكاة الفطر وزكاة المال بدون إنترنت',
                      icon: Icons.calculate_rounded,
                      iconColor: Colors.green.shade700,
                      badgeEmoji: '⚖️',
                      onTap: () => Get.toNamed(AppRoutes.ramadanZakat),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeEmoji,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.borderLg,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: colors.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  Text(badgeEmoji, style: const TextStyle(fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
