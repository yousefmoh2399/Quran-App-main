class AdhanSettingsModel {
  final double latitude;
  final double longitude;
  final String cityName;
  final String calculationMethod;
  final String madhab;
  final String highLatitudeRule;
  final String timeZoneId;

  // Offsets in minutes (-30 to +30)
  final int fajrOffset;
  final int sunriseOffset;
  final int dhuhrOffset;
  final int asrOffset;
  final int maghribOffset;
  final int ishaOffset;

  // Enabled toggles
  final bool fajrEnabled;
  final bool dhuhrEnabled;
  final bool asrEnabled;
  final bool maghribEnabled;
  final bool ishaEnabled;

  // Notification modes: 'adhan', 'notification_only', 'silent'
  final String fajrMode;
  final String dhuhrMode;
  final String asrMode;
  final String maghribMode;
  final String ishaMode;

  // Audio choice
  final String adhanSound;

  // Post-Adhan Du'a by Sheikh Al-Shaarawy
  final bool playPostAdhanDua;

  const AdhanSettingsModel({
    required this.latitude,
    required this.longitude,
    this.cityName = '',
    this.calculationMethod = 'EGYPTIAN',
    this.madhab = 'SHAFI',
    this.highLatitudeRule = 'MIDDLE_OF_THE_NIGHT',
    this.timeZoneId = '',
    this.fajrOffset = 0,
    this.sunriseOffset = 0,
    this.dhuhrOffset = 0,
    this.asrOffset = 0,
    this.maghribOffset = 0,
    this.ishaOffset = 0,
    this.fajrEnabled = true,
    this.dhuhrEnabled = true,
    this.asrEnabled = true,
    this.maghribEnabled = true,
    this.ishaEnabled = true,
    this.fajrMode = 'adhan',
    this.dhuhrMode = 'adhan',
    this.asrMode = 'adhan',
    this.maghribMode = 'adhan',
    this.ishaMode = 'adhan',
    this.adhanSound = 'default',
    this.playPostAdhanDua = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'highLatitudeRule': highLatitudeRule,
      'timeZoneId': timeZoneId,
      'fajrOffset': fajrOffset,
      'sunriseOffset': sunriseOffset,
      'dhuhrOffset': dhuhrOffset,
      'asrOffset': asrOffset,
      'maghribOffset': maghribOffset,
      'ishaOffset': ishaOffset,
      'fajrEnabled': fajrEnabled,
      'dhuhrEnabled': dhuhrEnabled,
      'asrEnabled': asrEnabled,
      'maghribEnabled': maghribEnabled,
      'ishaEnabled': ishaEnabled,
      'fajrMode': fajrMode,
      'dhuhrMode': dhuhrMode,
      'asrMode': asrMode,
      'maghribMode': maghribMode,
      'ishaMode': ishaMode,
      'adhanSound': adhanSound,
      'playPostAdhanDua': playPostAdhanDua,
    };
  }

  factory AdhanSettingsModel.fromMap(Map<String, dynamic> map) {
    return AdhanSettingsModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      cityName: map['cityName'] as String? ?? '',
      calculationMethod: map['calculationMethod'] as String? ?? 'EGYPTIAN',
      madhab: map['madhab'] as String? ?? 'SHAFI',
      highLatitudeRule: map['highLatitudeRule'] as String? ?? 'MIDDLE_OF_THE_NIGHT',
      timeZoneId: map['timeZoneId'] as String? ?? '',
      fajrOffset: (map['fajrOffset'] as num?)?.toInt() ?? 0,
      sunriseOffset: (map['sunriseOffset'] as num?)?.toInt() ?? 0,
      dhuhrOffset: (map['dhuhrOffset'] as num?)?.toInt() ?? 0,
      asrOffset: (map['asrOffset'] as num?)?.toInt() ?? 0,
      maghribOffset: (map['maghribOffset'] as num?)?.toInt() ?? 0,
      ishaOffset: (map['ishaOffset'] as num?)?.toInt() ?? 0,
      fajrEnabled: map['fajrEnabled'] as bool? ?? true,
      dhuhrEnabled: map['dhuhrEnabled'] as bool? ?? true,
      asrEnabled: map['asrEnabled'] as bool? ?? true,
      maghribEnabled: map['maghribEnabled'] as bool? ?? true,
      ishaEnabled: map['ishaEnabled'] as bool? ?? true,
      fajrMode: map['fajrMode'] as String? ?? 'adhan',
      dhuhrMode: map['dhuhrMode'] as String? ?? 'adhan',
      asrMode: map['asrMode'] as String? ?? 'adhan',
      maghribMode: map['maghribMode'] as String? ?? 'adhan',
      ishaMode: map['ishaMode'] as String? ?? 'adhan',
      adhanSound: map['adhanSound'] as String? ?? 'default',
      playPostAdhanDua: map['playPostAdhanDua'] as bool? ?? true,
    );
  }

  AdhanSettingsModel copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? calculationMethod,
    String? madhab,
    String? highLatitudeRule,
    String? timeZoneId,
    int? fajrOffset,
    int? sunriseOffset,
    int? dhuhrOffset,
    int? asrOffset,
    int? maghribOffset,
    int? ishaOffset,
    bool? fajrEnabled,
    bool? dhuhrEnabled,
    bool? asrEnabled,
    bool? maghribEnabled,
    bool? ishaEnabled,
    String? fajrMode,
    String? dhuhrMode,
    String? asrMode,
    String? maghribMode,
    String? ishaMode,
    String? adhanSound,
    bool? playPostAdhanDua,
  }) {
    return AdhanSettingsModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      fajrOffset: fajrOffset ?? this.fajrOffset,
      sunriseOffset: sunriseOffset ?? this.sunriseOffset,
      dhuhrOffset: dhuhrOffset ?? this.dhuhrOffset,
      asrOffset: asrOffset ?? this.asrOffset,
      maghribOffset: maghribOffset ?? this.maghribOffset,
      ishaOffset: ishaOffset ?? this.ishaOffset,
      fajrEnabled: fajrEnabled ?? this.fajrEnabled,
      dhuhrEnabled: dhuhrEnabled ?? this.dhuhrEnabled,
      asrEnabled: asrEnabled ?? this.asrEnabled,
      maghribEnabled: maghribEnabled ?? this.maghribEnabled,
      ishaEnabled: ishaEnabled ?? this.ishaEnabled,
      fajrMode: fajrMode ?? this.fajrMode,
      dhuhrMode: dhuhrMode ?? this.dhuhrMode,
      asrMode: asrMode ?? this.asrMode,
      maghribMode: maghribMode ?? this.maghribMode,
      ishaMode: ishaMode ?? this.ishaMode,
      adhanSound: adhanSound ?? this.adhanSound,
      playPostAdhanDua: playPostAdhanDua ?? this.playPostAdhanDua,
    );
  }
}
