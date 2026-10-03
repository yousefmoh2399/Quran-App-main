import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

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

    setState(() {
      _reminders = list;
      _isLoading = false;
    });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تذكيراتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note_rounded),
            tooltip: 'أصوات التنبيهات',
            onPressed: () => Get.toNamed(AppRoutes.notificationSoundsSettings),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الصدقات',
            onPressed: () => Get.toNamed('/sadaqahLogs'),
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'فحص التذكيرات القادمة',
              onPressed: () => Get.toNamed('/remindersDebug'),
            ),
        ],
      ),
      body: MaxWidthContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _loadReminders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF14382D), const Color(0xFF0F2B22)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: primaryColor.withOpacity(0.15),
                          child: Icon(Icons.notifications_active_rounded, color: isDark ? const Color(0xFF81C784) : primaryColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'محرك التذكيرات الموحد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تذكيرات ذكية موفرة للبطارية مع فحص تلقائي لأداء الورد قبل الإشعار.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              if (Platform.isIOS) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ملاحظة لـ iOS: التذكير لا يُلغى تلقائياً لو قرأت والتطبيق مغلق، بل يتم تحديثه وإلغاؤه فور فتحك للتطبيق. الحد الأقصى للمجدول 64 إشعاراً تُجدد تلقائياً.',
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
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
                  ),
                  const SizedBox(height: 16),

                  // Notification Sounds Customization Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Get.toNamed(AppRoutes.notificationSoundsSettings),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4D3E).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.music_note_rounded, color: Color(0xFF1B4D3E), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'أصوات ونغمات التنبيهات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'تخصيص نغمة لكل تذكير أو نغمة موحدة مع الاستماع للتجربة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. Daily Wird Card
                  _buildReminderCard(
                    id: 'wird_daily',
                    title: 'الورد اليومي',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF2E7D32),
                    defaultSubtitle: 'تذكير يومي في الساعة 08:00 مساءً',
                    onConfigure: () async {
                      await Get.toNamed('/wirdSettings');
                      _loadReminders();
                    },
                  ),

                  const SizedBox(height: 12),

                  // 2. Commute Wird Card
                  _buildReminderCard(
                    id: 'wird_commute',
                    title: 'ورد المواصلات',
                    icon: Icons.directions_bus_rounded,
                    color: const Color(0xFF00796B),
                    defaultSubtitle: 'مواعيد متعددة وصفحات مخصصة في الطريق',
                    onConfigure: () async {
                      await Get.toNamed('/commuteWirdSettings');
                      _loadReminders();
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. Monthly Sadaqah Card
                  _buildReminderCard(
                    id: 'sadaqah_monthly',
                    title: 'الصدقة الشهرية',
                    icon: Icons.volunteer_activism_rounded,
                    color: const Color(0xFFD32F2F),
                    defaultSubtitle: 'تذكير شهري (هجري / ميلادي) مع زر "تصدّقت"',
                    onConfigure: () async {
                      await Get.toNamed('/sadaqahSettings');
                      _loadReminders();
                    },
                  ),

                  const SizedBox(height: 12),

                  // 4. Periodic Azkar Card
                  _buildReminderCard(
                    id: 'azkar_periodic',
                    title: 'الأذكار الدورية',
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFF57C00),
                    defaultSubtitle: 'تنبيهات أذكار متفرقة بساعات نشاط وهدوء الصلاة',
                    onConfigure: () async {
                      await Get.toNamed(AppRoutes.azkarNotificationsSettings);
                      _loadReminders();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Fast Actions Tile
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isDark ? const Color(0xFF1E2622) : const Color(0xFFF1F5F2),
                    leading: const Icon(Icons.sync_rounded, color: Color(0xFF1B4D3E)),
                    title: const Text('إعادة مزامنة وجدولة كافة التذكيرات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('حساب أقرب تذكير فورياً وضبط المنظومة', style: TextStyle(fontSize: 12)),
                    onTap: () async {
                      await NativeRemindersBridge.rescheduleAll();
                      if (context.mounted) {
                        AppSnackbar.show(
                          'تمت المزامنة',
                          'تمت إعادة جدولة كافة التذكيرات بدقة',
                          context: context,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
    required String defaultSubtitle,
    required VoidCallback onConfigure,
  }) {
    final reminder = _getReminder(id);
    final isEnabled = reminder != null && (reminder['enabled'] == 1 || reminder['enabled'] == true);

    String subtitle = defaultSubtitle;
    if (reminder != null) {
      try {
        final schedule = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
        if (id == 'wird_daily') {
          final h = schedule['hour'] ?? 20;
          final m = (schedule['minute'] ?? 0).toString().padLeft(2, '0');
          final period = h >= 12 ? 'م' : 'ص';
          final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          subtitle = 'الساعة $displayH:$m $period • يلغى تلقائياً لو قُرئ الورد';
        } else if (id == 'wird_commute') {
          final h = schedule['hour'] ?? 7;
          final m = (schedule['minute'] ?? 30).toString().padLeft(2, '0');
          final p = schedule['target_pages'] ?? 3;
          final period = h >= 12 ? 'م' : 'ص';
          final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          subtitle = '$displayH:$m $period • $p صفحات • وضع مواصلات خاص';
        } else if (id == 'sadaqah_monthly') {
          final cal = schedule['calendar'] == 'hijri' ? 'هجري' : 'ميلادي';
          final dayType = schedule['day_type'];
          final dayDesc = dayType == 'last_working_day'
              ? 'آخر يوم عمل'
              : (dayType == 'last_thursday' ? 'آخر خميس' : 'يوم ${schedule['day']}');
          subtitle = '$dayDesc من كل شهر $cal • زر "تصدّقت" مباشر';
        } else if (id == 'azkar_periodic') {
          final interval = schedule['interval_minutes'] ?? 60;
          subtitle = 'كل $interval دقيقة • يتوقف أثناء النوم والصلاة';
        }
      } catch (_) {}
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEnabled ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onConfigure,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: color,
                onChanged: (val) => _toggleReminder(id, val),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
