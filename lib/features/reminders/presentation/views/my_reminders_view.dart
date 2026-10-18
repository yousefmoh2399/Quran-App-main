import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class MyRemindersView extends StatefulWidget {
  const MyRemindersView({super.key});

  @override
  State<MyRemindersView> createState() => _MyRemindersViewState();
}

class _MyRemindersViewState extends State<MyRemindersView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    var list = await NativeRemindersBridge.getAllReminders();

    if (list.isEmpty) {
      // Seed default reminder templates if empty
      await _seedDefaults();
      list = await NativeRemindersBridge.getAllReminders();
    }

    if (mounted) {
      setState(() {
        _reminders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _seedDefaults() async {
    // 1. Daily Wird
    await NativeRemindersBridge.saveReminder({
      'id': 'wird_daily',
      'type': 'wird_daily',
      'schedule_json': jsonEncode({'hour': 20, 'minute': 0}),
      'payload_json': jsonEncode({
        'title': 'وردك القرآني اليومي',
        'body': 'حان وقت وردك القرآني المبارك، رتّل وتدبّر آيات الله.',
      }),
      'enabled': 1,
      'last_triggered': 0,
    });

    // 2. Commute Wird
    await NativeRemindersBridge.saveReminder({
      'id': 'wird_commute',
      'type': 'wird_commute',
      'schedule_json': jsonEncode({
        'hour': 7,
        'minute': 30,
        'days': [1, 2, 3, 4, 5],
        'target_pages': 3,
        'count_towards_main': true,
      }),
      'payload_json': jsonEncode({
        'title': 'ورد المواصلات',
        'body': 'استثمر طريقك في تلاوة القرآن وتزكية وقتك.',
      }),
      'enabled': 0,
      'last_triggered': 0,
    });

    // 3. Monthly Sadaqah
    await NativeRemindersBridge.saveReminder({
      'id': 'sadaqah_monthly',
      'type': 'sadaqah_monthly',
      'schedule_json': jsonEncode({
        'day': 25,
        'day_type': 'day_of_month',
        'calendar': 'hijri',
        'hour': 10,
        'minute': 0,
        'second_reminder': true,
      }),
      'payload_json': jsonEncode({
        'title': 'تذكير الصدقة الشهرية',
        'amount': 0,
      }),
      'enabled': 1,
      'last_triggered': 0,
    });

    // 4. Periodic Azkar
    await NativeRemindersBridge.saveReminder({
      'id': 'azkar_periodic',
      'type': 'azkar_periodic',
      'schedule_json': jsonEncode({
        'interval_minutes': 60,
        'from_hour': 8,
        'from_minute': 0,
        'to_hour': 22,
        'to_minute': 0,
      }),
      'payload_json': jsonEncode({
        'title': 'أذكار وتسابيح',
      }),
      'enabled': 1,
      'last_triggered': 0,
    });
  }

  Map<String, dynamic>? _getReminder(String id) {
    try {
      return _reminders.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleReminder(String id, bool enabled) async {
    setState(() {
      final index = _reminders.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(_reminders[index]);
        updated['enabled'] = enabled ? 1 : 0;
        _reminders[index] = updated;
      }
    });

    await NativeRemindersBridge.toggleReminder(id, enabled);
    await _loadReminders();
    if (mounted) {
      AppSnackbar.show(
        enabled ? 'تم التفعيل' : 'تم التعطيل',
        enabled ? 'تم تفعيل التذكير بنجاح' : 'تم تعطيل التذكير بنجاح',
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'تذكيراتي',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.music_note_rounded, color: colors.primary),
            tooltip: 'أصوات التنبيهات',
            onPressed: () => Get.toNamed(AppRoutes.notificationSoundsSettings),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
            color: colors.surface,
            onSelected: (val) {
              if (val == 'debug') Get.toNamed('/remindersDebug');
              if (val == 'logs') Get.toNamed('/sadaqahLogs');
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logs',
                child: Text('سجل الصدقات', style: TextStyle(fontFamily: AppTypography.uiFont, color: colors.text)),
              ),
              if (kDebugMode)
                PopupMenuItem(
                  value: 'debug',
                  child: Text('فحص التذكيرات (Debug)', style: TextStyle(fontFamily: AppTypography.uiFont, color: colors.text)),
                ),
            ],
          ),
        ],
      ),
      body: MaxWidthContainer(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : RefreshIndicator(
                color: colors.primary,
                onRefresh: _loadReminders,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  children: [
                    // 1. Header Info Card
                    _buildHeaderBanner(colors),

                    const SizedBox(height: 14),

                    // 2. Notification Sounds Customization Card
                    _buildSoundsNavCard(colors),

                    const SizedBox(height: 18),

                    // Section Title
                    Row(
                      children: [
                        Icon(Icons.alarm_on_rounded, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'التذكيرات الرئيسية',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. Daily Wird Card
                    _buildReminderCard(
                      id: 'wird_daily',
                      title: 'الورد اليومي',
                      icon: Icons.menu_book_rounded,
                      imageAsset: 'assets/images/icon_3d_quran.png',
                      color: colors.primary,
                      defaultSubtitle: 'تذكير يومي في الساعة ٠٨:٠٠ مساءً',
                      onConfigure: () async {
                        await Get.toNamed('/wirdSettings');
                        _loadReminders();
                      },
                      colors: colors,
                    ),

                    const SizedBox(height: 10),

                    // 4. Commute Wird Card
                    _buildReminderCard(
                      id: 'wird_commute',
                      title: 'ورد المواصلات',
                      icon: Icons.directions_bus_rounded,
                      imageAsset: 'assets/images/icon_3d_travel.png',
                      color: const Color(0xFF00796B),
                      defaultSubtitle: 'مواعيد متعددة وصفحات مخصصة في الطريق',
                      onConfigure: () async {
                        await Get.toNamed('/commuteWirdSettings');
                        _loadReminders();
                      },
                      colors: colors,
                    ),

                    const SizedBox(height: 10),

                    // 5. Monthly Sadaqah Card
                    _buildReminderCard(
                      id: 'sadaqah_monthly',
                      title: 'الصدقة الشهرية',
                      icon: Icons.volunteer_activism_rounded,
                      imageAsset: 'assets/images/icon_3d_praying_hands.png',
                      color: const Color(0xFFD32F2F),
                      defaultSubtitle: 'تذكير شهري (هجري / ميلادي) مع زر "تصدّقت"',
                      onConfigure: () async {
                        await Get.toNamed('/sadaqahSettings');
                        _loadReminders();
                      },
                      colors: colors,
                    ),

                    const SizedBox(height: 10),

                    // 6. Periodic Azkar Card
                    _buildReminderCard(
                      id: 'azkar_periodic',
                      title: 'الأذكار الدورية',
                      icon: Icons.auto_awesome_rounded,
                      imageAsset: 'assets/images/icon_3d_tasbeeh.png',
                      color: const Color(0xFFF57C00),
                      defaultSubtitle: 'تنبيهات أذكار متفرقة بساعات نشاط وهدوء الصلاة',
                      onConfigure: () async {
                        await Get.toNamed(AppRoutes.azkarNotificationsSettings);
                        _loadReminders();
                      },
                      colors: colors,
                    ),

                    const SizedBox(height: 20),

                    // 7. Fast Actions Tile
                    _buildRescheduleTile(colors),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderBanner(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.primary.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محرك التذكيرات الموحد',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تذكيرات ذكية وموفرة للبطارية مع فحص تلقائي لأداء الورد وإلغاء ذكي للتنبيه إذا أتممته.',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    color: colors.textMuted,
                    height: 1.35,
                  ),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملاحظة لـ iOS: يتم تحديث التذكيرات تلقائياً فور فتح التطبيق لتوفير الطاقة.',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11,
                              color: colors.isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundsNavCard(dynamic colors) {
    return InkWell(
      borderRadius: AppRadius.borderLg,
      onTap: () => Get.toNamed(AppRoutes.notificationSoundsSettings),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.10),
                borderRadius: AppRadius.borderMd,
              ),
              child: Image.asset(
                'assets/images/icon_3d_card_studio.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.music_note_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أصوات ونغمات التنبيهات',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تخصيص نغمة لكل تذكير أو نغمة موحدة مع الاستماع للتجربة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String id,
    required String title,
    required IconData icon,
    String? imageAsset,
    required Color color,
    required String defaultSubtitle,
    required VoidCallback onConfigure,
    required dynamic colors,
  }) {
    final reminder = _getReminder(id);
    final isEnabled = reminder != null && (reminder['enabled'] == 1 || reminder['enabled'] == true);

    String subtitle = defaultSubtitle;
    if (reminder != null) {
      try {
        final schedule = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
        if (id == 'wird_daily') {
          final h = (schedule['hour'] as num?)?.toInt() ?? 20;
          final m = (schedule['minute'] as num?)?.toInt() ?? 0;
          final period = h >= 12 ? 'م' : 'ص';
          final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          final mTens = m ~/ 10;
          final mUnits = m % 10;
          subtitle = 'الساعة ${toArabicDigits(displayH)}:${toArabicDigits(mTens)}${toArabicDigits(mUnits)} $period • يلغى تلقائياً لو قُرئ الورد';
        } else if (id == 'wird_commute') {
          final h = (schedule['hour'] as num?)?.toInt() ?? 7;
          final m = (schedule['minute'] as num?)?.toInt() ?? 30;
          final p = (schedule['target_pages'] as num?)?.toInt() ?? 3;
          final period = h >= 12 ? 'م' : 'ص';
          final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          final mTens = m ~/ 10;
          final mUnits = m % 10;
          subtitle = '${toArabicDigits(displayH)}:${toArabicDigits(mTens)}${toArabicDigits(mUnits)} $period • ${toArabicDigits(p)} صفحات • وضع مواصلات خاص';
        } else if (id == 'sadaqah_monthly') {
          final cal = schedule['calendar'] == 'hijri' ? 'هجري' : 'ميلادي';
          final dayType = schedule['day_type'];
          final dayVal = (schedule['day'] as num?)?.toInt() ?? 25;
          final dayDesc = dayType == 'last_working_day'
              ? 'آخر يوم عمل'
              : (dayType == 'last_thursday' ? 'آخر خميس' : 'يوم ${toArabicDigits(dayVal)}');
          subtitle = '$dayDesc من كل شهر $cal • زر "تصدّقت" مباشر';
        } else if (id == 'azkar_periodic') {
          final interval = (schedule['interval_minutes'] as num?)?.toInt() ?? 60;
          subtitle = 'كل ${toArabicDigits(interval)} دقيقة • يتوقف أثناء النوم والصلاة';
        }
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.35) : colors.divider,
          width: isEnabled ? 1.3 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: onConfigure,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isEnabled ? color.withOpacity(0.12) : colors.textMuted.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: imageAsset != null
                    ? Image.asset(imageAsset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(icon, color: isEnabled ? color : colors.textMuted, size: 22))
                    : Icon(icon, color: isEnabled ? color : colors.textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isEnabled ? colors.text : colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: isEnabled ? colors.textMuted : colors.textMuted.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeColor: color,
                onChanged: (val) => _toggleReminder(id, val),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRescheduleTile(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.divider),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        leading: Icon(Icons.sync_rounded, color: colors.primary),
        title: Text(
          'إعادة مزامنة وجدولة كافة التذكيرات',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: colors.text,
          ),
        ),
        subtitle: Text(
          'حساب أقرب تذكير فورياً وضبط المنظومة',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 11.5,
            color: colors.textMuted,
          ),
        ),
        onTap: () async {
          await NativeRemindersBridge.rescheduleAll();
          if (mounted) {
            AppSnackbar.show(
              'تمت المزامنة',
              'تمت إعادة جدولة كافة التذكيرات بدقة',
              context: context,
            );
          }
        },
      ),
    );
  }
}
