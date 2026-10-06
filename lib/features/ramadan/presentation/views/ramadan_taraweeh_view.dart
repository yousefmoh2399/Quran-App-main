import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../data/ramadan_service.dart';

class RamadanTaraweehView extends StatefulWidget {
  const RamadanTaraweehView({super.key});

  @override
  State<RamadanTaraweehView> createState() => _RamadanTaraweehViewState();
}

class _RamadanTaraweehViewState extends State<RamadanTaraweehView> {
  final RamadanService _service = RamadanService.instance;
  int _targetRakats = 8;
  int _currentRakat = 0;
  bool _witrDone = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final target = await _service.getTaraweehTarget();
    final current = await _service.getTaraweehCurrent();
    final witr = await _service.getTaraweehWitrCompleted();

    setState(() {
      _targetRakats = target;
      _currentRakat = current;
      _witrDone = witr;
      _isLoading = false;
    });
  }

  Future<void> _setTarget(int target) async {
    HapticFeedback.selectionClick();
    setState(() {
      _targetRakats = target;
      if (_currentRakat > target) _currentRakat = target;
    });
    await _service.setTaraweehTarget(target);
  }

  Future<void> _addRakats(int delta) async {
    HapticFeedback.mediumImpact();
    final newCount = (_currentRakat + delta).clamp(0, _targetRakats);
    setState(() => _currentRakat = newCount);
    await _service.setTaraweehCurrent(newCount);

    if (newCount == _targetRakats && !_witrDone && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'هنيئاً! أتممت التراويح، يتبقى ركعات الشفع والوتر',
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF09261E),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _toggleWitr(bool? val) async {
    HapticFeedback.selectionClick();
    final done = val ?? false;
    setState(() => _witrDone = done);
    await _service.setTaraweehWitrCompleted(done);
  }

  Future<void> _resetCounter() async {
    HapticFeedback.lightImpact();
    setState(() {
      _currentRakat = 0;
      _witrDone = false;
    });
    await _service.setTaraweehCurrent(0);
    await _service.setTaraweehWitrCompleted(false);
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

    final isCompleted = _currentRakat >= _targetRakats;
    final progress = (_currentRakat / _targetRakats).clamp(0.0, 1.0);

    return AppScaffold(
      title: 'عدّاد صلاة التراويح والتهجد',
      constrainContentWidth: true,
      actions: [
        IconButton(
          tooltip: 'إعادة الضبط',
          onPressed: () {
            Get.defaultDialog(
              title: 'إعادة ضبط العداد؟',
              middleText: 'هل تريد إعادة ضبط ركعات التراويح والشفع والوتر لليلة جديدة؟',
              textConfirm: 'نعم، إعادة ضبط',
              textCancel: 'إلغاء',
              confirmTextColor: Colors.white,
              buttonColor: colors.primary,
              onConfirm: () {
                Get.back();
                _resetCounter();
              },
            );
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Selection (8 vs 20)
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.primary.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(8, '8 ركعات (سنة الإمام)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(20, '20 ركعة (الجامع)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Big Counter Circle
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: colors.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? const Color(0xFFD4AF37) : colors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentRakat',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'من $_targetRakats ركعات',
                        style: TextStyle(fontSize: 15, color: colors.textMuted),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'اكتملت التراويح',
                            style: TextStyle(color: Color(0xFF09261E), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons: +2 Rakats (صلاة الليل مثنى مثنى)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF09261E),
                      foregroundColor: const Color(0xFFD4AF37),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    onPressed: isCompleted ? null : () => _addRakats(2),
                    icon: const Icon(Icons.check_circle_rounded, size: 24),
                    label: const Text(
                      'أتممت تسليمة (+ ركعتين)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _currentRakat > 0 ? () => _addRakats(-2) : null,
                    child: const Text('- 2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Shif' & Witr Checklist Card
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: _witrDone ? const Color(0xFFD4AF37) : colors.primary.withOpacity(0.15),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                activeColor: const Color(0xFFD4AF37),
                checkColor: const Color(0xFF09261E),
                title: const Text(
                  'صلاة الشفع والوتر (3 ركعات)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  '«اجْعَلُوا آخِرَ صَلَاتِكُمْ بِاللَّيْلِ وِتْرًا» — متفق عليه',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
                value: _witrDone,
                onChanged: _toggleWitr,
              ),
            ),
            const SizedBox(height: 16),

            // Azkar Between Rakats (الترويحة)
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F0),
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: const Color(0xFFE5D8B8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.accessibility_new_rounded, size: 20, color: Color(0xFF09261E)),
                      SizedBox(width: 8),
                      Text(
                        'ذكر واستراحة ما بين الركعات (الترويحة)',
                        style: TextStyle(
                          color: Color(0xFF09261E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '«سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ، سُبْحَانَ ذِي الْعِزَّةِ وَالْعَظَمَةِ وَالْقُدْرَةِ وَالْكِبْرِيَاءِ وَالْجَبَرُوتِ، سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لا يَمُوتُ، سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلائِكَةِ وَالرُّوحِ»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.decorativeFont,
                      fontSize: 16,
                      color: Color(0xFF09261E),
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(int target, String label) {
    final isSelected = _targetRakats == target;
    final colors = context.appColors;
    return InkWell(
      onTap: () => _setTarget(target),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF09261E) : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : colors.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4AF37) : colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
