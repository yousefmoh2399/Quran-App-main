import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_app_android/core/service/settings/lock_screen_banner_service.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';

class LockScreenBannerSettingsView extends StatefulWidget {
  const LockScreenBannerSettingsView({super.key});

  @override
  State<LockScreenBannerSettingsView> createState() =>
      _LockScreenBannerSettingsViewState();
}

class _LockScreenBannerSettingsViewState
    extends State<LockScreenBannerSettingsView> {
  final LockScreenBannerService _service = LockScreenBannerService.instance;
  LockScreenBannerModel _model = LockScreenBannerModel();
  BannerDisplayData? _previewData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final m = await _service.loadSettings();
    final data = await _service.buildDisplayData(m);
    if (mounted) {
      setState(() {
        _model = m;
        _previewData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndRefresh() async {
    await _service.saveSettings(_model);
    final data = await _service.buildDisplayData(_model);
    if (mounted) {
      setState(() {
        _previewData = data;
      });
      AppSnackbar.show(
        'تم التحديث',
        _model.isEnabled
            ? 'تم تحديث بانر شاشة القفل وتثبيته بنجاح'
            : 'تم إيقاف بانر شاشة القفل',
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بانر شاشة القفل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Master Enable Switch Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _model.isEnabled
                          ? primary
                          : theme.dividerColor.withOpacity(0.3),
                      width: _model.isEnabled ? 1.6 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.screen_lock_portrait_rounded,
                              color: primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تفعيل البانر على شاشة القفل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'تثبيت إشعار دائم بمواقيت الصلاة والورد والأذكار',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _model.isEnabled,
                          activeColor: primary,
                          onChanged: (val) {
                            setState(() => _model.isEnabled = val);
                            _saveAndRefresh();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Live Lock Screen Mockup / Preview
                Text(
                  'معاينة حية لشاشة القفل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildLockScreenMockup(isDark, primary),

                const SizedBox(height: 24),

                // Customization Section Header
                Text(
                  'تخصيص محتويات البانر',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'حدد العناصر والمعلومات التي ترغب في ظهورها داخل البانر:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 14),

                // Options List
                _buildToggleTile(
                  icon: Icons.access_time_filled_rounded,
                  title: 'الصلاة القادمة والعد التنازلي',
                  subtitle: 'عرض اسم الصلاة القادمة وموعدها والوقت المتبقي',
                  value: _model.showNextPrayer,
                  onChanged: (val) {
                    setState(() => _model.showNextPrayer = val);
                    _saveAndRefresh();
                  },
                ),
                _buildToggleTile(
                  icon: Icons.table_rows_rounded,
                  title: 'شريط مواقيت الصلاة الكاملة',
                  subtitle: 'جدول مواعيد الفجر، الظهر، العصر، المغرب، والعشاء',
                  value: _model.showAllPrayers,
                  onChanged: (val) {
                    setState(() => _model.showAllPrayers = val);
                    _saveAndRefresh();
                  },
                ),
                _buildToggleTile(
                  icon: Icons.menu_book_rounded,
                  title: 'الورد القرآني اليومي',
                  subtitle: 'متابعة صفحات ورد اليوم وعدد الصفحات المتبقية',
                  value: _model.showWirdProgress,
                  onChanged: (val) {
                    setState(() => _model.showWirdProgress = val);
                    _saveAndRefresh();
                  },
                ),
                _buildToggleTile(
                  icon: Icons.spa_rounded,
                  title: 'ذكر اليوم والتسبيح',
                  subtitle: 'عرض أذكار وأدعية نبوية متجددة لتزكية الوقت',
                  value: _model.showDailyZikr,
                  onChanged: (val) {
                    setState(() => _model.showDailyZikr = val);
                    _saveAndRefresh();
                  },
                ),
                _buildToggleTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'التاريخ الهجري المبارك',
                  subtitle: 'عرض تاريخ اليوم بالتقويم الهجري في رأس البانر',
                  value: _model.showHijriDate,
                  onChanged: (val) {
                    setState(() => _model.showHijriDate = val);
                    _saveAndRefresh();
                  },
                ),
                _buildToggleTile(
                  icon: Icons.touch_app_rounded,
                  title: 'أزرار الوصول السريع',
                  subtitle: 'أزرار مباشرة داخل الإشعار (فتح الورد، الأذكار، المواقيت)',
                  value: _model.showQuickActions,
                  onChanged: (val) {
                    setState(() => _model.showQuickActions = val);
                    _saveAndRefresh();
                  },
                ),

                const SizedBox(height: 20),

                // Note & Tip Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ملاحظة: البانر يظهر بثبات دائم على شاشة القفل وشريط الإشعارات بدون إصدار رنين أو إزعاج، ويتم تحديثه تلقائياً على مدار اليوم.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF1B4D3E);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile.adaptive(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: theme.textTheme.bodySmall?.color),
        ),
        activeColor: primary,
        value: value,
        onChanged: _model.isEnabled ? onChanged : null,
      ),
    );
  }

  Widget _buildLockScreenMockup(bool isDark, Color primary) {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm').format(now);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Lock Screen Status Bar & Clock
          const Icon(Icons.lock_rounded, size: 18, color: Colors.white70),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (_previewData != null && _previewData!.hijriLine.isNotEmpty)
            Text(
              _previewData!.hijriLine,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          const SizedBox(height: 18),

          // The Notification Banner Card
          if (_model.isEnabled && _previewData != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162B24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.star_rounded,
                            size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'تطبيق تقرّب • شاشة القفل',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'الآن',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Main Title
                  Text(
                    _previewData!.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body Content
                  Text(
                    _previewData!.bigContentText,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),

                  // Action Buttons
                  if (_model.showQuickActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMockActionButton('📖 الورد'),
                        const SizedBox(width: 8),
                        _buildMockActionButton('📿 الأذكار'),
                        const SizedBox(width: 8),
                        _buildMockActionButton('🕌 المواقيت'),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'البانر معطل حالياً من المفتاح أعلاه',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMockActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
