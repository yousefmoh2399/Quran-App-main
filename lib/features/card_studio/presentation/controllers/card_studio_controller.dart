import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../../../core/util/app_snackbar.dart';
import '../../../../core/util/share_helper.dart';
import '../../../azkar/data/smart_azkar_service.dart';
import '../../../home/data/models/daily_tadabbur_model.dart';
import '../../../home/data/services/daily_tadabbur_service.dart';
import '../../data/models/card_studio_theme_preset.dart';

enum CardContentMode {
  quran('آية من المصحف', Icons.menu_book_rounded),
  zikr('ذكر ودعاء مأثور', Icons.volunteer_activism_rounded),
  tadabbur('لطيفة وتدبر', Icons.lightbulb_outline_rounded),
  custom('نص حر مخصص', Icons.edit_note_rounded);

  final String title;
  final IconData icon;

  const CardContentMode(this.title, this.icon);
}

class CardStudioController extends GetxController {
  final QuranRepository _quranRepo = QuranRepository();

  // Mode
  final Rx<CardContentMode> contentMode = CardContentMode.quran.obs;

  // Content Data
  final RxString mainText = '﴿ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ﴾'.obs;
  final RxString subtitleText = 'سورة البقرة • آية 255'.obs;
  final RxString tafsirOrNote = ''.obs;

  // Surahs & Ayahs (Offline)
  final RxList<SurahEntity> surahs = <SurahEntity>[].obs;
  final Rx<SurahEntity?> selectedSurah = Rx<SurahEntity?>(null);
  final RxList<AyahEntity> ayahs = <AyahEntity>[].obs;
  final Rx<AyahEntity?> selectedAyah = Rx<AyahEntity?>(null);
  final RxBool isLoadingSurahs = false.obs;

  // Visual Customization
  final Rx<CardStudioThemePreset> selectedPreset = CardStudioThemePreset.parchment.obs;
  final Rx<CardAspectRatio> selectedRatio = CardAspectRatio.story.obs;
  final Rx<CardIslamicFrameStyle> selectedFrame = CardIslamicFrameStyle.andalusian.obs;
  final Rx<CardStudioFontFamily> selectedFont = CardStudioFontFamily.amiri.obs;
  final RxDouble fontSize = 23.0.obs;
  final RxBool showBismillah = true.obs;
  final RxBool showBrackets = true.obs;
  final RxBool showWatermark = true.obs;
  final Rx<TextAlign> textAlignment = TextAlign.center.obs;

  // Export state
  final RxBool isExporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      isLoadingSurahs.value = true;
      final list = await _quranRepo.getSurahs();
      surahs.assignAll(list);
      if (surahs.isNotEmpty) {
        selectedSurah.value = surahs.first;
        await loadAyahsForSurah(surahs.first.id);
      }
    } catch (e) {
      debugPrint('Error loading surahs in card studio: $e');
    } finally {
      isLoadingSurahs.value = false;
    }
  }

  Future<void> loadAyahsForSurah(int surahId) async {
    try {
      final list = await _quranRepo.getAyahs(surahId);
      ayahs.assignAll(list);
      if (ayahs.isNotEmpty) {
        selectedAyah.value = ayahs.first;
      }
    } catch (e) {
      debugPrint('Error loading ayahs in card studio: $e');
    }
  }

  /// Initialize with external arguments (e.g. from Mushaf or Daily Tadabbur)
  void initWithArguments({
    String? text,
    String? surahName,
    int? ayahNumber,
    String? tafsir,
    String? source,
    String? mode,
  }) {
    if (text != null && text.isNotEmpty) {
      mainText.value = text;
    }
    if (surahName != null && ayahNumber != null) {
      subtitleText.value = '$surahName • آية $ayahNumber';
    } else if (source != null && source.isNotEmpty) {
      subtitleText.value = source;
    }
    if (tafsir != null) {
      tafsirOrNote.value = tafsir;
    }
    if (mode == 'tadabbur') {
      contentMode.value = CardContentMode.tadabbur;
    } else if (mode == 'zikr') {
      contentMode.value = CardContentMode.zikr;
    }
  }

  void setContentMode(CardContentMode mode) {
    contentMode.value = mode;
    AppHaptics.selection();

    if (mode == CardContentMode.quran) {
      showBismillah.value = true;
      showBrackets.value = true;
      if (selectedAyah.value != null && selectedSurah.value != null) {
        mainText.value = selectedAyah.value!.textAr;
        subtitleText.value = 'سورة ${selectedSurah.value!.nameAr} • آية ${selectedAyah.value!.ayahNumber}';
      }
    } else if (mode == CardContentMode.zikr) {
      showBismillah.value = false;
      showBrackets.value = false;
      // Default to Sayyid al-Istighfar
      mainText.value = 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ';
      subtitleText.value = 'سيد الاستغفار • صحيح البخاري';
    } else if (mode == CardContentMode.tadabbur) {
      showBismillah.value = true;
      showBrackets.value = true;
      final tadabbur = DailyTadabburService.instance.getTodayTadabbur();
      mainText.value = tadabbur.ayahText;
      subtitleText.value = '${tadabbur.surahName} • آية ${tadabbur.ayahNumber} | ${tadabbur.scholar}';
      tafsirOrNote.value = tadabbur.reflection;
    } else if (mode == CardContentMode.custom) {
      showBismillah.value = true;
      showBrackets.value = false;
    }
  }

  void onSurahChanged(SurahEntity? surah) async {
    if (surah == null) return;
    selectedSurah.value = surah;
    await loadAyahsForSurah(surah.id);
    if (ayahs.isNotEmpty) {
      onAyahChanged(ayahs.first);
    }
  }

  void onAyahChanged(AyahEntity? ayah) {
    if (ayah == null) return;
    selectedAyah.value = ayah;
    mainText.value = ayah.textAr;
    final sName = selectedSurah.value?.nameAr ?? '';
    subtitleText.value = 'سورة $sName • آية ${ayah.ayahNumber}';
    tafsirOrNote.value = ayah.tafsirMuyassar ?? '';
    AppHaptics.selection();
  }

  void applyZikr(ContextualZikr zikr) {
    mainText.value = zikr.text;
    subtitleText.value = zikr.virture ?? zikr.type.title;
    showBismillah.value = false;
    showBrackets.value = false;
    AppHaptics.selection();
  }

  void applyTadabbur(DailyTadabburItem item) {
    mainText.value = item.ayahText;
    subtitleText.value = '${item.surahName} • آية ${item.ayahNumber} (${item.scholar})';
    tafsirOrNote.value = item.reflection;
    showBismillah.value = true;
    showBrackets.value = true;
    AppHaptics.selection();
  }

  void setPreset(CardStudioThemePreset preset) {
    selectedPreset.value = preset;
    AppHaptics.selection();
  }

  void setRatio(CardAspectRatio ratio) {
    selectedRatio.value = ratio;
    AppHaptics.selection();
  }

  void setFrame(CardIslamicFrameStyle frame) {
    selectedFrame.value = frame;
    AppHaptics.selection();
  }

  void setFont(CardStudioFontFamily font) {
    selectedFont.value = font;
    AppHaptics.selection();
  }

  /// Exports card to high-resolution PNG image and opens native sharing sheet
  Future<void> exportAndShare(BuildContext context, GlobalKey cardKey) async {
    if (isExporting.value) return;
    final origin = getSharePositionOrigin(context);
    isExporting.value = true;
    AppHaptics.itemCompleted();

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // 3.0 pixelRatio provides ultra sharp 300+ DPI images for 1080x1920 Status / Story
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'taqarrab_card_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        final xFile = XFile(file.path, mimeType: 'image/png');

        await Share.shareXFiles(
          [xFile],
          text: '${mainText.value}\n[${subtitleText.value}]\nعبر تطبيق تقرّب',
          sharePositionOrigin: origin,
        );
      }
    } catch (e) {
      debugPrint('Error generating card image: $e');
      AppSnackbar.show(
        'تنبيه',
        'تعذر إنشاء الصورة، يرجى المحاولة ثانية',
        backgroundColor: Colors.orange.shade800,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Saves the card image to the device files
  Future<void> saveToDevice(BuildContext context, GlobalKey cardKey) async {
    if (isExporting.value) return;
    isExporting.value = true;
    AppHaptics.itemCompleted();

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'بطاقة_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        if (context.mounted) {
          AppSnackbar.show(
            'تم حفظ الصورة بنجاح ✅',
            'تم حفظ البطاقة بجودة فائقة في مجلد التطبيق',
            context: context,
            backgroundColor: const Color(0xFF0F5C4A),
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          'خطأ',
          'تعذر حفظ الصورة: $e',
          context: context,
          backgroundColor: Colors.red.shade800,
        );
      }
    } finally {
      isExporting.value = false;
    }
  }

  void copyText() {
    Clipboard.setData(ClipboardData(
      text: '${mainText.value}\n${subtitleText.value}\n— تطبيق تقرّب',
    ));
    AppHaptics.selection();
    AppSnackbar.show(
      'تم النسخ',
      'تم نسخ النص إلى الحافظة',
      duration: const Duration(seconds: 2),
    );
  }
}
