import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/daily_wird_card.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class ContinueReadingWirdCard extends StatelessWidget {
  const ContinueReadingWirdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();
    final homeVM = Get.find<HomeViewModel>();

    return Obx(() {
      final lastPage = homeVM.lastReadPage.value ??
          settings.sharedPref?.getInt('mushaf_last_page') ??
          1;
      final lastReadRaw = settings.sharedPref?.getString('lastRead');
      final hasLastRead = lastReadRaw != null && lastReadRaw.trim().isNotEmpty;
      final displayTitle = hasLastRead ? lastReadRaw : 'سورة الفاتحة - صفحة ١';

      final plan = homeVM.currentWirdPlan.value;
      final todayPages = homeVM.todayPagesRead.value;

      return AppCard(
        variant: AppCardVariant.elevated,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLg,
        backgroundColor: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Continue Reading
            InkWell(
              borderRadius: AppRadius.borderMd,
              onTap: () {
                Get.toNamed(
                  AppRoutes.mushaf,
                  arguments: {'pageNumber': lastPage},
                )?.then((_) => homeVM.loadUserQuranData());
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'تابع القراءة',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.accent,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'صـ ${toArabicDigits(lastPage)}',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(
                height: 1,
                thickness: 0.8,
                color: colors.divider.withOpacity(0.5),
              ),
            ),

            // Section 2: Daily Wird Progress
            if (plan == null) ...[
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'الورد اليومي: لم تحدد ورداً بعد',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      foregroundColor: colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text(
                      'تحديد ورد',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => openWirdPlanModal(context, homeVM),
                  ),
                ],
              ),
            ] else ...[
              _buildWirdProgress(context, colors, textTheme, homeVM, plan, todayPages),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildWirdProgress(
    BuildContext context,
    AppColorsExtension colors,
    TextTheme textTheme,
    HomeViewModel homeVM,
    dynamic plan,
    int todayPages,
  ) {
    final int targetPages = ((plan.endPage - plan.startPage + 1) as num).clamp(1, 604).toInt();
    final int currentRead = todayPages.clamp(0, targetPages).toInt();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الورد اليومي',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                if (plan.streak > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 12, color: colors.accent),
                        const SizedBox(width: 2),
                        Text(
                          '${toArabicDigits(plan.streak)} يوم',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${toArabicDigits(currentRead)} / ${toArabicDigits(targetPages)} صـ',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  color: colors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'تعديل الخطة',
                  onPressed: () => openWirdPlanModal(context, homeVM, existingPlan: plan),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: progressRatio,
            minHeight: 6.0,
            backgroundColor: colors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? colors.accent : colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isCompleted
                    ? 'تم إنجاز ورد اليوم مباركاً'
                    : 'من صـ ${toArabicDigits(plan.startPage)} إلى صـ ${toArabicDigits(plan.endPage)}',
                style: textTheme.bodySmall?.copyWith(
                  color: isCompleted ? colors.primary : colors.textMuted,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isCompleted)
              InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.mushaf,
                    arguments: {'pageNumber': resumePage},
                  )?.then((_) => homeVM.loadUserQuranData());
                },
                borderRadius: AppRadius.borderSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasStartedWird
                            ? 'أكمل (صـ ${toArabicDigits(resumePage)})'
                            : 'قراءة الورد',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.play_arrow_rounded, size: 16, color: colors.primary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
