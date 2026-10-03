import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../../../core/util/routes/routes.dart';
import '../../data/ramadan_service.dart';

class RamadanKhatmaView extends StatefulWidget {
  const RamadanKhatmaView({super.key});

  @override
  State<RamadanKhatmaView> createState() => _RamadanKhatmaViewState();
}

class _RamadanKhatmaViewState extends State<RamadanKhatmaView> {
  final RamadanService _service = RamadanService.instance;
  int _targetKhatmas = 1;
  int _completedPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;

  // Daily prayers reading checklist
  final Map<String, bool> _prayerChecklist = {
    'الفجر': false,
    'الظهر': false,
    'العصر': false,
    'المغرب': false,
    'العشاء': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final target = await _service.getKhatmaTarget();
    final completed = await _service.getKhatmaCompletedPages();
    final current = await _service.getKhatmaCurrentPage();

    setState(() {
      _targetKhatmas = target;
      _completedPages = completed;
      _currentPage = current;
      _isLoading = false;
    });
  }

  Future<void> _updateTarget(int target) async {
    HapticFeedback.selectionClick();
    setState(() => _targetKhatmas = target);
    await _service.setKhatmaTarget(target);
  }

  Future<void> _addPages(int count) async {
    HapticFeedback.lightImpact();
    final newPage = (_currentPage + count).clamp(1, 604);
    final newCompleted = (_completedPages + count).clamp(0, 604 * _targetKhatmas);

    setState(() {
      _currentPage = newPage;
      _completedPages = newCompleted;
    });

    await _service.saveKhatmaCurrentPage(newPage);
    await _service.saveKhatmaCompletedPages(newCompleted);

    if (newPage == 604) {
      _showKhatmaCelebration();
    }
  }

  void _showKhatmaCelebration() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF09261E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 هنيئاً لك ختم كتاب الله!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '«مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللَّهِ فَلَهُ بِهِ حَسَنَةٌ، وَالحَسَنَةُ بِعَشْرِ أَمْثَالِهَا»',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'تقبل الله طاعتكم وجعل القرآن العظيم ربيع قلوبكم ونور صدوركم 🤲',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF09261E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Get.back(),
              child: const Text('الحمد لله • متابعة القراءة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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

    final totalTargetPages = 604 * _targetKhatmas;
    final progressFraction = (_completedPages / totalTargetPages).clamp(0.0, 1.0);
    final percentage = (progressFraction * 100).toStringAsFixed(1);
    final dailyPagesRequired = (_targetKhatmas * 20.13).ceil(); // ~20 pages per khatma per 30 days
    final pagesPerPrayer = (dailyPagesRequired / 5).ceil();

    return AppScaffold(
      title: 'مخطط ختمة رمضان',
      constrainContentWidth: true,
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Selection Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.primary.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'اختر هدف الختم في رمضان',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildTargetChip(1, 'ختمة واحدة', 'جزء يومياً (20 صفحة)'),
                      const SizedBox(width: 8),
                      _buildTargetChip(2, 'ختمتان', 'جزأين يومياً (40 صفحة)'),
                      const SizedBox(width: 8),
                      _buildTargetChip(3, '3 ختمات', '3 أجزاء (60 صفحة)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Banner
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF09261E), Color(0xFF134E3E)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.borderLg,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF09261E).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
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
                            const Text(
                              'نسبة إنجاز الختمة',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الصفحة الحالية: $_currentPage',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'المتبقي: ${totalTargetPages - _completedPages} صفحة',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 10,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF09261E),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': _currentPage});
                    },
                    icon: const Icon(Icons.auto_stories_rounded, size: 20),
                    label: Text(
                      'متابعة القراءة من صفحة $_currentPage',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily Prayer Reading Distribution
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
                      Icon(Icons.calendar_today_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'جدول الورد بعد كل صلاة اليوم',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'قراءة $pagesPerPrayer صفحات بعد كل صلاة مكتوبة = إتمام $dailyPagesRequired صفحة يومياً بسهولة.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ..._prayerChecklist.keys.map((prayer) {
                    final done = _prayerChecklist[prayer] ?? false;
                    return Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.primary,
                        title: Text(
                          'بعد صلاة $prayer ($pagesPerPrayer صفحات)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: done ? FontWeight.bold : FontWeight.normal,
                            decoration: done ? TextDecoration.lineThrough : null,
                            color: done ? colors.primary : colors.text,
                          ),
                        ),
                        value: done,
                        onChanged: (val) {
                          setState(() {
                            _prayerChecklist[prayer] = val ?? false;
                          });
                          if (val == true) {
                            _addPages(pagesPerPrayer);
                          } else {
                            _addPages(-pagesPerPrayer);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fast Page Increment Bar
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.primary.withOpacity(0.12)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addPages(1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ صفحة', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _addPages(4),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.exposure_plus_1, size: 16),
                    label: const Text('+ 4 صفحات', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _addPages(20),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 16),
                    label: const Text('+ جزء (20)', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip(int target, String title, String subtitle) {
    final isSelected = _targetKhatmas == target;
    final colors = context.appColors;
    return Expanded(
      child: InkWell(
        onTap: () => _updateTarget(target),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF09261E) : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : colors.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFD4AF37) : colors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : colors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
