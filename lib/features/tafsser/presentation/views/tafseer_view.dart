import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/constant/constant.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_screen_model_details.dart';
import 'package:quran_app_android/features/tafsser/presentation/view_model/tafseer_details_view_model.dart';

class TafseerView extends StatefulWidget {
  const TafseerView({super.key});

  @override
  State<TafseerView> createState() => _TafseerViewState();
}

class _TafseerViewState extends State<TafseerView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();

    final quranScreenVM = Get.isRegistered<QuranScreenViewModel>()
        ? Get.find<QuranScreenViewModel>()
        : Get.put(QuranScreenViewModel());

    if (!Get.isRegistered<TafseerDetailsViewModel>()) {
      Get.put(TafseerDetailsViewModel());
    }

    return AppScaffold(
      title: 'التفسير الميسر',
      constrainContentWidth: true,
      body: GetBuilder<QuranScreenViewModel>(
        init: quranScreenVM,
        builder: (ctrl) {
          if (ctrl.isLoading.value && ctrl.ayah_Model.isEmpty) {
            return ListView.separated(
              padding: AppSpacing.screen,
              itemCount: 8,
              separatorBuilder: (_, __) => AppSpacing.verticalMd,
              itemBuilder: (_, __) => const LoadingSkeleton(
                width: double.infinity,
                height: 72,
                borderRadius: AppRadius.borderMd,
              ),
            );
          }

          final allSurahs = ctrl.ayah_Model;
          final filteredSurahs = _searchQuery.trim().isEmpty
              ? allSurahs
              : allSurahs.where((s) {
                  final name = s.name?.toLowerCase() ?? '';
                  return name.contains(_searchQuery.trim().toLowerCase());
                }).toList();

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم السورة في التفسير...',
                    prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: filteredSurahs.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد سور مطابقة',
                        message: 'تأكد من كتابة اسم السورة بشكل صحيح',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.xl,
                          top: AppSpacing.xs,
                        ),
                        itemCount: filteredSurahs.length,
                        separatorBuilder: (_, __) => AppSpacing.verticalSm,
                        itemBuilder: (context, index) {
                          final surah = filteredSurahs[index];
                          final originalIndex = allSurahs.indexOf(surah);
                          final surahNum = (originalIndex >= 0 ? originalIndex : index) + 1;
                          final versesCount = surah.verses.length;

                          return AppCard(
                            variant: AppCardVariant.elevated,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            onTap: () {
                              settings.sharedPref!.setInt(
                                tafseerIndex,
                                originalIndex >= 0 ? originalIndex : index,
                              );
                              Get.toNamed(AppRoutes.detailsTafseer);
                            },
                            child: Row(
                              children: [
                                // Surah Number Badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.1),
                                    borderRadius: AppRadius.borderMd,
                                    border: Border.all(
                                      color: colors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$surahNum',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                AppSpacing.horizontalMd,
                                // Surah Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        surah.name ?? '',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: AppTypography.decorativeFont,
                                          color: colors.text,
                                        ),
                                      ),
                                      AppSpacing.verticalXs,
                                      Text(
                                        '$versesCount آية',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.horizontalSm,
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: colors.textMuted.withOpacity(0.6),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
