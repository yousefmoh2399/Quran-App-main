import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';

class RemindersDebugView extends StatefulWidget {
  const RemindersDebugView({super.key});

  @override
  State<RemindersDebugView> createState() => _RemindersDebugViewState();
}

class _RemindersDebugViewState extends State<RemindersDebugView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcoming = [];

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    setState(() => _isLoading = true);
    final list = await NativeRemindersBridge.getUpcomingAlarms();
    setState(() {
      _upcoming = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص محرك التذكيرات (Debug)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _loadUpcoming,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2622) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: primary),
                          const SizedBox(width: 8),
                          const Text(
                            'المجدول الموحد (Single Chained Alarm)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'النظام يحسب أقرب تذكير بين كافة الأنواع المفعّلة ويضبط منبهًا غير دقيق (setAndAllowWhileIdle) واحدًا فقط لحفظ البطارية. وفور انطلاقه يفحص شرط الإلغاء ثم يحسب الموعد التالي.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي التذكيرات المجدولة: ${_upcoming.length}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('إعادة جدولة الكل', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              await NativeRemindersBridge.rescheduleAll();
                              await _loadUpcoming();
                              Get.snackbar(
                                'تمت المزامنة',
                                'تمت إعادة حساب أقرب موعد وتحديث المنبه',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: primary,
                                colorText: Colors.white,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text('جدول المواعيد القادمة (حسب الأسبقية)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

                if (_upcoming.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('لا توجد تذكيرات مفعلة حالياً في المحرك', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._upcoming.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final id = item['id'] as String? ?? '';
                    final type = item['type'] as String? ?? '';
                    final timeFormatted = item['next_trigger_formatted'] as String? ?? '';
                    final isCancelled = item['is_cancelled_by_condition'] as bool? ?? false;
                    final channel = item['channel'] as String? ?? '';
                    final isNextActive = idx == 0; // Earliest alarm is the active one!

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isNextActive ? primary : Colors.transparent,
                          width: isNextActive ? 2.0 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isNextActive) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('المنبه الفعّال حالياً ⏰', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  id,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Spacer(),
                                Chip(
                                  label: Text(type, style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('الموعد القادم: $timeFormatted', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.notifications_none_rounded, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('القناة: $channel', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                                  size: 16,
                                  color: isCancelled ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCancelled
                                      ? 'شرط الإلغاء: مُحقق (سيتخطى الإشعار ويجدول التالي) 🚫'
                                      : 'شرط الإلغاء: غير محقق (سيظهر الإشعار بنجاح) 🔔',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isCancelled ? Colors.orange : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: const Text('تجربة الإطلاق فورياً (Test Fire)'),
                                onPressed: () async {
                                  await NativeRemindersBridge.testTriggerReminder(id);
                                  Get.snackbar(
                                    'تم الإطلاق',
                                    'تم إرسال إشعار $id بنجاح للتجربة',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: primary,
                                    colorText: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
