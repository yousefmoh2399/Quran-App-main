import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class DailyWirdCard extends StatelessWidget {
  const DailyWirdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final homeVM = Get.find<HomeViewModel>();

    return Obx(() {
      final plan = homeVM.currentWirdPlan.value;
      final todayPages = homeVM.todayPagesRead.value;

      if (plan == null) {
        return AppCard(
          variant: AppCardVariant.elevated,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: AppSpacing.paddingLg,
          backgroundColor: colors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: Icon(Icons.auto_stories_rounded, color: colors.primary, size: 24),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الورد اليومي للختمة',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        Text(
                          'حدد خطة منتظمة لوردك اليومي واستمر في الختمة',
                          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalMd,
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                icon: const Icon(Icons.add_task_rounded, size: 18.0),
                label: const Text(
                  'إعداد الورد اليومي',
                  style: TextStyle(fontFamily: AppTypography.uiFont, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openWirdPlanDialog(context, homeVM),
              ),
            ],
          ),
        );
      }

      // Active Plan Display
      final targetPages = (plan.endPage - plan.startPage + 1).clamp(1, 604);
      final currentRead = todayPages.clamp(0, targetPages);
      final progressRatio = (currentRead / targetPages).clamp(0.0, 1.0);
      final isCompleted = progressRatio >= 1.0;

      final settings = Get.find<SettingsServices>();
      final savedWirdPage = settings.sharedPref?.getInt('wird_last_page');
      final lastRead = homeVM.lastReadPage.value;

      int resumePage = plan.startPage;
      if (savedWirdPage != null && savedWirdPage >= plan.startPage && savedWirdPage <= plan.endPage) {
        resumePage = savedWirdPage;
      } else if (lastRead != null && lastRead >= plan.startPage && lastRead <= plan.endPage) {
        resumePage = lastRead;
      } else if (currentRead > 0) {
        resumePage = (plan.startPage + currentRead).clamp(plan.startPage, plan.endPage);
      }
      final bool hasStartedWird = (resumePage > plan.startPage) || (currentRead > 0);

      return AppCard(
        variant: AppCardVariant.elevated,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLg,
        backgroundColor: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title, streak badge, edit button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'الورد اليومي',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          AppSpacing.horizontalSm,
                          if (plan.streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.15),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(color: colors.accent.withOpacity(0.4)),
                              ),
                              child: Text(
                                '🔥 ${toArabicDigits(plan.streak)} يوم',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'من صـ ${toArabicDigits(plan.startPage)} إلى صـ ${toArabicDigits(plan.endPage)}',
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  color: colors.textMuted,
                  tooltip: 'تعديل الخطة',
                  onPressed: () => _openWirdPlanDialog(context, homeVM, existingPlan: plan),
                ),
              ],
            ),

            AppSpacing.verticalMd,

            // Progress text and bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted
                      ? '🎉 تم إنجاز ورد اليوم مباركاً!'
                      : 'قُرئ ${toArabicDigits(currentRead)} من ${toArabicDigits(targetPages)} صفحة',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? colors.primary : colors.text,
                  ),
                ),
                Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalXs,
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 7.0,
                backgroundColor: colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? colors.accent : colors.primary,
                ),
              ),
            ),

            AppSpacing.verticalMd,

            // Action Buttons: Start Wird vs Completed
            Row(
              children: [
                // "ابدأ الورد"
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11.0),
                      side: BorderSide(color: colors.primary),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: Icon(Icons.play_arrow_rounded, color: colors.primary, size: 20),
                    label: Text(
                      hasStartedWird ? 'أكمل الورد (صـ ${toArabicDigits(resumePage)})' : 'ابدأ الورد',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.mushaf,
                        arguments: {'pageNumber': resumePage},
                      )?.then((_) => homeVM.loadUserQuranData());
                    },
                  ),
                ),
                AppSpacing.horizontalSm,

                // "تم"
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? colors.accent : colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11.0),
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      isCompleted ? 'مكتمل اليوم' : 'تم',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      await homeVM.markWirdCompleted();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تقبل الله طاعتكم! تم تسجيل ورد اليوم بنجاح',
                              style: TextStyle(fontFamily: AppTypography.uiFont),
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _openWirdPlanDialog(
    BuildContext context,
    HomeViewModel homeVM, {
    WirdPlan? existingPlan,
  }) {
    openWirdPlanModal(context, homeVM, existingPlan: existingPlan);
  }
}

void openWirdPlanModal(
  BuildContext context,
  HomeViewModel homeVM, {
  WirdPlan? existingPlan,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WirdPlanModalSheet(
      homeVM: homeVM,
      existingPlan: existingPlan,
    ),
  );
}

class WirdPlanModalSheet extends StatefulWidget {
  final HomeViewModel homeVM;
  final WirdPlan? existingPlan;

  const WirdPlanModalSheet({
    super.key,
    required this.homeVM,
    this.existingPlan,
  });

  @override
  State<WirdPlanModalSheet> createState() => _WirdPlanModalSheetState();
}

class _WirdPlanModalSheetState extends State<WirdPlanModalSheet> {
  late WirdType _selectedType;
  late int _target;
  late int _startPage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingPlan?.type ?? WirdType.pagesPerDay;
    _target = widget.existingPlan?.target ?? 10;
    _startPage = widget.existingPlan?.startPage ?? 1;
  }

  void _save() async {
    final range = UserRepository.calculateWirdRange(
      type: _selectedType,
      target: _target,
      fromPage: _startPage,
    );

    final plan = (widget.existingPlan ??
            WirdPlan(
              type: _selectedType,
              target: _target,
              startDate: DateTime.now().toIso8601String().substring(0, 10),
              reminderTime: '08:00',
              enabled: true,
              startPage: range['startPage']!,
              endPage: range['endPage']!,
            ))
        .copyWith(
      type: _selectedType,
      target: _target,
      startPage: range['startPage']!,
      endPage: range['endPage']!,
    );

    await widget.homeVM.saveWirdPlan(plan);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ خطة الورد اليومي بنجاح',
            style: TextStyle(fontFamily: AppTypography.uiFont),
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: bottomInset + 20.0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
            ),
            AppSpacing.verticalSm,

            Text(
              widget.existingPlan != null ? 'تعديل خطة الورد' : 'إعداد خطة الورد اليومي',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const Divider(height: 20.0),

            // Type selector
            Text(
              'نوع الخطة',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalXs,
            Wrap(
              spacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('صفحات يومياً'),
                  selected: _selectedType == WirdType.pagesPerDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = WirdType.pagesPerDay);
                  },
                ),
                ChoiceChip(
                  label: const Text('ختمة في عدد أيام'),
                  selected: _selectedType == WirdType.khatmaInDays,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = WirdType.khatmaInDays);
                  },
                ),
                ChoiceChip(
                  label: const Text('أجزاء يومياً'),
                  selected: _selectedType == WirdType.juzPerDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = WirdType.juzPerDay);
                  },
                ),
              ],
            ),

            AppSpacing.verticalMd,

            // Target selector
            Text(
              _getTargetTitle(),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalXs,
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: colors.primary,
                  onPressed: () {
                    if (_target > 1) setState(() => _target--);
                  },
                ),
                Expanded(
                  child: Text(
                    '${toArabicDigits(_target)} ${_getTargetUnit()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: colors.primary,
                  onPressed: () {
                    setState(() => _target++);
                  },
                ),
              ],
            ),

            AppSpacing.verticalLg,

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13.0),
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              onPressed: _save,
              child: const Text(
                'حفظ الخطة',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetTitle() {
    switch (_selectedType) {
      case WirdType.pagesPerDay:
        return 'عدد الصفحات المستهدفة كل يوم:';
      case WirdType.khatmaInDays:
        return 'مدة الختمة المستهدفة بالأيام:';
      case WirdType.juzPerDay:
        return 'عدد الأجزاء المستهدفة كل يوم:';
    }
  }

  String _getTargetUnit() {
    switch (_selectedType) {
      case WirdType.pagesPerDay:
        return 'صفحات';
      case WirdType.khatmaInDays:
        return 'يوماً (ختمة كاملة)';
      case WirdType.juzPerDay:
        return 'أجزاء';
    }
  }
}
