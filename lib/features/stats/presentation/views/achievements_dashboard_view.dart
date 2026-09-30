import 'package:flutter/material.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';

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

    if (mounted) {
      setState(() {
        _readingStats = stats;
        _wirdPlan = plan;
        _unlockedBadges = badges;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final totalPages = _readingStats['totalPages'] ?? 0;
    final totalDays = _readingStats['totalDays'] ?? 0;
    final currentStreak = _wirdPlan?.streak ?? 0;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('الإحصائيات والإنجازات'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, const Color(0xFF14453A)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: AppRadius.borderLg,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'صحبتك مع كتاب الله',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTypography.decorativeFont,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'خطوات مباركة ومستمرة تقربك من الله تعالى يوماً بعد يوم.',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                        AppSpacing.verticalLg,
                        Row(
                          children: [
                            _buildHeroStat('صفحة مقروءة', '$totalPages', Icons.menu_book_rounded),
                            const SizedBox(width: 12),
                            _buildHeroStat('أيام متتالية', '$currentStreak', Icons.local_fire_department_rounded),
                            const SizedBox(width: 12),
                            _buildHeroStat('إجمالي الأيام', '$totalDays', Icons.calendar_month_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalXl,

                  // Badges Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'شارات التقدير والإنجاز',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_unlockedBadges.length} من ${AchievementBadge.all.length} شارة',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'شارات تشجيعية بسيطة لتوثيق مسيرتك بدون أي ضغط',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  AppSpacing.verticalLg,

                  // Badges Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: AchievementBadge.all.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final badge = AchievementBadge.all[index];
                      final isUnlocked = _unlockedBadges.contains(badge.id);

                      return AppCard(
                        variant: isUnlocked ? AppCardVariant.elevated : AppCardVariant.flat,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUnlocked ? badge.color.withOpacity(0.15) : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                badge.icon,
                                color: isUnlocked ? badge.color : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isUnlocked ? colors.text : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              badge.description,
                              style: TextStyle(
                                fontSize: 10,
                                color: isUnlocked ? colors.textMuted : Colors.grey.shade400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroStat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
