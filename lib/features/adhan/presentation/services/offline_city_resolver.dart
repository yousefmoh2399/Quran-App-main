import 'dart:math' as math;

/// Represents a city entry in the offline resolver database.
class OfflineCityEntry {
  final String name;
  final String governorateOrState;
  final String country;
  final double latitude;
  final double longitude;
  final String calculationMethod;
  final String madhab;

  const OfflineCityEntry({
    required this.name,
    required this.governorateOrState,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.calculationMethod = 'EGYPTIAN',
    this.madhab = 'SHAFI',
  });

  bool get isEgypt => country == 'مصر';
  String get displayName => '$name، $country';
}

/// The result returned when resolving GPS coordinates offline.
class OfflineCityResult {
  final String cityName;
  final String country;
  final bool isEgypt;
  final String recommendedMethod;
  final String recommendedMadhab;
  final double distanceKm;
  final OfflineCityEntry nearestCity;

  const OfflineCityResult({
    required this.cityName,
    required this.country,
    required this.isEgypt,
    required this.recommendedMethod,
    required this.recommendedMadhab,
    required this.distanceKm,
    required this.nearestCity,
  });

  String get displayName => '$cityName، $country';
}

/// Resolves latitude/longitude coordinates to the nearest city and governorate offline
/// without requiring internet, external geocoding APIs, or heavy map assets.
/// Takes virtually 0 KB of app size and executes in < 1 ms via the Haversine formula.
class OfflineCityResolver {
  OfflineCityResolver._();

  /// All 27 Egyptian Governorates + key centers
  static const List<OfflineCityEntry> egyptianCities = [
    // 1. القاهرة الكبرى والقناة
    OfflineCityEntry(name: 'القاهرة', governorateOrState: 'القاهرة', country: 'مصر', latitude: 30.0444, longitude: 31.2357),
    OfflineCityEntry(name: 'الجيزة', governorateOrState: 'الجيزة', country: 'مصر', latitude: 30.0131, longitude: 31.2089),
    OfflineCityEntry(name: 'حلوان', governorateOrState: 'القاهرة', country: 'مصر', latitude: 29.8414, longitude: 31.3008),
    OfflineCityEntry(name: '6 أكتوبر', governorateOrState: 'الجيزة', country: 'مصر', latitude: 29.9723, longitude: 30.9419),
    OfflineCityEntry(name: 'القاهرة الجديدة', governorateOrState: 'القاهرة', country: 'مصر', latitude: 30.0074, longitude: 31.4913),
    OfflineCityEntry(name: 'بنها', governorateOrState: 'القليوبية', country: 'مصر', latitude: 30.4667, longitude: 31.1833),
    OfflineCityEntry(name: 'شبرا الخيمة', governorateOrState: 'القليوبية', country: 'مصر', latitude: 30.1286, longitude: 31.2422),

    // 2. الدلتا والوجه البحري
    OfflineCityEntry(name: 'الإسكندرية', governorateOrState: 'الإسكندرية', country: 'مصر', latitude: 31.2001, longitude: 29.9187),
    OfflineCityEntry(name: 'المنصورة', governorateOrState: 'الدقهلية', country: 'مصر', latitude: 31.0409, longitude: 31.3785),
    OfflineCityEntry(name: 'طنطا', governorateOrState: 'الغربية', country: 'مصر', latitude: 30.7865, longitude: 31.0004),
    OfflineCityEntry(name: 'المحلة الكبرى', governorateOrState: 'الغربية', country: 'مصر', latitude: 30.9706, longitude: 31.1669),
    OfflineCityEntry(name: 'الزقازيق', governorateOrState: 'الشرقية', country: 'مصر', latitude: 30.5877, longitude: 31.5020),
    OfflineCityEntry(name: 'شبين الكوم', governorateOrState: 'المنوفية', country: 'مصر', latitude: 30.5526, longitude: 31.0090),
    OfflineCityEntry(name: 'دمنهور', governorateOrState: 'البحيرة', country: 'مصر', latitude: 31.0344, longitude: 30.4682),
    OfflineCityEntry(name: 'كفر الشيخ', governorateOrState: 'كفر الشيخ', country: 'مصر', latitude: 31.1107, longitude: 30.9388),
    OfflineCityEntry(name: 'دمياط', governorateOrState: 'دمياط', country: 'مصر', latitude: 31.4175, longitude: 31.8144),
    OfflineCityEntry(name: 'بورسعيد', governorateOrState: 'بورسعيد', country: 'مصر', latitude: 31.2653, longitude: 32.3019),
    OfflineCityEntry(name: 'الإسماعيلية', governorateOrState: 'الإسماعيلية', country: 'مصر', latitude: 30.5965, longitude: 32.2715),
    OfflineCityEntry(name: 'السويس', governorateOrState: 'السويس', country: 'مصر', latitude: 29.9668, longitude: 32.5498),

    // 3. شمال وجنوب سيناء
    OfflineCityEntry(name: 'العريش', governorateOrState: 'شمال سيناء', country: 'مصر', latitude: 31.1316, longitude: 33.7984),
    OfflineCityEntry(name: 'الطور', governorateOrState: 'جنوب سيناء', country: 'مصر', latitude: 28.2364, longitude: 33.6254),
    OfflineCityEntry(name: 'شرم الشيخ', governorateOrState: 'جنوب سيناء', country: 'مصر', latitude: 27.9158, longitude: 34.3299),
    OfflineCityEntry(name: 'دهب', governorateOrState: 'جنوب سيناء', country: 'مصر', latitude: 28.5097, longitude: 34.5137),

    // 4. شمال الصعيد
    OfflineCityEntry(name: 'الفيوم', governorateOrState: 'الفيوم', country: 'مصر', latitude: 29.3084, longitude: 30.8428),
    OfflineCityEntry(name: 'بني سويف', governorateOrState: 'بني سويف', country: 'مصر', latitude: 29.0661, longitude: 31.0994),
    OfflineCityEntry(name: 'المنيا', governorateOrState: 'المنيا', country: 'مصر', latitude: 28.0871, longitude: 30.7618),

    // 5. وسط وجنوب الصعيد
    OfflineCityEntry(name: 'أسيوط', governorateOrState: 'أسيوط', country: 'مصر', latitude: 27.1783, longitude: 31.1859),
    OfflineCityEntry(name: 'سوهاج', governorateOrState: 'سوهاج', country: 'مصر', latitude: 26.5569, longitude: 31.6948),
    OfflineCityEntry(name: 'قنا', governorateOrState: 'قنا', country: 'مصر', latitude: 26.1551, longitude: 32.7160),
    OfflineCityEntry(name: 'الأقصر', governorateOrState: 'الأقصر', country: 'مصر', latitude: 25.6872, longitude: 32.6396),
    OfflineCityEntry(name: 'أسوان', governorateOrState: 'أسوان', country: 'مصر', latitude: 24.0889, longitude: 32.8998),

    // 6. البحر الأحمر والحدود
    OfflineCityEntry(name: 'الغردقة', governorateOrState: 'البحر الأحمر', country: 'مصر', latitude: 27.2579, longitude: 33.8116),
    OfflineCityEntry(name: 'سفاجا', governorateOrState: 'البحر الأحمر', country: 'مصر', latitude: 26.7292, longitude: 33.9366),
    OfflineCityEntry(name: 'مرسى علم', governorateOrState: 'البحر الأحمر', country: 'مصر', latitude: 25.0676, longitude: 34.8790),
    OfflineCityEntry(name: 'شلاتين', governorateOrState: 'البحر الأحمر', country: 'مصر', latitude: 23.1311, longitude: 35.5847),
    OfflineCityEntry(name: 'مرسى مطروح', governorateOrState: 'مطروح', country: 'مصر', latitude: 31.3543, longitude: 27.2373),
    OfflineCityEntry(name: 'سيوة', governorateOrState: 'مطروح', country: 'مصر', latitude: 29.2032, longitude: 25.5195),
    OfflineCityEntry(name: 'الخارجة', governorateOrState: 'الوادي الجديد', country: 'مصر', latitude: 25.4514, longitude: 30.5471),
    OfflineCityEntry(name: 'الداخلة', governorateOrState: 'الوادي الجديد', country: 'مصر', latitude: 25.5244, longitude: 28.9864),
  ];

  /// Major Arab & Islamic Capitals and Metropolises
  static const List<OfflineCityEntry> internationalCities = [
    OfflineCityEntry(name: 'مكة المكرمة', governorateOrState: 'مكة المكرمة', country: 'السعودية', latitude: 21.3891, longitude: 39.8579, calculationMethod: 'UMM_AL_QURA'),
    OfflineCityEntry(name: 'المدينة المنورة', governorateOrState: 'المدينة المنورة', country: 'السعودية', latitude: 24.5247, longitude: 39.5692, calculationMethod: 'UMM_AL_QURA'),
    OfflineCityEntry(name: 'الرياض', governorateOrState: 'منطقة الرياض', country: 'السعودية', latitude: 24.7136, longitude: 46.6753, calculationMethod: 'UMM_AL_QURA'),
    OfflineCityEntry(name: 'جدة', governorateOrState: 'منطقة مكة', country: 'السعودية', latitude: 21.5433, longitude: 39.1728, calculationMethod: 'UMM_AL_QURA'),
    OfflineCityEntry(name: 'الدمام', governorateOrState: 'المنطقة الشرقية', country: 'السعودية', latitude: 26.4207, longitude: 50.0888, calculationMethod: 'UMM_AL_QURA'),

    OfflineCityEntry(name: 'القدس الشريف', governorateOrState: 'القدس', country: 'فلسطين', latitude: 31.7683, longitude: 35.2137, calculationMethod: 'EGYPTIAN'),
    OfflineCityEntry(name: 'غزة', governorateOrState: 'غزة', country: 'فلسطين', latitude: 31.5017, longitude: 34.4668, calculationMethod: 'EGYPTIAN'),

    OfflineCityEntry(name: 'عمّان', governorateOrState: 'عمّان', country: 'الأردن', latitude: 31.9454, longitude: 35.9284, calculationMethod: 'EGYPTIAN'),
    OfflineCityEntry(name: 'دبي', governorateOrState: 'إمارة دبي', country: 'الإمارات', latitude: 25.2048, longitude: 55.2708, calculationMethod: 'DUBAI'),
    OfflineCityEntry(name: 'أبوظبي', governorateOrState: 'إمارة أبوظبي', country: 'الإمارات', latitude: 24.4539, longitude: 54.3773, calculationMethod: 'DUBAI'),
    OfflineCityEntry(name: 'الشارقة', governorateOrState: 'إمارة الشارقة', country: 'الإمارات', latitude: 25.3463, longitude: 55.4209, calculationMethod: 'DUBAI'),

    OfflineCityEntry(name: 'الكويت', governorateOrState: 'العاصمة', country: 'الكويت', latitude: 29.3759, longitude: 47.9774, calculationMethod: 'KUWAIT'),
    OfflineCityEntry(name: 'الدوحة', governorateOrState: 'الدوحة', country: 'قطر', latitude: 25.2854, longitude: 51.5310, calculationMethod: 'QATAR'),
    OfflineCityEntry(name: 'المنامة', governorateOrState: 'العاصمة', country: 'البحرين', latitude: 26.2285, longitude: 50.5860, calculationMethod: 'UMM_AL_QURA'),
    OfflineCityEntry(name: 'مسقط', governorateOrState: 'محافظة مسقط', country: 'عُمان', latitude: 23.5880, longitude: 58.3829, calculationMethod: 'UMM_AL_QURA'),

    OfflineCityEntry(name: 'بغداد', governorateOrState: 'بغداد', country: 'العراق', latitude: 33.3152, longitude: 44.3661, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'دمشق', governorateOrState: 'دمشق', country: 'سوريا', latitude: 33.5138, longitude: 36.2765, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'بيروت', governorateOrState: 'بيروت', country: 'لبنان', latitude: 33.8938, longitude: 35.5018, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),

    OfflineCityEntry(name: 'طرابلس', governorateOrState: 'طرابلس', country: 'ليبيا', latitude: 32.8872, longitude: 13.1913, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'بنغازي', governorateOrState: 'بنغازي', country: 'ليبيا', latitude: 32.1167, longitude: 20.0667, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'تونس', governorateOrState: 'تونس', country: 'تونس', latitude: 36.8065, longitude: 10.1815, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'الجزائر', governorateOrState: 'الجزائر', country: 'الجزائر', latitude: 36.7538, longitude: 3.0588, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'الرباط', governorateOrState: 'الرباط', country: 'المغرب', latitude: 34.0209, longitude: -6.8416, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'الدار البيضاء', governorateOrState: 'الدار البيضاء', country: 'المغرب', latitude: 33.5731, longitude: -7.5898, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'الخرطوم', governorateOrState: 'الخرطوم', country: 'السودان', latitude: 15.5007, longitude: 32.5599, calculationMethod: 'EGYPTIAN'),
    OfflineCityEntry(name: 'صنعاء', governorateOrState: 'صنعاء', country: 'اليمن', latitude: 15.3694, longitude: 44.1910, calculationMethod: 'UMM_AL_QURA'),

    OfflineCityEntry(name: 'إسطنبول', governorateOrState: 'إسطنبول', country: 'تركيا', latitude: 41.0082, longitude: 28.9784, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'لندن', governorateOrState: 'إنجلترا', country: 'المملكة المتحدة', latitude: 51.5074, longitude: -0.1278, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'باريس', governorateOrState: 'إيل دو فرانس', country: 'فرنسا', latitude: 48.8566, longitude: 2.3522, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'برلين', governorateOrState: 'برلين', country: 'ألمانيا', latitude: 52.5200, longitude: 13.4050, calculationMethod: 'MUSLIM_WORLD_LEAGUE'),
    OfflineCityEntry(name: 'نيويورك', governorateOrState: 'نيويورك', country: 'الولايات المتحدة', latitude: 40.7128, longitude: -74.0060, calculationMethod: 'NORTH_AMERICA'),
  ];

  /// Combined database
  static List<OfflineCityEntry> get allCities => [
    ...egyptianCities,
    ...internationalCities,
  ];

  /// Checks if coordinates fall within Egypt's geographic bounding box
  static bool isInEgyptBoundingBox(double lat, double lng) {
    return lat >= 21.8 && lat <= 31.9 && lng >= 24.6 && lng <= 37.1;
  }

  /// Calculates Haversine distance in kilometers between two geographic coordinates
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Resolves the given [lat] and [lng] to the closest city in the database.
  /// Always returns a valid result.
  static OfflineCityResult resolve(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) {
      // Default to Cairo, Egypt
      final cairo = egyptianCities.first;
      return OfflineCityResult(
        cityName: cairo.name,
        country: cairo.country,
        isEgypt: true,
        recommendedMethod: 'EGYPTIAN',
        recommendedMadhab: 'SHAFI',
        distanceKm: 0.0,
        nearestCity: cairo,
      );
    }

    OfflineCityEntry nearest = allCities.first;
    double minDistance = double.infinity;

    for (final city in allCities) {
      final dist = calculateDistanceKm(lat, lng, city.latitude, city.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = city;
      }
    }

    final inEgyptBox = isInEgyptBoundingBox(lat, lng);
    final isEgypt = nearest.isEgypt || inEgyptBox;

    final recommendedMethod = isEgypt ? 'EGYPTIAN' : nearest.calculationMethod;
    final recommendedMadhab = 'SHAFI'; // Default to Shafi'i / Jumhur everywhere unless user explicitly overrides

    return OfflineCityResult(
      cityName: nearest.name,
      country: nearest.country,
      isEgypt: isEgypt,
      recommendedMethod: recommendedMethod,
      recommendedMadhab: recommendedMadhab,
      distanceKm: minDistance,
      nearestCity: nearest,
    );
  }
}
