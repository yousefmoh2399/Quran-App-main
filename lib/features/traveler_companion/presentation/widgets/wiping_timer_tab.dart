import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../controllers/traveler_companion_controller.dart';
import '../../data/models/wiping_timer_model.dart';

class WipingTimerTab extends StatelessWidget {
  final TravelerCompanionController controller;

  const WipingTimerTab({super.key, required this.controller});

  String _formatDateTime(DateTime dt) {
    const weekdays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = weekdays[dt.weekday - 1];
    final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$dayName ${toArabicDigits(dt.day)}/${toArabicDigits(dt.month)} في ${toArabicDigits(hour12)}:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final timer = controller.timerState.value;
      final now = controller.currentTime.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (timer != null && timer.isActive) ...[
              _buildActiveTimerView(context, timer, now, colors),
            ] else ...[
              _buildInactiveStartView(context, colors),
            ],
            const SizedBox(height: 16.0),
            _buildFiqhRulesGuidanceCard(context, colors),
            const SizedBox(height: 16.0),
            _buildConditionsCard(context, colors),
            const SizedBox(height: 24.0),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Active Timer View
  // ---------------------------------------------------------------------------
  Widget _buildActiveTimerView(
    BuildContext context,
    WipingTimerState timer,
    DateTime now,
    AppColorsExtension colors,
  ) {
    final remaining = timer.remaining(now);
    final isExpired = timer.isExpired(now);
    final isWarning = timer.isWarning(now);
    final progress = timer.progress(now);

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final primaryColor = isExpired
        ? colors.error
        : (isWarning ? const Color(0xFFE65100) : colors.primary);

    return AppCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      timer.isTraveler ? Icons.flight_takeoff_rounded : Icons.home_rounded,
                      size: 15.0,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      timer.isTraveler ? 'مسح مسافر (٧٢ ساعة)' : 'مسح مقيم (٢٤ ساعة)',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: isExpired
                      ? colors.error.withValues(alpha: 0.15)
                      : colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  isExpired ? 'انتهت المدة' : (isWarning ? 'تنبيه: قارب على الانتهاء' : 'مؤقت نشط'),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? colors.error : colors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Circular Ring Progress
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: 1.0 - progress,
                    strokeWidth: 10.0,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colors.divider.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExpired) ...[
                      Icon(Icons.warning_amber_rounded, size: 36, color: colors.error),
                      const SizedBox(height: 4),
                      Text(
                        'انتهت مدة المسح',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'يلزم غسل القدمين في الوضوء القادم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'الوقت المتبقي',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.0,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${toArabicDigits(hours)}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${toArabicDigits(hours)} س و ${toArabicDigits(minutes)} د',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          // Timing Details Container
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, size: 16, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'بدأ المسح:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(timer.startedAt),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'ينتهي المسح:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(timer.expiresAt),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'إيقاف المؤقت',
                      middleText: 'هل قمت بخلع الخفين أو تجديد غسل القدمين؟ سيتم إيقاف المؤقت الحالي.',
                      textConfirm: 'نعم، إيقاف',
                      textCancel: 'إلغاء',
                      confirmTextColor: Colors.white,
                      buttonColor: colors.error,
                      onConfirm: () {
                        Get.back();
                        controller.stopTimer();
                      },
                    );
                  },
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('إنهاء المسح'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'إعادة ضبط المؤقت',
                      middleText: 'هل أعدت الوضوء وغسل القدمين ومسحت للتو مجدداً؟ سيبدأ الحساب من هذه اللحظة.',
                      textConfirm: 'نعم، إعادة ضبط',
                      textCancel: 'إلغاء',
                      confirmTextColor: Colors.white,
                      buttonColor: colors.primary,
                      onConfirm: () {
                        Get.back();
                        controller.resetTimer();
                      },
                    );
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('تجديد من الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inactive Start View
  // ---------------------------------------------------------------------------
  Widget _buildInactiveStartView(BuildContext context, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.12),
                colors.accent.withValues(alpha: 0.06),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مؤقت المسح على الخفين والجوربين',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'احسب مدة المسح الشرعية الدقيقة وتجنب بطلان الطهارة بانقضاء الوقت دون علم.',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        color: colors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        Text(
          'اختر صفتك لبدء المؤقت:',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),

        const SizedBox(height: 10.0),

        // Two Big Luxury Options
        Row(
          children: [
            // 1. المسافر (72h)
            Expanded(
              child: InkWell(
                onTap: () => controller.startTimer(isTraveler: true),
                borderRadius: AppRadius.borderMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: colors.primary.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flight_takeoff_rounded, size: 26, color: colors.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أنا مسافر',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '٣ أيام بلياليها',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '(٧٢ ساعة)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12.0),

            // 2. المقيم (24h)
            Expanded(
              child: InkWell(
                onTap: () => controller.startTimer(isTraveler: false),
                borderRadius: AppRadius.borderMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: colors.accent.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.home_rounded, size: 26, color: colors.accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أنا مقيم',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يوم وليلة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '(٢٤ ساعة)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Fiqh Rule Guidance Card (متى يبدأ الحساب؟)
  // ---------------------------------------------------------------------------
  Widget _buildFiqhRulesGuidanceCard(BuildContext context, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.divider.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 19, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'تنبيه فقهي هام: متى تبدأ مدة المسح؟',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'الراجح عند جمهور المحققين (كالنووي وابن تيمية وابن عثيمين) أن مدة المسح تبدأ من «أول مسحة توضأتها بعد الحدث»، وليس من وقت لبس الجورب، ولا من وقت الحدث نفسه.',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مثال: لبست الجوربين بعد وضوء الفجر ٥:٠٠ ص، ثم أحدثت ٩:٠٠ ص، وعند وضوء الظهر ١٢:٠٠ م مسحت عليهما: يبدأ المؤقت من ١٢:٠٠ م وينتهي غداً في ١٢:٠٠ م للمقيم.',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.text,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5 Conditions Card (شروط المسح ومبطلاته)
  // ---------------------------------------------------------------------------
  Widget _buildConditionsCard(BuildContext context, AppColorsExtension colors) {
    final conditions = [
      '١. لبس الخفين أو الجوربين على طهارة كاملة بالماء بعد الوضوء التام.',
      '٢. أن يكونا ساترين لمحل الفرض (القدمين مع الكعبين العظمين الناتئين).',
      '٣. أن يكونا طاهرين مباحين وليس فيهما نجاسة.',
      '٤. أن يكون المسح في الحدث الأصغر؛ أما الجنابة وموجبات الغسل فتوجب خلعهما.',
      '٥. صفة المسح: يبلل يديه ويمسح ظاهر الخف من أطراف الأصابع إلى الساق بمرة واحدة.',
    ];

    return AppCard(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 19, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'شروط وضوابط المسح الشرعية',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...conditions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.0,
                    color: colors.text,
                    height: 1.4,
                  ),
                ),
              )),
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cancel_outlined, size: 16, color: colors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'مبطلات المسح: انقضاء المدة المحددة، أو خلع الخف بعد الحدث، أو حدوث ما يوجب الغسل الأكبر.',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
