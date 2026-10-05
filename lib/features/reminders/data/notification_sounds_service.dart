import 'package:flutter/material.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';

class SoundOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const SoundOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class NotificationSoundsSettings {
  String mode; // 'custom', 'unified', 'default'
  String unifiedSound;
  String wirdSound;
  String commuteSound;
  String sadaqahSound;
  String azkarSound;

  NotificationSoundsSettings({
    this.mode = 'custom',
    this.unifiedSound = 'fazakkir',
    this.wirdSound = 'fazakkir',
    this.commuteSound = 'fazakkir',
    this.sadaqahSound = 'azkar_2',
    this.azkarSound = 'azkar_1',
  });

  Map<String, String> toMap() {
    return {
      'mode': mode,
      'unifiedSound': unifiedSound,
      'wirdSound': wirdSound,
      'commuteSound': commuteSound,
      'sadaqahSound': sadaqahSound,
      'azkarSound': azkarSound,
    };
  }

  factory NotificationSoundsSettings.fromMap(Map<String, String> map) {
    return NotificationSoundsSettings(
      mode: map['mode'] ?? 'custom',
      unifiedSound: map['unifiedSound'] ?? 'fazakkir',
      wirdSound: map['wirdSound'] ?? 'fazakkir',
      commuteSound: map['commuteSound'] ?? 'fazakkir',
      sadaqahSound: map['sadaqahSound'] ?? 'azkar_2',
      azkarSound: map['azkarSound'] ?? 'azkar_1',
    );
  }
}

class NotificationSoundsService {
  NotificationSoundsService._();
  static final NotificationSoundsService instance = NotificationSoundsService._();

  static const List<SoundOption> availableSounds = [
    SoundOption(
      key: 'fazakkir',
      title: 'فذكّر بالقرآن',
      subtitle: 'تلاوة ندية هادئة (مستحسن للورد والتلاوة)',
      icon: Icons.menu_book_rounded,
    ),
    SoundOption(
      key: 'azkar_1',
      title: 'سبحان الله وبحمده',
      subtitle: 'صوت ندي بالتسبيح والأذكار',
      icon: Icons.spa_rounded,
    ),
    SoundOption(
      key: 'azkar_2',
      title: 'الصلاة على النبي ﷺ',
      subtitle: 'تذكير عطر بالصلاة على رسول الله',
      icon: Icons.favorite_rounded,
    ),
    SoundOption(
      key: 'adhan',
      title: 'تكبيرات الأذان',
      subtitle: 'تكبيرات روحانية من الأذان',
      icon: Icons.notifications_active_rounded,
    ),
    SoundOption(
      key: 'system_default',
      title: 'نغمة الهاتف الافتراضية',
      subtitle: 'صوت إشعارات النظام القياسي',
      icon: Icons.smartphone_rounded,
    ),
    SoundOption(
      key: 'silent',
      title: 'صامت (بدون صوت)',
      subtitle: 'إشعار مرئي فقط دون أي رنين',
      icon: Icons.volume_off_rounded,
    ),
  ];

  static SoundOption getOption(String key) {
    return availableSounds.firstWhere(
      (opt) => opt.key == key,
      orElse: () => availableSounds.first,
    );
  }

  Future<NotificationSoundsSettings> loadSettings() async {
    final map = await NativeRemindersBridge.getSoundSettings();
    if (map.isEmpty) {
      return NotificationSoundsSettings();
    }
    return NotificationSoundsSettings.fromMap(map);
  }

  Future<bool> saveSettings(NotificationSoundsSettings settings) async {
    return await NativeRemindersBridge.saveSoundSettings(
      mode: settings.mode,
      unifiedSound: settings.unifiedSound,
      wirdSound: settings.wirdSound,
      commuteSound: settings.commuteSound,
      sadaqahSound: settings.sadaqahSound,
      azkarSound: settings.azkarSound,
    );
  }

  Future<void> previewSound(String soundKey) async {
    await NativeRemindersBridge.previewSound(soundKey);
  }

  Future<void> stopSound() async {
    await NativeRemindersBridge.stopSound();
  }
}
