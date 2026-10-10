import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/spiritual_milestone_model.dart';
import '../controllers/spiritual_milestones_controller.dart';

class SpiritualMilestonesView extends StatefulWidget {
  const SpiritualMilestonesView({super.key});

  @override
  State<SpiritualMilestonesView> createState() => _SpiritualMilestonesViewState();
}

class _SpiritualMilestonesViewState extends State<SpiritualMilestonesView> {
  late final SpiritualMilestonesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SpiritualMilestonesController>()
        ? Get.find<SpiritualMilestonesController>()
        : Get.put(SpiritualMilestonesController());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'ميزان الحسنات وغِراس الجنة',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          return Column(
            children: [
              _buildCelebrationBanner(colors),
              _buildTabSelector(colors),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentTabContent(colors),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCelebrationBanner(dynamic colors) {
    return Obx(() {
      if (!_controller.justPlantedTree.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.park_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'مبارك! أثمرت ألف تسبيحة شجرة جديدة في بستانك الإيماني 🌴',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabSelector(dynamic colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider.withOpacity(0.4)),
      ),
      child: Obx(() {
        final currentTab = _controller.selectedTab.value;
        return Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'بستان الغِراس',
                icon: Icons.park_outlined,
                isSelected: currentTab == 0,
                onTap: () => _controller.setTab(0),
                colors: colors,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                title: 'الميزان التراكمي',
                icon: Icons.bar_chart_rounded,
                isSelected: currentTab == 1,
                onTap: () => _controller.setTab(1),
                colors: colors,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                title: 'أوسمة الإنجاز',
                icon: Icons.military_tech_outlined,
                isSelected: currentTab == 2,
                onTap: () => _controller.setTab(2),
                colors: colors,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(dynamic colors) {
    switch (_controller.selectedTab.value) {
      case 0:
        return _buildGardenTab(colors);
      case 1:
        return _buildLifetimeStatsTab(colors);
      case 2:
        return _buildBadgesTab(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  // TAB 1: Visual Garden & Live Tapping Counter
  Widget _buildGardenTab(dynamic colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Garden Hero Box
          _buildGardenHeroCard(colors),
          const SizedBox(height: 14),

          // 2. Zikr Type Selector Chips
          _buildZikrTypeChips(colors),
          const SizedBox(height: 14),

          // 3. Interactive Counter Box
          _buildActiveCounterCard(colors),
          const SizedBox(height: 14),

          // 4. Prophetic Hadith Box
          _buildHadithBox(colors),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGardenHeroCard(dynamic colors) {
    final trees = _controller.treesCount.value;
    final nextProgress = _controller.nextTreeProgress.value;
    final progressPercent = (nextProgress / 1000.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بستانك الإيماني في الجنة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'كل 1,000 تسبيحة تثمر شجرة مباركة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.park_rounded, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 5),
                    Text(
                      '$trees شجرة',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Forest of Trees (up to 15 mini trees)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    trees > 0 ? (trees > 16 ? 16 : trees) : 1,
                    (i) {
                      if (trees == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'ابدأ الذكر لغرس شجرتك الأولى في بستانك الإيماني 🌱',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const Icon(
                        Icons.park_rounded,
                        color: Color(0xFF2E7D32),
                        size: 26,
                      );
                    },
                  ),
                ),
                if (trees > 16) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+ ${trees - 16} شجرة أخرى مغروسة في ميزانك',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar towards Next Tree
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التقدم نحو الشجرة القادمة:',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '$nextProgress / 1,000 (${(progressPercent * 100).toInt()}%)',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8,
                  backgroundColor: colors.divider.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZikrTypeChips(dynamic colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        final active = _controller.activeZikr.value;
        return Row(
          children: ZikrType.values.map((type) {
            final isSelected = active == type;
            final count = _controller.counts[type] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => _controller.setActiveZikr(type),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.divider.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        size: 14,
                        color: isSelected ? Colors.white : colors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : colors.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($count)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: isSelected ? Colors.white.withOpacity(0.85) : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildActiveCounterCard(dynamic colors) {
    return Obx(() {
      final active = _controller.activeZikr.value;
      final count = _controller.counts[active] ?? 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.divider.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            // Zikr Calligraphy Text
            Text(
              active.zikrText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.quranFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),

            // Virtue description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                active.virtue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Big Circular Interactive Tap Counter
            GestureDetector(
              onTap: () => _controller.incrementZikr(active),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withOpacity(0.08),
                  border: Border.all(color: colors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المجموع التراكمي',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 10.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.touch_app_rounded, size: 16, color: colors.primary.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Quick Batch Add Buttons (+33, +100)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAddButton(
                  title: '+33 تسبيحة',
                  onTap: () => _controller.incrementZikr(active, amount: 33),
                  colors: colors,
                ),
                const SizedBox(width: 12),
                _buildQuickAddButton(
                  title: '+100 تسبيحة',
                  onTap: () => _controller.incrementZikr(active, amount: 100),
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickAddButton({
    required String title,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colors.primary.withOpacity(0.35)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildHadithBox(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFD4AF37)),
              SizedBox(width: 6),
              Text(
                'حديث غراس الجنة الشريف',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'قال رسول الله ﷺ: «لَقِيتُ إِبْرَاهِيمَ لَيْلَةَ أُسْرِيَ بِي فَقَالَ: يَا مُحَمَّدُ، أَقْرِئْ أُمَّتَكَ مِنِّي السَّلَامَ، وَأَخْبِرْهُمْ أَنَّ الْجَنَّةَ طَيِّبَةُ التُّرْبَةِ عَذْبَةُ الْمَاءِ، وَأَنَّهَا قِيعَانٌ، وَأَنَّ غِرَاسَهَا: سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ».',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Lifetime Comprehensive Stats
  Widget _buildLifetimeStatsTab(dynamic colors) {
    final total = _controller.totalLifetimeCount.value;
    final trees = _controller.treesCount.value;
    final badgesCount = _controller.unlockedBadgesCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 3 Key Lifetime Numbers
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'إجمالي الأذكار',
                value: '$total',
                icon: Icons.all_inclusive_rounded,
                color: colors.primary,
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'أشجار مغروسة',
                value: '$trees',
                icon: Icons.park_rounded,
                color: const Color(0xFF2E7D32),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'أوسمة محققة',
                value: '$badgesCount',
                icon: Icons.military_tech_rounded,
                color: const Color(0xFFD4AF37),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'تفاصيل ميزان الأذكار التراكمي:',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 10),

        // Breakdown by Each Zikr Type
        ...ZikrType.values.map((type) {
          final count = _controller.counts[type] ?? 0;
          final percent = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.divider.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: colors.primary.withOpacity(0.12),
                      child: Icon(type.icon, size: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            type.zikrText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: colors.divider.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required dynamic colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 10.5,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Badges & Achievements
  Widget _buildBadgesTab(dynamic colors) {
    final badges = _controller.badges;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final progress = _controller.getBadgeProgress(badge);
        final isUnlocked = _controller.isBadgeUnlocked(badge);
        final progressRatio = (progress / badge.requiredCount).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFFD4AF37).withOpacity(0.6)
                  : colors.divider.withOpacity(0.3),
              width: isUnlocked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? const Color(0xFFD4AF37).withOpacity(0.15)
                      : colors.divider.withOpacity(0.2),
                ),
                child: Icon(
                  badge.icon,
                  size: 22,
                  color: isUnlocked ? const Color(0xFFD4AF37) : colors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text(
                              'مكتمل ✨',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.description,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 5,
                        backgroundColor: colors.divider.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlocked ? const Color(0xFFD4AF37) : colors.primary,
                        ),
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
