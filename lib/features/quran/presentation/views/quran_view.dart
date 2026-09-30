import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/repositories/mushaf_repository.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/quran/data/models/juz_model.dart';
import 'package:quran_app_android/features/quran/data/models/model.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_screen_model_details.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_view_model.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSurah({
    required int index,
    required NameModel model,
    required SettingsServices settings,
    required QuranScreenViewModel quranScreenVM,
  }) async {
    final prefs = settings.sharedPref;
    final surahId = model.id ?? (index + 1);
    final mushafRepo = MushafRepository();
    final targetPage = await mushafRepo.getSurahStart(surahId) ?? 1;

    // Update last read
    prefs?.setInt('mushaf_last_page', targetPage);
    prefs?.setInt('mushaf_last_surah', surahId);
    prefs?.setString('mushaf_last_surah_name', model.name ?? '');
    prefs?.setString('lastRead', 'سورة ${model.name} - صفحة $targetPage');
    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().getLastRead();
    }

    await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': targetPage});
  }

  Future<void> _openJuz(JuzModel juz) async {
    final mushafRepo = MushafRepository();
    final targetPage = await mushafRepo.getJuzStart(juz.number) ?? 1;
    final prefs = Get.find<SettingsServices>().sharedPref;
    prefs?.setInt('mushaf_last_page', targetPage);
    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().getLastRead();
    }
    await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': targetPage});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();

    final quranVM = Get.isRegistered<QuranViewModel>()
        ? Get.find<QuranViewModel>()
        : Get.put(QuranViewModel());

    final quranScreenVM = Get.isRegistered<QuranScreenViewModel>()
        ? Get.find<QuranScreenViewModel>()
        : Get.put(QuranScreenViewModel());

    return AppScaffold(
      title: 'فهرس القرآن الكريم',
      constrainContentWidth: true,
      body: GetBuilder<QuranViewModel>(
        init: quranVM,
        builder: (ctrl) {
          if (ctrl.isLoading && ctrl.nameModel.isEmpty) {
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

          final allSurahs = ctrl.nameModel;
          final filteredSurahs = _searchQuery.trim().isEmpty
              ? allSurahs
              : allSurahs.where((s) {
                  final name = s.name?.toLowerCase() ?? '';
                  final numStr = s.id?.toString() ?? '';
                  return name.contains(_searchQuery.trim().toLowerCase()) ||
                      numStr.contains(_searchQuery.trim());
                }).toList();

          final filteredJuz = _searchQuery.trim().isEmpty
              ? JuzModel.allJuz
              : JuzModel.allJuz.where((j) {
                  final title = j.title.toLowerCase();
                  final surah = j.startSurahName.toLowerCase();
                  return title.contains(_searchQuery.trim().toLowerCase()) ||
                      surah.contains(_searchQuery.trim().toLowerCase()) ||
                      j.number.toString().contains(_searchQuery.trim());
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
                    hintText: 'ابحث عن سورة أو جزء بالاسم أو الرقم...',
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
              // TabBar: السور / الأجزاء
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: colors.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colors.primary,
                    borderRadius: AppRadius.borderMd,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.textMuted,
                  labelStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 18),
                          AppSpacing.horizontalXs,
                          Text('السور (١١٤)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_numbered_rtl_rounded, size: 18),
                          AppSpacing.horizontalXs,
                          Text('الأجزاء (٣٠)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSm,
              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Surahs list
                    filteredSurahs.isEmpty
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
                              final surahNum = surah.id ?? (index + 1);
                              final isSaved = settings.sharedPref?.getInt('currentIndex4Quran') == surah.id;
                              final typeArabic = surah.type == 'meccan' ? 'مكية' : 'مدنية';

                              return AppCard(
                                variant: AppCardVariant.elevated,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                                onTap: () => _openSurah(
                                  index: originalIndex >= 0 ? originalIndex : index,
                                  model: surah,
                                  settings: settings,
                                  quranScreenVM: quranScreenVM,
                                ),
                                child: Row(
                                  children: [
                                    // Number badge
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
                                    // Surah details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'سورة ${surah.name ?? ''}',
                                                style: textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: AppTypography.decorativeFont,
                                                  color: colors.text,
                                                ),
                                              ),
                                              if (isSaved) ...[
                                                AppSpacing.horizontalXs,
                                                Icon(
                                                  Icons.bookmark_added_rounded,
                                                  size: 16,
                                                  color: colors.accent,
                                                ),
                                              ],
                                            ],
                                          ),
                                          AppSpacing.verticalXs,
                                          Text(
                                            '$typeArabic • ${surah.total_verses ?? 0} آيات',
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
                    // Tab 2: Juz' list
                    filteredJuz.isEmpty
                        ? const EmptyState(
                            title: 'لا توجد أجزاء مطابقة',
                            message: 'تأكد من كتابة اسم الجزء أو السورة بشكل صحيح',
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
                            itemCount: filteredJuz.length,
                            separatorBuilder: (_, __) => AppSpacing.verticalSm,
                            itemBuilder: (context, index) {
                              final juz = filteredJuz[index];

                              return AppCard(
                                variant: AppCardVariant.elevated,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                                onTap: () => _openJuz(juz),
                                child: Row(
                                  children: [
                                    // Juz number badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: colors.accent.withOpacity(0.12),
                                        borderRadius: AppRadius.borderMd,
                                        border: Border.all(
                                          color: colors.accent.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${juz.number}',
                                          style: textTheme.labelMedium?.copyWith(
                                            color: colors.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    AppSpacing.horizontalMd,
                                    // Juz Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            juz.title,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.text,
                                            ),
                                          ),
                                          AppSpacing.verticalXs,
                                          Text(
                                            'يبدأ من سورة ${juz.startSurahName} (آية ${juz.startAyah})',
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
