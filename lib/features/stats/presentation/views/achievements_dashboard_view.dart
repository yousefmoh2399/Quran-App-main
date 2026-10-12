import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../../../core/util/routes/routes.dart';

class AchievementsDashboardView extends StatefulWidget {
  const AchievementsDashboardView({super.key});

  @override
  State<AchievementsDashboardView> createState() => _AchievementsDashboardViewState();
}

class _AchievementsDashboardViewState extends State<AchievementsDashboardView> {
  final UserRepository _userRepo = UserRepository();
  Map<String, dynamic> _readingStats = {};
  WirdPlan? _wirdPlan;
  Set<String> _unlockedBadges = {};
  bool _isLoading = true;
  int _selectedStageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await _userRepo.evaluateAchievements();
    final stats = await _userRepo.getReadingStats();
    final plan = await _userRepo.getWirdPlan();
    final badges = await _userRepo.getUnlockedAchievements();

    // Determine initial active stage
    int initialStage = 0;
    for (int i = 0; i < AchievementStage.all.length; i++) {
      final stageNum = AchievementStage.all[i].number;
      if (_isStageUnlockedWithBadges(stageNum, badges)) {
        initialStage = i;
      }
    }

    if (mounted) {
      setState(() {
        _readingStats = stats;
        _wirdPlan = plan;
        _unlockedBadges = badges;
        _selectedStageIndex = initialStage;
        _isLoading = false;
      });
    }
  }

  bool _isStageUnlockedWithBadges(int stageNum, Set<String> badges) {
    if (stageNum <= 1) return true;
    final prevStageBadges = AchievementBadge.forStage(stageNum - 1);
    final prevUnlockedCount = prevStageBadges.where((b) => badges.contains(b.id)).length;
    return prevUnlockedCount >= 2;
  }

  bool _isStageUnlocked(int stageNum) {
    return _isStageUnlockedWithBadges(stageNum, _unlockedBadges);
  }

  int _getMissingBadgesForStage(int stageNum) {
    if (stageNum <= 1) return 0;
    final prevStageBadges = AchievementBadge.forStage(stageNum - 1);
    final prevUnlockedCount = prevStageBadges.where((b) => _unlockedBadges.contains(b.id)).length;
    return (2 - prevUnlockedCount).clamp(0, 2);
  }

  String _getUserRankTitle(int count) {
    if (count >= 12) return 'تاج الوقار وأهل القرآن 👑';
    if (count >= 8) return 'صاحب القرآن الكريم 💎';
    if (count >= 4) return 'حامل الورد القرآني 🌟';
    return 'غارس بذرة النور 🌿';
  }

  int _getUserLevel(int count) {
    if (count >= 12) return 4;
    if (count >= 8) return 3;
    if (count >= 4) return 2;
    return 1;
  }

  (double progress, int currentVal) _getBadgeProgress(
    AchievementBadge badge,
    int totalPages,
    int effectiveStreak,
  ) {
    if (_unlockedBadges.contains(badge.id)) {
      return (1.0, badge.targetValue);
    }
    int current = 0;
    switch (badge.metricType) {
      case 'pages':
        current = totalPages;
        break;
      case 'streak':
        current = effectiveStreak;
        break;
      case 'khatma':
        current = totalPages;
        break;
      default:
        current = 0;
    }
    final target = badge.targetValue > 0 ? badge.targetValue : 1;
    final clampedProgress = (current / target).clamp(0.0, 1.0);
    return (clampedProgress, current.clamp(0, target));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final totalPages = _readingStats['totalPages'] ?? 0;
    final totalDays = _readingStats['totalDays'] ?? 0;
    final streak = _readingStats['streak'] ?? 0;
    final planStreak = _wirdPlan?.streak ?? 0;
    final currentStreak = streak > planStreak ? streak : planStreak;
    final effectiveStreak = currentStreak > totalDays ? currentStreak : totalDays;

    final unlockedCount = _unlockedBadges.length;
    final totalBadges = AchievementBadge.all.length;
    final overallProgress = totalBadges > 0 ? (unlockedCount / totalBadges) : 0.0;
    final userRank = _getUserRankTitle(unlockedCount);
    final userLevel = _getUserLevel(unlockedCount);

    final currentStage = AchievementStage.all[_selectedStageIndex.clamp(0, AchievementStage.all.length - 1)];
    final stageBadges = AchievementBadge.forStage(currentStage.number);
    final stageUnlocked = _isStageUnlocked(currentStage.number);
    final stageUnlockedCount = stageBadges.where((b) => _unlockedBadges.contains(b.id)).length;
    final isStageFullyCompleted = stageBadges.isNotEmpty && stageUnlockedCount == stageBadges.length;

    return AppScaffold(
      title: 'الإحصائيات والأوسمة القرآنية',
      constrainContentWidth: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Journey Banner with 3D Icon & Real-time Level
                  _buildHeroBanner(
                    context: context,
                    colors: colors,
                    userLevel: userLevel,
                    userRank: userRank,
                    unlockedCount: unlockedCount,
                    totalBadges: totalBadges,
                    overallProgress: overallProgress,
                    totalPages: totalPages,
                    currentStreak: currentStreak,
                    totalDays: totalDays,
                  ),
                  AppSpacing.verticalLg,

                  // 2. Stage Roadmap Selector (Pills)
                  _buildStageSelector(colors),
                  AppSpacing.verticalMd,

                  // 3. Stage Details Header Card
                  _buildStageHeaderCard(
                    colors: colors,
                    stage: currentStage,
                    stageUnlocked: stageUnlocked,
                    stageUnlockedCount: stageUnlockedCount,
                    totalStageBadges: stageBadges.length,
                    isFullyCompleted: isStageFullyCompleted,
                  ),
                  AppSpacing.verticalMd,

                  // 4. Badges Grid
                  _buildBadgesGrid(
                    context: context,
                    colors: colors,
                    stageBadges: stageBadges,
                    stageUnlocked: stageUnlocked,
                    totalPages: totalPages,
                    effectiveStreak: effectiveStreak,
                  ),
                  AppSpacing.verticalXl,
                ],
              ),
            ),
    );
  }

  // ==========================================
  // HERO BANNER
  // ==========================================
  Widget _buildHeroBanner({
    required BuildContext context,
    required AppColorsExtension colors,
    required int userLevel,
    required String userRank,
    required int unlockedCount,
    required int totalBadges,
    required double overallProgress,
    required int totalPages,
    required int currentStreak,
    required int totalDays,
  }) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            const Color(0xFF063328),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with 3D Icon and Rank Pill
          Row(
            children: [
              // 3D Medals Avatar
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/icon_3d_khatma_circles.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.military_tech_rounded,
                    color: Colors.amber,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'المستوى $userLevel • $userRank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.uiFont,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'مسيرتك المباركة في صحبة القرآن',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.uiFont,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Overall Progress Meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم الإجمالي: $unlockedCount من $totalBadges أوسمة',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTypography.uiFont,
                ),
              ),
              Text(
                '${(overallProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.uiFont,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
              minHeight: 7,
            ),
          ),
          AppSpacing.verticalMd,

          // 3 Hero Stat Tiles (3D icons)
          Row(
            children: [
              _buildHeroStatTile(
                title: 'صفحة مقروءة',
                value: '$totalPages',
                imageAsset: 'assets/images/icon_3d_quran.png',
                fallbackIcon: Icons.menu_book_rounded,
              ),
              const SizedBox(width: 8),
              _buildHeroStatTile(
                title: 'أيام متتالية',
                value: '$currentStreak',
                imageAsset: 'assets/images/icon_3d_prayer_clock.png',
                fallbackIcon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(width: 8),
              _buildHeroStatTile(
                title: 'إجمالي الأيام',
                value: '$totalDays',
                imageAsset: 'assets/images/icon_3d_calendar.png',
                fallbackIcon: Icons.calendar_month_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatTile({
    required String title,
    required String value,
    required String imageAsset,
    required IconData fallbackIcon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              imageAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                fallbackIcon,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: AppTypography.uiFont,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 9.5,
                fontFamily: AppTypography.uiFont,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STAGE ROADMAP SELECTOR
  // ==========================================
  Widget _buildStageSelector(AppColorsExtension colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(AchievementStage.all.length, (index) {
          final stage = AchievementStage.all[index];
          final isSelected = _selectedStageIndex == index;
          final isUnlocked = _isStageUnlocked(stage.number);
          final badgesInStage = AchievementBadge.forStage(stage.number);
          final completedInStage = badgesInStage.where((b) => _unlockedBadges.contains(b.id)).length;
          final isStageDone = badgesInStage.isNotEmpty && completedInStage == badgesInStage.length;

          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isUnlocked) {
                    setState(() => _selectedStageIndex = index);
                  } else {
                    _showLockedStageInfo(stage);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? stage.themeColor.withOpacity(colors.isDark ? 0.22 : 0.12)
                        : (colors.isDark ? colors.surface : colors.bg),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? stage.themeColor
                          : (isUnlocked
                              ? colors.divider
                              : Colors.grey.withOpacity(0.3)),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: stage.themeColor.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStageDone
                            ? Icons.check_circle_rounded
                            : (isUnlocked ? stage.icon : Icons.lock_rounded),
                        size: 16,
                        color: isSelected
                            ? stage.themeColor
                            : (isUnlocked
                                ? (isStageDone ? Colors.green : colors.textMuted)
                                : Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'مرحلة ${stage.number}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? colors.text
                              : (isUnlocked ? colors.textMuted : Colors.grey),
                          fontFamily: AppTypography.uiFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // STAGE HEADER DETAILS CARD
  // ==========================================
  Widget _buildStageHeaderCard({
    required AppColorsExtension colors,
    required AchievementStage stage,
    required bool stageUnlocked,
    required int stageUnlockedCount,
    required int totalStageBadges,
    required bool isFullyCompleted,
  }) {
    final stageProgress = totalStageBadges > 0 ? (stageUnlockedCount / totalStageBadges) : 0.0;

    return AppCard(
      variant: AppCardVariant.flat,
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stage.themeColor.withOpacity(0.25),
                      stage.themeColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stage.themeColor.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  stageUnlocked ? stage.icon : Icons.lock_rounded,
                  color: stageUnlocked ? stage.themeColor : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Stage badge status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFullyCompleted
                      ? Colors.green.withOpacity(0.12)
                      : (stageUnlocked
                          ? stage.themeColor.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isFullyCompleted
                      ? 'مكتملة ✓'
                      : (stageUnlocked
                          ? '$stageUnlockedCount من $totalStageBadges'
                          : 'مغلقة 🔒'),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFullyCompleted
                        ? Colors.green
                        : (stageUnlocked ? stage.themeColor : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stage progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stageProgress.clamp(0.0, 1.0),
              backgroundColor: stage.themeColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyCompleted ? Colors.green : stage.themeColor,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),

          // Quote / Hadith for this stage
          Text(
            stage.quote,
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 11.5,
              color: stage.themeColor.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BADGES GRID
  // ==========================================
  Widget _buildBadgesGrid({
    required BuildContext context,
    required AppColorsExtension colors,
    required List<AchievementBadge> stageBadges,
    required bool stageUnlocked,
    required int totalPages,
    required int effectiveStreak,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 840
            ? 4
            : (width > 560 ? 3 : 2);
        // Generous child aspect ratio to completely eliminate text overflow
        final double aspectRatio = width < 360 ? 0.84 : (width > 560 ? 1.05 : 0.92);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stageBadges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final badge = stageBadges[index];
            final isBadgeUnlocked = _unlockedBadges.contains(badge.id);
            final (progress, currentVal) = _getBadgeProgress(badge, totalPages, effectiveStreak);

            return _buildBadgeTile(
              context: context,
              colors: colors,
              badge: badge,
              isBadgeUnlocked: isBadgeUnlocked,
              stageUnlocked: stageUnlocked,
              progress: progress,
              currentVal: currentVal,
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeTile({
    required BuildContext context,
    required AppColorsExtension colors,
    required AchievementBadge badge,
    required bool isBadgeUnlocked,
    required bool stageUnlocked,
    required double progress,
    required int currentVal,
  }) {
    final effectiveColor = isBadgeUnlocked
        ? badge.color
        : (stageUnlocked ? badge.color.withOpacity(0.6) : Colors.grey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBadgeDetailModal(
          badge: badge,
          isUnlocked: isBadgeUnlocked,
          stageUnlocked: stageUnlocked,
          progress: progress,
          currentVal: currentVal,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isBadgeUnlocked
                ? badge.color.withOpacity(colors.isDark ? 0.16 : 0.08)
                : (colors.isDark ? colors.surface : colors.bg),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBadgeUnlocked
                  ? badge.color.withOpacity(colors.isDark ? 0.45 : 0.35)
                  : colors.divider.withOpacity(colors.isDark ? 0.4 : 0.6),
              width: isBadgeUnlocked ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (isBadgeUnlocked)
                BoxShadow(
                  color: badge.color.withOpacity(colors.isDark ? 0.22 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D Clay Icon Badge Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      effectiveColor.withOpacity(isBadgeUnlocked ? 0.28 : 0.12),
                      effectiveColor.withOpacity(isBadgeUnlocked ? 0.10 : 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: effectiveColor.withOpacity(isBadgeUnlocked ? 0.45 : 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(isBadgeUnlocked ? 0.25 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    stageUnlocked ? badge.icon : Icons.lock_rounded,
                    color: isBadgeUnlocked
                        ? badge.color
                        : (stageUnlocked ? colors.textMuted : Colors.grey),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                stageUnlocked ? badge.title : 'شارة مقفلة',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isBadgeUnlocked ? colors.text : colors.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Description
              Text(
                stageUnlocked
                    ? badge.description
                    : 'تُفتح عند بلوغ هذه المرحلة',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 10,
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Status indicator / Progress
              if (isBadgeUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 10, color: Colors.green),
                      SizedBox(width: 3),
                      Text(
                        'تم الفتح',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontFamily: AppTypography.uiFont,
                        ),
                      ),
                    ],
                  ),
                )
              else if (stageUnlocked && badge.targetValue > 1) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currentVal / ${badge.targetValue}',
                  style: TextStyle(
                    fontSize: 9,
                    color: colors.textMuted,
                    fontFamily: AppTypography.uiFont,
                  ),
                ),
              ] else
                Text(
                  stageUnlocked ? 'قيد السعي' : 'مغلق',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: colors.textMuted,
                    fontFamily: AppTypography.uiFont,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BADGE DETAIL MODAL (BOTTOM SHEET)
  // ==========================================
  void _showBadgeDetailModal({
    required AchievementBadge badge,
    required bool isUnlocked,
    required bool stageUnlocked,
    required double progress,
    required int currentVal,
  }) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Large 3D Badge icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    badge.color.withOpacity(isUnlocked ? 0.35 : 0.15),
                    badge.color.withOpacity(isUnlocked ? 0.12 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: badge.color.withOpacity(isUnlocked ? 0.5 : 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badge.color.withOpacity(isUnlocked ? 0.3 : 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  stageUnlocked ? badge.icon : Icons.lock_rounded,
                  size: 34,
                  color: isUnlocked ? badge.color : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              badge.title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),

            // Stage Label
            Text(
              'المرحلة ${badge.stage} • ${AchievementStage.all[badge.stage - 1].title}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                color: badge.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Meaning / Spiritual Reflection
            if (badge.meaning.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badge.color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: badge.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        badge.meaning,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Progress / Status Box
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'تم إنجاز هذا الوسام المبارك بنجاح',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else if (stageUnlocked && badge.targetValue > 1) ...[
              Text(
                'التقدم الحالي: $currentVal من ${badge.targetValue}',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: colors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  minHeight: 8,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (isUnlocked) {
                        Share.share(
                          'أكرمني الله بنيل وسام «${badge.title}» في مسيرتي القرآنية المباركة مع تطبيق تقرب! 🌿📖\n«${badge.meaning}»',
                        );
                      } else {
                        Get.toNamed(AppRoutes.mushaf);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isUnlocked ? 'مشاركة الوسام' : 'فتح المصحف للبدء'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedStageInfo(AchievementStage stage) {
    final colors = context.appColors;
    final missing = _getMissingBadgesForStage(stage.number);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'المرحلة مغلقة 🔒',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stage.title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: stage.themeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أكمل $missing وسام إضافي من المرحلة السابقة لفتح هذه المرحلة وتظهر أوسمتها وتحدياتها الجديدة بإذن الله.',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: stage.themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('فهمت ذلك'),
          ),
        ],
      ),
    );
  }
}
