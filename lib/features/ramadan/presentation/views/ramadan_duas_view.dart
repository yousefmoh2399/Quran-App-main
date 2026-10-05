import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/responsive.dart';
import '../../data/ramadan_service.dart';

class RamadanDuasView extends StatefulWidget {
  const RamadanDuasView({super.key});

  @override
  State<RamadanDuasView> createState() => _RamadanDuasViewState();
}

class _RamadanDuasViewState extends State<RamadanDuasView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RamadanService _service = RamadanService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyDua(String text) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ الدعاء إلى الحافظة بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF09261E),
      colorText: const Color(0xFFD4AF37),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('أدعية رمضان المبارك'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'أدعية الأيام الـ 30'),
            Tab(text: 'العشر الأواخر وليلة القدر'),
            Tab(text: 'دعاء القنوت والوتر'),
            Tab(text: 'أذكار الصائم وسننه'),
          ],
        ),
      ),
      body: MaxWidthContainer(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDuasList(_service.getDuasByCategory('daily')),
            _buildDuasList(_service.getDuasByCategory('last_ten')),
            _buildDuasList(_service.getDuasByCategory('qunut')),
            _buildDuasList(_service.getDuasByCategory('fasting_sunnah')),
          ],
        ),
      ),
    );
  }

  Widget _buildDuasList(List<RamadanDuaItem> list) {
    final colors = context.appColors;

    if (list.isEmpty) {
      return const Center(child: Text('لا توجد أدعية'));
    }

    return ListView.builder(
      padding: AppSpacing.paddingLg,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: colors.primary.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF09261E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                      tooltip: 'نسخ الدعاء',
                      onPressed: () => _copyDua(item.arabicText),
                    ),
                  ],
                ),
              ),

              // Body Arabic Text
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  item.arabicText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                    height: 1.8,
                  ),
                ),
              ),

              // Reference / Virtue footer
              if (item.virtureOrReference != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_outline_rounded, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.virtureOrReference!,
                          style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
