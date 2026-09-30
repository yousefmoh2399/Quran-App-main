import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/constant/constant.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_screen_model_details.dart';
import 'package:quran_app_android/features/tafsser/data/models/tafaseerModel.dart';
import 'package:quran_app_android/features/tafsser/presentation/view_model/tafseer_details_view_model.dart';
import 'package:quran_app_android/features/tafsser/presentation/views/widget/ayah_tafseer_card.dart';

class TafseerDetailsView extends StatefulWidget {
  const TafseerDetailsView({super.key});

  @override
  State<TafseerDetailsView> createState() => _TafseerDetailsViewState();
}

class _TafseerDetailsViewState extends State<TafseerDetailsView> {
  double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = Get.find<SettingsServices>();

    final quranScreenVM = Get.isRegistered<QuranScreenViewModel>()
        ? Get.find<QuranScreenViewModel>()
        : Get.put(QuranScreenViewModel());

    final tafseerVM = Get.isRegistered<TafseerDetailsViewModel>()
        ? Get.find<TafseerDetailsViewModel>()
        : Get.put(TafseerDetailsViewModel());

    final surahIndex = settings.sharedPref?.getInt(tafseerIndex) ?? 0;

    return GetBuilder<QuranScreenViewModel>(
      init: quranScreenVM,
      builder: (quranCtrl) {
        return GetBuilder<TafseerDetailsViewModel>(
          init: tafseerVM,
          builder: (tafCtrl) {
            if (surahIndex < 0 || surahIndex >= quranCtrl.ayah_Model.length) {
              return const AppScaffold(
                title: 'تفسير الآيات',
                body: EmptyState(
                  title: 'لم يتم العثور على السورة',
                  message: 'يرجى العودة واختيار سورة مجدداً',
                ),
              );
            }

            final surah = quranCtrl.ayah_Model[surahIndex];
            final surahName = surah.name ?? 'السورة';
            final verses = surah.verses;

            // Find matching tafseer model for this surah
            final surahNumber = surahIndex + 1;
            final tafseerModelList = tafCtrl.tafaseerModel
                .firstWhereOrNull((m) => m.id == surahNumber);
            final tafseerData = tafseerModelList?.data ?? <DataModel>[];

            return AppScaffold(
              title: 'تفسير $surahName',
              constrainContentWidth: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.text_increase_rounded, size: 20),
                  color: colors.primary,
                  tooltip: 'تكبير الخط',
                  onPressed: () {
                    if (_fontSize < 32) {
                      setState(() => _fontSize += 2);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_decrease_rounded, size: 20),
                  color: colors.primary,
                  tooltip: 'تصغير الخط',
                  onPressed: () {
                    if (_fontSize > 14) {
                      setState(() => _fontSize -= 2);
                    }
                  },
                ),
              ],
              body: verses.isEmpty
                  ? const EmptyState(
                      title: 'لا توجد آيات',
                      message: 'البيانات غير متوفرة حالياً',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        final verse = verses[index];
                        final tafseerItem = index < tafseerData.length
                            ? tafseerData[index]
                            : null;

                        return AyahTafseerCard(
                          verse: verse,
                          tafseer: tafseerItem,
                          ayahIndex: index,
                          surahName: surahName,
                          fontSize: _fontSize,
                          onBookmark: () {
                            settings.sharedPref?.setInt(changeIndex_3, verse.id ?? index);
                            settings.sharedPref?.setInt(changeIndex_4, surahNumber);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم حفظ الموضع في $surahName آية ${verse.id ?? (index + 1)}',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                  ),
                                ),
                                backgroundColor: colors.primary,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.borderMd,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
