import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';

class PostPrayerZikr {
  final String text;
  final String? virture;
  final int count;

  const PostPrayerZikr({
    required this.text,
    this.virture,
    required this.count,
  });
}

class PostPrayerAzkarView extends StatefulWidget {
  const PostPrayerAzkarView({super.key});

  @override
  State<PostPrayerAzkarView> createState() => _PostPrayerAzkarViewState();
}

class _PostPrayerAzkarViewState extends State<PostPrayerAzkarView> {
  static const List<PostPrayerZikr> _azkarList = [
    PostPrayerZikr(
      text: 'أَسْتَغْفِرُ اللَّهَ',
      virture: 'كان رسول الله ﷺ إذا انصرف من صلاته استغفر ثلاثاً',
      count: 3,
    ),
    PostPrayerZikr(
      text: 'اللَّهُمَّ أَنْتَ السَّلاَمُ، وَمِنْكَ السَّلاَمُ، تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالإِكْرَامِ',
      count: 1,
    ),
    PostPrayerZikr(
      text: 'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لاَ مَانِعَ لِمَا أَعْطَيْتَ، وَلاَ مُعْطِيَ لِمَا مَنَعْتَ، وَلاَ يَنْفَعُ ذَا الجَدِّ مِنْكَ الجَدُّ',
      count: 1,
    ),
    PostPrayerZikr(
      text: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      virture: 'من قرأ آية الكرسي دبر كل صلاة مكتوبة لم يمنعه من دخول الجنة إلا أن يموت',
      count: 1,
    ),
    PostPrayerZikr(
      text: 'سُبْحَانَ اللَّهِ',
      virture: 'التسبيح ٣٣ مرة',
      count: 33,
    ),
    PostPrayerZikr(
      text: 'الْحَمْدُ لِلَّهِ',
      virture: 'التحميد ٣٣ مرة',
      count: 33,
    ),
    PostPrayerZikr(
      text: 'اللَّهُ أَكْبَرُ',
      virture: 'التكبير ٣٣ مرة',
      count: 33,
    ),
    PostPrayerZikr(
      text: 'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ المُلْكُ وَلَهُ الحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      virture: 'تمام المائة: غفرت خطاياه وإن كانت مثل زبد البحر',
      count: 1,
    ),
  ];

  int _currentIndex = 0;
  int _currentCount = 0;
  bool _isAllCompleted = false;

  void _increment() {
    HapticFeedback.lightImpact();
    final zikr = _azkarList[_currentIndex];

    setState(() {
      _currentCount++;
      if (_currentCount >= zikr.count) {
        HapticFeedback.mediumImpact();
        if (_currentIndex < _azkarList.length - 1) {
          _currentIndex++;
          _currentCount = 0;
        } else {
          _isAllCompleted = true;
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _currentCount = 0;
      _isAllCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final zikr = _azkarList[_currentIndex];
    final progress = (_currentIndex + (_currentCount / zikr.count)) / _azkarList.length;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('أذكار ما بعد الصلاة المفروضة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة البدء',
            onPressed: _reset,
          ),
        ],
      ),
      body: _isAllCompleted
          ? _buildCompletionState(colors, textTheme)
          : Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overall Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الذكر ${_currentIndex + 1} من ${_azkarList.length}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalLg,

                  // Zikr Card
                  Expanded(
                    child: AppCard(
                      variant: AppCardVariant.elevated,
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (zikr.virture != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                zikr.virture!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Text(
                                  zikr.text,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    height: 1.8,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTypography.decorativeFont,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Target vs Current
                          Text(
                            '$_currentCount / ${zikr.count}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalLg,

                  // Big Tap Button
                  SizedBox(
                    height: 90,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderLg,
                        ),
                        elevation: 4,
                      ),
                      onPressed: _increment,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'اضغط للعد (${_currentCount + 1}/${zikr.count})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalMd,
                ],
              ),
            ),
    );
  }

  Widget _buildCompletionState(AppColorsExtension colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, size: 72, color: colors.primary),
            ),
            AppSpacing.verticalLg,
            const Text(
              'تقبل الله صلاتك وذكرك',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: AppTypography.decorativeFont,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أتممت أذكار ما بعد الصلاة المسنونة عن النبي ﷺ',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalXl,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة البدء'),
              onPressed: _reset,
            ),
          ],
        ),
      ),
    );
  }
}
