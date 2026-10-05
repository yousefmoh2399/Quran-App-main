import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';

class SadaqahLogsView extends StatefulWidget {
  const SadaqahLogsView({super.key});

  @override
  State<SadaqahLogsView> createState() => _SadaqahLogsViewState();
}

class _SadaqahLogsViewState extends State<SadaqahLogsView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await NativeRemindersBridge.getSadaqahLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: 'صدقة شهرية');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل صدقة مباركة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ (اختياري)',
                hintText: 'مثلاً: 50 أو 100',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'بيان أو ملاحظة',
                hintText: 'إطعام مسكين، كفالة، صدقة جارية...',
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final amountText = amountController.text.trim();
              final amount = amountText.isNotEmpty ? double.tryParse(amountText) : null;
              final note = noteController.text.trim();
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

              await NativeRemindersBridge.markSadaqahDonated(
                date: todayStr,
                amount: amount,
                note: note.isNotEmpty ? note : 'صدقة',
              );

              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
              if (mounted) {
                _loadLogs();
                AppSnackbar.show(
                  'تقبل الله طاعتكم',
                  'تم حفظ الصدقة في سجلك المحلي بنجاح 🤲',
                  context: context,
                );
              }
            },
            child: const Text('تسجيل وتأكيد', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF1B4D3E);

    double totalAmount = 0.0;
    for (final log in _logs) {
      final amt = log['amount'];
      if (amt is num) {
        totalAmount += amt.toDouble();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الصدقات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('تسجيل صدقة'),
        onPressed: _showAddDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism_outlined, size: 72, color: primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد صدقات مسجلة بعد',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'يمكنك تسجيل صدقاتك يدوياً أو بنقرة "تصدّقت" من الإشعار الشهري',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('سجل أول صدقة الآن'),
                        onPressed: _showAddDialog,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF14382D), const Color(0xFF0F2B22)]
                              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_logs.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: isDark ? const Color(0xFF81C784) : primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('إجمالي المرات', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                          Column(
                            children: [
                              Text(
                                totalAmount > 0 ? totalAmount.toStringAsFixed(0) : '—',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: isDark ? const Color(0xFF81C784) : primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('إجمالي المبالغ المسجلة', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('السجل التاريخي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),

                    ..._logs.map((log) {
                      final date = log['date'] as String? ?? '';
                      final note = log['note'] as String? ?? 'صدقة';
                      final amount = log['amount'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withOpacity(0.12),
                            child: Icon(Icons.volunteer_activism_rounded, color: primary, size: 20),
                          ),
                          title: Text(note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: amount != null
                              ? Text(
                                  '$amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primary,
                                  ),
                                )
                              : const Text('✓ مسجلة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),

                    const SizedBox(height: 60),
                  ],
                ),
    );
  }
}
