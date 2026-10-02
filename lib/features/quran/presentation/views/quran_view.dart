import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/repositories/mushaf_repository.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/quran/data/models/juz_model.dart';
import 'package:quran_app_android/features/quran/data/models/model.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_view_model.dart';
import 'widget/juz_index_item.dart';
import 'widget/quran_continue_card.dart';
import 'widget/quran_filter_chips_bar.dart';
import 'widget/surah_index_item.dart';
import 'quran_search_view.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSurah({
    required NameModel model,
    required QuranViewModel ctrl,
    int? specificPage,
  }) async {
    final prefs = Get.find<SettingsServices>().sharedPref;
    final surahId = model.id ?? 1;
    final mushafRepo = MushafRepository();
    final targetPage = specificPage ?? (await mushafRepo.getSurahStart(surahId) ?? 1);

    // Update last read
    prefs?.setInt('mushaf_last_page', targetPage);
    prefs?.setInt('mushaf_last_surah', surahId);
    prefs?.setString('mushaf_last_surah_name', model.name ?? '');
    prefs?.setString('lastRead', 'سورة ${model.name} - صفحة $targetPage');
    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().getLastRead();
    }

    await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': targetPage});
    await ctrl.loadMarks();
  }

  Future<void> _openJuz({
    required JuzModel juz,
    required QuranViewModel ctrl,
    int? specificPage,
  }) async {
    final mushafRepo = MushafRepository();
    final targetPage = specificPage ?? (await mushafRepo.getJuzStart(juz.number) ?? 1);
    final prefs = Get.find<SettingsServices>().sharedPref;
    prefs?.setInt('mushaf_last_page', targetPage);
    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().getLastRead();
    }

    await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': targetPage});
    await ctrl.loadMarks();
  }

  Future<void> _continueReading(QuranViewModel ctrl) async {
    final targetPage = ctrl.marksAggregate?.lastReadPage ?? 1;
    await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': targetPage});
    await ctrl.loadMarks();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final quranVM = Get.isRegistered<QuranViewModel>()
        ? Get.find<QuranViewModel>()
        : Get.put(QuranViewModel());

    return AppScaffold(
      title: 'فهرس القرآن الكريم',
      constrainContentWidth: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.manage_search_rounded),
          tooltip: 'البحث في نص الآيات',
          onPressed: () => Get.to(
            () => const QuranSearchView(),
            transition: Transition.cupertino,
          ),
        ),
      ],
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
          final filteredSurahs = allSurahs.where((s) {
            if (!ctrl.matchesSurahFilter(s)) return false;
            if (_searchQuery.trim().isEmpty) return true;
            final name = s.name?.toLowerCase() ?? '';
            final numStr = s.id?.toString() ?? '';
            final q = _searchQuery.trim().toLowerCase();
            return name.contains(q) || numStr.contains(q);
          }).toList();

          final allJuz = JuzModel.allJuz;
          final filteredJuz = allJuz.where((j) {
            if (!ctrl.matchesJuzFilter(j)) return false;
            if (_searchQuery.trim().isEmpty) return true;
            final title = j.title.toLowerCase();
            final surah = j.startSurahName.toLowerCase();
            final q = _searchQuery.trim().toLowerCase();
            return title.contains(q) || surah.contains(q) || j.number.toString().contains(q);
          }).toList();

          final hasLastRead = ctrl.marksAggregate?.lastReadPage != null &&
              ctrl.marksAggregate!.lastReadPage! > 0;

          return Column(
            children: [
              // 1. Search input
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

              // Search in Ayahs banner when user is searching
              if (_searchQuery.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                  child: Material(
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        Get.to(
                          () => const QuranSearchView(),
                          transition: Transition.cupertino,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.manage_search_rounded, size: 20, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ابحث عن "$_searchQuery" في نص آيات القرآن الكريم...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Pinned Top Card: "تابع من سورة [الاسم] صفحة [الرقم]"
              if (hasLastRead && _searchQuery.isEmpty)
                QuranContinueReadingCard(
                  surahName: ctrl.marksAggregate?.lastReadSurahName ?? '',
                  pageNumber: ctrl.marksAggregate!.lastReadPage!,
                  onTap: () => _continueReading(ctrl),
                ),

              // 3. Quick Filter Chips Bar: [الكل / المحفوظ / عليها علامات]
              QuranFilterChipsBar(
                activeFilter: ctrl.activeFilter,
                onFilterChanged: (filter) => ctrl.setFilter(filter),
                memorizedCount: _tabController.index == 0
                    ? ctrl.memorizedSurahsCount
                    : ctrl.memorizedJuzsCount,
                markedCount: _tabController.index == 0
                    ? ctrl.markedSurahsCount
                    : ctrl.markedJuzsCount,
              ),

              // 4. TabBar: السور / الأجزاء
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
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 18),
                          AppSpacing.horizontalXs,
                          Text('السور (${filteredSurahs.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.format_list_numbered_rtl_rounded, size: 18),
                          AppSpacing.horizontalXs,
                          Text('الأجزاء (${filteredJuz.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSm,

              // 5. TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Surahs list
                    filteredSurahs.isEmpty
                        ? const EmptyState(
                            title: 'لا توجد سور مطابقة',
                            message: 'تأكد من كتابة اسم السورة بشكل صحيح أو جرّب فيلتراً آخر',
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
                              final marks = ctrl.marksAggregate?.surahs[surah.id];

                              return SurahIndexItem(
                                surah: surah,
                                marks: marks,
                                onTap: () {
                                  if (marks?.isLastRead == true && marks?.lastReadPage != null) {
                                    _openSurah(
                                      model: surah,
                                      ctrl: ctrl,
                                      specificPage: marks!.lastReadPage,
                                    );
                                  } else if (marks?.hasBookmark == true && marks?.bookmarkedPage != null) {
                                    _openSurah(
                                      model: surah,
                                      ctrl: ctrl,
                                      specificPage: marks!.bookmarkedPage,
                                    );
                                  } else {
                                    _openSurah(
                                      model: surah,
                                      ctrl: ctrl,
                                    );
                                  }
                                },
                                onStartFromBeginning: (marks?.isLastRead == true ||
                                        (marks?.hasBookmark == true && marks?.bookmarkedPage != null))
                                    ? () => _openSurah(
                                          model: surah,
                                          ctrl: ctrl,
                                          specificPage: marks?.startPage,
                                        )
                                    : null,
                              );
                            },
                          ),

                    // Tab 2: Juz' list
                    filteredJuz.isEmpty
                        ? const EmptyState(
                            title: 'لا توجد أجزاء مطابقة',
                            message: 'تأكد من كتابة اسم الجزء أو السورة بشكل صحيح أو جرّب فيلتراً آخر',
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
                              final marks = ctrl.marksAggregate?.juzs[juz.number];

                              return JuzIndexItem(
                                juz: juz,
                                marks: marks,
                                onTap: () {
                                  if (marks?.isLastRead == true && marks?.lastReadPage != null) {
                                    _openJuz(
                                      juz: juz,
                                      ctrl: ctrl,
                                      specificPage: marks!.lastReadPage,
                                    );
                                  } else {
                                    _openJuz(
                                      juz: juz,
                                      ctrl: ctrl,
                                    );
                                  }
                                },
                                onStartFromBeginning: marks?.isLastRead == true
                                    ? () => _openJuz(
                                          juz: juz,
                                          ctrl: ctrl,
                                          specificPage: marks?.startPage,
                                        )
                                    : null,
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
