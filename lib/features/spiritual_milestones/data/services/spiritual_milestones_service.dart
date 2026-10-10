import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spiritual_milestone_model.dart';

class SpiritualMilestonesService {
  SpiritualMilestonesService._();
  static final SpiritualMilestonesService instance = SpiritualMilestonesService._();

  static const String _keyPrefix = 'spiritual_milestone_zikr_';
  final Map<ZikrType, int> _cachedCounts = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    for (final type in ZikrType.values) {
      final key = '$_keyPrefix${type.id}';
      _cachedCounts[type] = prefs.getInt(key) ?? 0;
    }
    _isInitialized = true;
  }

  int getCount(ZikrType type) {
    return _cachedCounts[type] ?? 0;
  }

  int getTotalCount() {
    int total = 0;
    for (final count in _cachedCounts.values) {
      total += count;
    }
    return total;
  }

  int getTreesPlanted() {
    return getTotalCount() ~/ 1000;
  }

  int getNextTreeProgress() {
    return getTotalCount() % 1000;
  }

  SpiritualGardenSummary getSummary() {
    final total = getTotalCount();
    return SpiritualGardenSummary(
      totalCount: total,
      treesCount: total ~/ 1000,
      nextTreeProgress: total % 1000,
      counts: Map.unmodifiable(_cachedCounts),
    );
  }

  Future<void> addCount(ZikrType type, int amount) async {
    if (amount <= 0) return;
    await init();
    final current = getCount(type);
    final updated = current + amount;
    _cachedCounts[type] = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix${type.id}', updated);
  }

  Future<void> resetAll() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    for (final type in ZikrType.values) {
      _cachedCounts[type] = 0;
      await prefs.remove('$_keyPrefix${type.id}');
    }
  }

  List<SpiritualBadge> getAllBadges() {
    return const [
      SpiritualBadge(
        id: 'tree_1',
        title: 'غارس الجنة',
        description: 'غرس أول شجرة مباركة في بستانك الإيماني (1,000 ذكر)',
        requiredCount: 1000,
        icon: Icons.park_rounded,
      ),
      SpiritualBadge(
        id: 'tree_5',
        title: 'بستان الذاكرين',
        description: 'غرس 5 أشجار إيمانية في ميزان حسناتك (5,000 ذكر)',
        requiredCount: 5000,
        icon: Icons.forest_rounded,
      ),
      SpiritualBadge(
        id: 'tree_10',
        title: 'واحة الصالحين',
        description: 'غرس 10 أشجار إيمانية مباركة (10,000 ذكر)',
        requiredCount: 10000,
        icon: Icons.nature_people_rounded,
      ),
      SpiritualBadge(
        id: 'tree_50',
        title: 'غابة الفردوس',
        description: 'غرس 50 شجرة وثمرة في ميزانك الإيماني (50,000 ذكر)',
        requiredCount: 50000,
        icon: Icons.yard_rounded,
      ),
      SpiritualBadge(
        id: 'tree_100',
        title: 'روضة الخلد',
        description: 'غرس 100 شجرة في الجنة (100,000 ذكر)',
        requiredCount: 100000,
        icon: Icons.auto_awesome_rounded,
      ),
      SpiritualBadge(
        id: 'salawat_1k',
        title: 'المحب المصلي',
        description: '1,000 صلاة وسلام على النبي المصطفى ﷺ',
        requiredCount: 1000,
        specificType: ZikrType.salawat,
        icon: Icons.star_rounded,
      ),
      SpiritualBadge(
        id: 'salawat_10k',
        title: 'رفيق المصطفى ﷺ',
        description: '10,000 صلاة على النبي ﷺ ترفعك درجات وقرباً',
        requiredCount: 10000,
        specificType: ZikrType.salawat,
        icon: Icons.military_tech_rounded,
      ),
      SpiritualBadge(
        id: 'istighfar_1k',
        title: 'المستغفر بالأسحار',
        description: '1,000 استغفار تمحو الذنوب وتفتح أبواب الرزق',
        requiredCount: 1000,
        specificType: ZikrType.istighfar,
        icon: Icons.water_drop_rounded,
      ),
      SpiritualBadge(
        id: 'istighfar_10k',
        title: 'التواب الأواب',
        description: '10,000 استغفار تطهر القلب وتجلب سكينة الروح',
        requiredCount: 10000,
        specificType: ZikrType.istighfar,
        icon: Icons.favorite_rounded,
      ),
      SpiritualBadge(
        id: 'hawqalah_1k',
        title: 'صاحب الكنز',
        description: '1,000 حوقلة من كنوز الجنة ودواء للهموم',
        requiredCount: 1000,
        specificType: ZikrType.hawqalah,
        icon: Icons.shield_rounded,
      ),
      SpiritualBadge(
        id: 'tahlil_1k',
        title: 'أهل التوحيد',
        description: '1,000 تهليلة (لا إله إلا الله) أفضل الذكر',
        requiredCount: 1000,
        specificType: ZikrType.tahlil,
        icon: Icons.wb_sunny_rounded,
      ),
    ];
  }
}
