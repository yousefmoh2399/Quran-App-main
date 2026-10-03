import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/native/native_reminders_bridge.dart';
import '../../data/ramadan_notification_service.dart';
import '../../data/ramadan_service.dart';

class RamadanCannonSuhoorView extends StatefulWidget {
  const RamadanCannonSuhoorView({super.key});

  @override
  State<RamadanCannonSuhoorView> createState() => _RamadanCannonSuhoorViewState();
}

class _RamadanCannonSuhoorViewState extends State<RamadanCannonSuhoorView> {
  final RamadanService _service = RamadanService.instance;
  bool _cannonEnabled = true;
  bool _suhoorEnabled = true;
  int _suhoorMinutes = 45;
  bool _isPlayingPreview = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cannon = await _service.isIftarCannonEnabled();
    final suhoor = await _service.isSuhoorAlertEnabled();
    final minutes = await _service.getSuhoorMinutesBeforeFajr();

    setState(() {
      _cannonEnabled = cannon;
      _suhoorEnabled = suhoor;
      _suhoorMinutes = minutes;
      _isLoading = false;
    });

    // Ensure Ramadan notifications and widgets are refreshed
    await RamadanNotificationService.instance.scheduleAll();
  }

  Future<void> _toggleCannon(bool val) async {
    HapticFeedback.selectionClick();
    setState(() => _cannonEnabled = val);
    await _service.setIftarCannonEnabled(val);
    await RamadanNotificationService.instance.scheduleAll();
  }

  Future<void> _toggleSuhoor(bool val) async {
    HapticFeedback.selectionClick();
    setState(() => _suhoorEnabled = val);
    await _service.setSuhoorAlertEnabled(val);
    await RamadanNotificationService.instance.scheduleAll();
  }

  Future<void> _setSuhoorMinutes(int minutes) async {
    HapticFeedback.selectionClick();
    setState(() => _suhoorMinutes = minutes);
    await _service.setSuhoorMinutesBeforeFajr(minutes);
    await RamadanNotificationService.instance.scheduleAll();
  }

  Future<void> _previewCannon() async {
    HapticFeedback.heavyImpact();
    setState(() => _isPlayingPreview = true);

    try {
      await NativeRemindersBridge.previewSound('fazakkir');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '💥 مدفع الإفطار.. اضرررررب! تقبل الله صيامكم وطاعتكم 🌙',
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF09261E),
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() => _isPlayingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('مدفع الإفطار وتنبيه السحور'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Iftar Cannon Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF09261E), Color(0xFF1B4D3E)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.borderLg,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Text('💥', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'مدفع الإفطار التفاعلي',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _cannonEnabled,
                        activeColor: const Color(0xFFD4AF37),
                        onChanged: _toggleCannon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تشغيل صوت ونداء مدفع رمضان التراثي المبهج بالتزامن مع أذان المغرب وإعلان وقت الإفطار.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF09261E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: _isPlayingPreview ? null : _previewCannon,
                      icon: Icon(_isPlayingPreview ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
                      label: Text(
                        _isPlayingPreview ? 'جاري تشغيل المدفع...' : 'تجربة صوت مدفع الإفطار الآن',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Suhoor Alert Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alarm_on_rounded, color: colors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'منبه وتنبيه السحور المخصص',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _suhoorEnabled,
                        activeColor: colors.primary,
                        onChanged: _toggleSuhoor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تنبيهك قبل أذان الفجر بوقت كافٍ لتناول وجبة السحور ونيل بركتها والاستغفار بالأسحار.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  if (_suhoorEnabled) ...[
                    const SizedBox(height: 14),
                    Text(
                      'التنبيه قبل الفجر بـ:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.text),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMinutesChip(30, '30 دقيقة'),
                        const SizedBox(width: 8),
                        _buildMinutesChip(45, '45 دقيقة (مستحسن)'),
                        const SizedBox(width: 8),
                        _buildMinutesChip(60, 'ساعة كاملة'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '«تَسَحَّرُوا فَإِنَّ فِي السَّحُورِ بَرَكَةً» — متفق عليه',
                            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Test Section
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notification_add_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'فحص واختبار الإشعارات المباشرة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يمكنك إرسال إشعار تجريبي فوري لشريط الإشعارات للتأكد من وصول الصوت والظهور السليم.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await RamadanNotificationService.instance.testTriggerSuhoor();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔔 تم إرسال تجربة إشعار السحور المبارك'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              icon: const Text('🌙'),
                              label: const Text('إشعار السحور', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                HapticFeedback.heavyImpact();
                                await RamadanNotificationService.instance.testTriggerIftarCannon();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('💥 تم إرسال تجربة إشعار مدفع الإفطار'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              icon: const Text('💥'),
                              label: const Text('إشعار الإفطار', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Official Iftar Dua Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🤲', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        'دعاء الإفطار المأثور',
                        style: TextStyle(
                          color: colors.isDark ? const Color(0xFFD4AF37) : const Color(0xFF09261E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF132B23) : const Color(0xFFF9F7F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.isDark ? const Color(0xFF1E463A) : const Color(0xFFE8DFC8)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '«ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ»',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.decorativeFont,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.isDark ? const Color(0xFFD4AF37) : const Color(0xFF09261E),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '«اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ أَنْ تَغْفِرَ لِي»',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                            text: 'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ.',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ تم نسخ دعاء الإفطار إلى الحافظة'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('نسخ الدعاء'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinutesChip(int minutes, String label) {
    final isSelected = _suhoorMinutes == minutes;
    final colors = context.appColors;
    return Expanded(
      child: InkWell(
        onTap: () => _setSuhoorMinutes(minutes),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}
