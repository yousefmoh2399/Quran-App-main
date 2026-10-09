import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../../home/data/services/daily_tadabbur_service.dart';
import '../../data/models/card_studio_theme_preset.dart';
import '../controllers/card_studio_controller.dart';
import '../widgets/card_canvas_widget.dart';

class CardStudioView extends StatefulWidget {
  final String? initialText;
  final String? initialSurahName;
  final int? initialAyahNumber;
  final String? initialTafsir;
  final String? initialSource;
  final String? initialMode;

  const CardStudioView({
    super.key,
    this.initialText,
    this.initialSurahName,
    this.initialAyahNumber,
    this.initialTafsir,
    this.initialSource,
    this.initialMode,
  });

  @override
  State<CardStudioView> createState() => _CardStudioViewState();
}

class _CardStudioViewState extends State<CardStudioView> with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late final CardStudioController _controller;
  late final TabController _tabController;
  final TextEditingController _customTextCtrl = TextEditingController();
  final TextEditingController _customSubCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<CardStudioController>()
        ? Get.find<CardStudioController>()
        : Get.put(CardStudioController());
    _tabController = TabController(length: 4, vsync: this);

    // Read initial data either from widget or Get.arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final text = widget.initialText ?? args?['text'] as String?;
    final surah = widget.initialSurahName ?? args?['surahName'] as String?;
    final ayahNum = widget.initialAyahNumber ?? args?['ayahNumber'] as int?;
    final tafsir = widget.initialTafsir ?? args?['tafsir'] as String?;
    final source = widget.initialSource ?? args?['source'] as String?;
    final mode = widget.initialMode ?? args?['mode'] as String?;

    if (text != null && text.isNotEmpty) {
      _controller.initWithArguments(
        text: text,
        surahName: surah,
        ayahNumber: ayahNum,
        tafsir: tafsir,
        source: source,
        mode: mode,
      );
      _customTextCtrl.text = text;
      if (surah != null && ayahNum != null) {
        _customSubCtrl.text = '$surah • آية $ayahNum';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTextCtrl.dispose();
    _customSubCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        title: 'استوديو بطاقات القرآن والأدعية',
        actions: [
          IconButton(
            tooltip: 'نسخ النص',
            icon: Icon(Icons.copy_rounded, color: colors.primary),
            onPressed: () => _controller.copyText(),
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Aspect Ratio Selector (Story 9:16 / Square 1:1 / Card 4:5)
              _buildAspectRatioBar(colors),
              const SizedBox(height: 14),

              // 2. Live Canvas Preview
              _buildCanvasPreview(colors),
              const SizedBox(height: 16),

              // 3. Tab Navigation (Content / Theme / Frame / Typography)
              _buildControlTabs(colors),
              const SizedBox(height: 12),

              // 4. Tab Content Panels
              SizedBox(
                height: 250,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentTab(colors),
                    _buildThemesTab(colors),
                    _buildFramesTab(colors),
                    _buildTypographyTab(colors),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Export Actions
              _buildActionButtons(colors),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAspectRatioBar(AppColorsExtension colors) {
    return Obx(() {
      final current = _controller.selectedRatio.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: CardAspectRatio.values.map((r) {
            final isSelected = current == r;
            return Expanded(
              child: InkWell(
                onTap: () => _controller.setRatio(r),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: isSelected ? Border.all(color: colors.primary, width: 1.2) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        r.icon,
                        size: 16,
                        color: isSelected ? colors.primary : colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? colors.primary : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildCanvasPreview(AppColorsExtension colors) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380, maxWidth: 360),
        child: RepaintBoundary(
          key: _cardKey,
          child: Obx(() {
            return CardCanvasWidget(
              preset: _controller.selectedPreset.value,
              frameStyle: _controller.selectedFrame.value,
              font: _controller.selectedFont.value,
              ratio: _controller.selectedRatio.value,
              mainText: _controller.mainText.value,
              subtitleText: _controller.subtitleText.value,
              tafsirOrNote: _controller.tafsirOrNote.value.isNotEmpty
                  ? _controller.tafsirOrNote.value
                  : null,
              fontSize: _controller.fontSize.value,
              showBismillah: _controller.showBismillah.value,
              showBrackets: _controller.showBrackets.value,
              showWatermark: _controller.showWatermark.value,
              alignment: _controller.textAlignment.value,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildControlTabs(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.divider),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: colors.primary,
        indicatorWeight: 3,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.uiFont,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
        tabs: const [
          Tab(text: 'المحتوى', icon: Icon(Icons.edit_note_rounded, size: 18)),
          Tab(text: 'الخلفية', icon: Icon(Icons.palette_outlined, size: 18)),
          Tab(text: 'الإطار', icon: Icon(Icons.crop_free_rounded, size: 18)),
          Tab(text: 'الخط والضبط', icon: Icon(Icons.text_fields_rounded, size: 18)),
        ],
      ),
    );
  }

  Widget _buildContentTab(AppColorsExtension colors) {
    return Obx(() {
      final mode = _controller.contentMode.value;

      return AppCard(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode switcher chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CardContentMode.values.map((m) {
                    final isSel = mode == m;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        selected: isSel,
                        label: Text(m.title),
                        avatar: Icon(m.icon, size: 16),
                        selectedColor: colors.primary.withOpacity(0.18),
                        labelStyle: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? colors.primary : colors.text,
                        ),
                        onSelected: (_) => _controller.setContentMode(m),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 18),

              // Quran Mode: Pick Surah and Ayah
              if (mode == CardContentMode.quran) ...[
                if (_controller.isLoadingSurahs.value)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      // Surahs Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: _controller.selectedSurah.value?.id,
                          decoration: InputDecoration(
                            labelText: 'السورة',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: _controller.surahs.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text('${s.id}. سورة ${s.nameAr}', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              final found = _controller.surahs.firstWhereOrNull((s) => s.id == id);
                              _controller.onSurahChanged(found);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ayahs Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _controller.selectedAyah.value?.ayahNumber,
                          decoration: InputDecoration(
                            labelText: 'الآية',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: _controller.ayahs.map((a) {
                            return DropdownMenuItem<int>(
                              value: a.ayahNumber,
                              child: Text('آية ${a.ayahNumber}', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (ayahNum) {
                            if (ayahNum != null) {
                              final found = _controller.ayahs.firstWhereOrNull((a) => a.ayahNumber == ayahNum);
                              _controller.onAyahChanged(found);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
              ],

              // Zikr Mode: Sample Azkar Chips
              if (mode == CardContentMode.zikr) ...[
                const Text(
                  'اختر من الأذكار النبوية المأثورة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickZikrChip(
                      label: 'سيد الاستغفار',
                      text: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ',
                      source: 'سيد الاستغفار • صحيح البخاري',
                    ),
                    _buildQuickZikrChip(
                      label: 'الصلاة على النبي ﷺ',
                      text: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
                      source: 'الصلاة الإبراهيمية',
                    ),
                    _buildQuickZikrChip(
                      label: 'دعاء تفريج الكرب',
                      text: 'لاَ إِلَهَ إِلاَّ اللَّهُ العَظِيمُ الحَلِيمُ، لاَ إِلَهَ إِلاَّ اللَّهُ رَبُّ العَرْشِ العَظِيمِ، لاَ إِلَهَ إِلاَّ اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الأَرْضِ وَرَبُّ العَرْشِ الكَرِيمِ',
                      source: 'دعاء الكرب • متفق عليه',
                    ),
                    _buildQuickZikrChip(
                      label: 'الحوقلة (كنز الجنة)',
                      text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
                      source: 'كنز من كنوز الجنة',
                    ),
                  ],
                ),
              ],

              // Tadabbur Mode
              if (mode == CardContentMode.tadabbur) ...[
                Text(
                  'لطيفة اليوم: ${_controller.subtitleText.value}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  _controller.tafsirOrNote.value,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('تبديل للتدبر التالي'),
                  onPressed: () {
                    final next = DailyTadabburService.items[
                        (DateTime.now().millisecond) % DailyTadabburService.items.length];
                    _controller.applyTadabbur(next);
                  },
                ),
              ],

              // Custom Text Mode
              if (mode == CardContentMode.custom) ...[
                TextField(
                  controller: _customTextCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'اكتب نص الآية أو الذكر هنا',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _controller.mainText.value = v,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customSubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العزو أو المصدر (مثال: سورة النور • آية 35)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _controller.subtitleText.value = v,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickZikrChip({
    required String label,
    required String text,
    required String source,
  }) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        _controller.mainText.value = text;
        _controller.subtitleText.value = source;
        _controller.showBismillah.value = false;
        _controller.showBrackets.value = false;
      },
    );
  }

  Widget _buildThemesTab(AppColorsExtension colors) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Obx(() {
        final current = _controller.selectedPreset.value;

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: CardStudioThemePreset.presets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final p = CardStudioThemePreset.presets[i];
            final isSelected = current.id == p.id;

            return InkWell(
              onTap: () => _controller.setPreset(p),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 118,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: p.bgGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.amber : p.borderColor.withOpacity(0.4),
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.palette_rounded,
                      color: isSelected ? Colors.amber : p.accentColor,
                      size: 20,
                    ),
                    Column(
                      children: [
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: p.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: p.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFramesTab(AppColorsExtension colors) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Obx(() {
        final current = _controller.selectedFrame.value;

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: CardIslamicFrameStyle.values.map((f) {
            final isSel = current == f;
            return InkWell(
              onTap: () => _controller.setFrame(f),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSel ? colors.primary.withOpacity(0.12) : colors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? colors.primary : colors.divider,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSel ? Icons.check_circle_rounded : Icons.crop_free_rounded,
                          size: 15,
                          color: isSel ? colors.primary : colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                            color: isSel ? colors.primary : colors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildTypographyTab(AppColorsExtension colors) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Obx(() {
        final currentFont = _controller.selectedFont.value;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Font picker
              const Text('نوع الخط:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: CardStudioFontFamily.values.map((font) {
                  final isSel = currentFont == font;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSel ? colors.primary.withOpacity(0.12) : null,
                          side: BorderSide(color: isSel ? colors.primary : colors.divider),
                        ),
                        onPressed: () => _controller.setFont(font),
                        child: Text(
                          font.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? colors.primary : colors.text,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Font Size Slider
              Row(
                children: [
                  const Text('حجم الخط:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: _controller.fontSize.value,
                      min: 16.0,
                      max: 34.0,
                      divisions: 9,
                      activeColor: colors.primary,
                      onChanged: (val) => _controller.fontSize.value = val,
                    ),
                  ),
                  Text('${_controller.fontSize.value.toInt()}', style: const TextStyle(fontSize: 12)),
                ],
              ),
              const Divider(height: 10),

              // Switches
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('إظهار البسملة الشريفة أعلى البطاقة', style: TextStyle(fontSize: 12)),
                value: _controller.showBismillah.value,
                onChanged: (v) => _controller.showBismillah.value = v,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('إظهار الأقواس القرآنية ﴿ ﴾', style: TextStyle(fontSize: 12)),
                value: _controller.showBrackets.value,
                onChanged: (v) => _controller.showBrackets.value = v,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('إظهار اسم التطبيق أسفل البطاقة', style: TextStyle(fontSize: 12)),
                value: _controller.showWatermark.value,
                onChanged: (v) => _controller.showWatermark.value = v,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(AppColorsExtension colors) {
    return Obx(() {
      final isExporting = _controller.isExporting.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Share Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                elevation: 2,
              ),
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
              label: Text(
                isExporting ? 'جارٍ توليد الصورة فائقة الدقة...' : 'مشاركة كصورة الآن (Story / Status)',
                style: const TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: isExporting ? null : () => _controller.exportAndShare(context, _cardKey),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Save Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'حفظ الصورة بجودة فائقة في الهاتف',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: isExporting ? null : () => _controller.saveToDevice(context, _cardKey),
          ),
        ],
      );
    });
  }
}
