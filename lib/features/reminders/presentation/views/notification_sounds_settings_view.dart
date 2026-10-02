import 'package:flutter/material.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/reminders/data/notification_sounds_service.dart';

class NotificationSoundsSettingsView extends StatefulWidget {
  const NotificationSoundsSettingsView({super.key});

  @override
  State<NotificationSoundsSettingsView> createState() =>
      _NotificationSoundsSettingsViewState();
}

class _NotificationSoundsSettingsViewState
    extends State<NotificationSoundsSettingsView> {
  final NotificationSoundsService _service = NotificationSoundsService.instance;
  NotificationSoundsSettings _settings = NotificationSoundsSettings();
  bool _isLoading = true;
  String? _currentlyPlayingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.stopSound();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.loadSettings();
    if (mounted) {
      setState(() {
        _settings = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final success = await _service.saveSettings(_settings);
    if (success && mounted) {
      AppSnackbar.show(
        'تم الحفظ',
        'تم حفظ نغمات التنبيهات وتحديث قنوات النظام بنجاح',
        context: context,
      );
    }
  }

  Future<void> _togglePreview(String soundKey) async {
    if (_currentlyPlayingKey == soundKey) {
      await _service.stopSound();
      setState(() => _currentlyPlayingKey = null);
    } else {
      setState(() => _currentlyPlayingKey = soundKey);
      await _service.previewSound(soundKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أصوات ونغمات التنبيهات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Intro Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF14382D), const Color(0xFF0F2B22)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.music_note_rounded,
                            size: 28, color: primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تخصيص رنين الإشعارات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'يمكنك تعيين صوت موحد لكل التنبيهات أو اختيار نغمة روحانية خاصة بكل عبادة (الورد، الأذكار، الصدقة).',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mode Selector Segment
                Text(
                  'نمط تشغيل الأصوات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildModeTile(
                  title: 'تخصيص نغمة لكل تذكير',
                  subtitle: 'صوت مختلف للورد اليومي والمواصلات والأذكار والصدقة',
                  modeKey: 'custom',
                  icon: Icons.tune_rounded,
                ),
                _buildModeTile(
                  title: 'نفس النغمة لجميع التنبيهات',
                  subtitle: 'اختيار نغمة واحدة تطبق على كل إشعارات التطبيق',
                  modeKey: 'unified',
                  icon: Icons.all_inclusive_rounded,
                ),
                _buildModeTile(
                  title: 'نغمة الهاتف الافتراضية',
                  subtitle: 'استخدام صوت الإشعار القياسي لنظام أندرويد للجميع',
                  modeKey: 'default',
                  icon: Icons.smartphone_rounded,
                ),

                const SizedBox(height: 24),

                // Content based on selected mode
                if (_settings.mode == 'custom') ...[
                  Text(
                    'نغمات التذكيرات الفردية',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCustomCategoryCard(
                    title: 'تنبيه الورد اليومي للقرآن',
                    subtitle: 'إشعار تذكير بقراءة الورد اليومي ومتابعة الختمة',
                    icon: Icons.menu_book_rounded,
                    selectedSoundKey: _settings.wirdSound,
                    onSelected: (key) {
                      setState(() => _settings.wirdSound = key);
                      _save();
                    },
                  ),
                  _buildCustomCategoryCard(
                    title: 'تنبيه ورد المواصلات والطريق',
                    subtitle: 'تذكيرات فترات الذهاب والعودة اليومية',
                    icon: Icons.directions_car_rounded,
                    selectedSoundKey: _settings.commuteSound,
                    onSelected: (key) {
                      setState(() => _settings.commuteSound = key);
                      _save();
                    },
                  ),
                  _buildCustomCategoryCard(
                    title: 'تنبيهات أذكار اليوم والليلة',
                    subtitle: 'إشعارات التسبيح وأذكار الصباح والمساء الدورية',
                    icon: Icons.spa_rounded,
                    selectedSoundKey: _settings.azkarSound,
                    onSelected: (key) {
                      setState(() => _settings.azkarSound = key);
                      _save();
                    },
                  ),
                  _buildCustomCategoryCard(
                    title: 'تذكير الصدقة الشهرية',
                    subtitle: 'تنبيه المساهمة في الصدقة والإنفاق المبارك',
                    icon: Icons.favorite_rounded,
                    selectedSoundKey: _settings.sadaqahSound,
                    onSelected: (key) {
                      setState(() => _settings.sadaqahSound = key);
                      _save();
                    },
                  ),
                ] else if (_settings.mode == 'unified') ...[
                  Text(
                    'اختر النغمة الموحدة للتطبيق',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: NotificationSoundsService.availableSounds
                            .map((sound) => _buildSoundRadioTile(
                                  sound: sound,
                                  isSelected:
                                      _settings.unifiedSound == sound.key,
                                  onSelect: () {
                                    setState(
                                        () => _settings.unifiedSound = sound.key);
                                    _save();
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 0,
                    color: isDark
                        ? const Color(0xFF1E2822)
                        : const Color(0xFFF1F6F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: primary.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 32, color: primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تم تفعيل صوت النظام الافتراضي',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ستصلك كافة إشعارات التطبيق بالنغمة القياسية المضبوطة في إعدادات صوت هاتفك.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildModeTile({
    required String title,
    required String subtitle,
    required String modeKey,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _settings.mode == modeKey;
    final primary = const Color(0xFF1B4D3E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withOpacity(0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary : theme.dividerColor.withOpacity(0.3),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: modeKey,
        groupValue: _settings.mode,
        activeColor: primary,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        secondary: Icon(
          icon,
          color: isSelected ? primary : theme.iconTheme.color?.withOpacity(0.6),
        ),
        onChanged: (val) {
          if (val != null) {
            setState(() => _settings.mode = val);
            _save();
          }
        },
      ),
    );
  }

  Widget _buildCustomCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String selectedSoundKey,
    required Function(String) onSelected,
  }) {
    final theme = Theme.of(context);
    final sound = NotificationSoundsService.getOption(selectedSoundKey);
    final primary = const Color(0xFF1B4D3E);
    final isPlaying = _currentlyPlayingKey == sound.key;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSoundPickerModal(
          title: title,
          currentKey: selectedSoundKey,
          onPicked: onSelected,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'النغمة: ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          sound.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play/Stop Button
              if (sound.key != 'silent')
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isPlaying ? Colors.redAccent : primary,
                    size: 32,
                  ),
                  tooltip: isPlaying ? 'إيقاف' : 'استماع للنغمة',
                  onPressed: () => _togglePreview(sound.key),
                ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundRadioTile({
    required SoundOption sound,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF1B4D3E);
    final isPlaying = _currentlyPlayingKey == sound.key;

    return ListTile(
      leading: Icon(
        sound.icon,
        color: isSelected ? primary : theme.iconTheme.color?.withOpacity(0.6),
      ),
      title: Text(
        sound.title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        sound.subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sound.key != 'silent')
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_fill_rounded,
                color: isPlaying ? Colors.redAccent : primary,
                size: 28,
              ),
              tooltip: isPlaying ? 'إيقاف' : 'استماع للنغمة',
              onPressed: () => _togglePreview(sound.key),
            ),
          Radio<bool>(
            value: true,
            groupValue: isSelected,
            activeColor: primary,
            onChanged: (_) => onSelect(),
          ),
        ],
      ),
      onTap: onSelect,
    );
  }

  void _showSoundPickerModal({
    required String title,
    required String currentKey,
    required Function(String) onPicked,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.music_note_rounded,
                              color: Color(0xFF1B4D3E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'اختر نغمة $title',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    ...NotificationSoundsService.availableSounds.map((sound) {
                      final isSelected = currentKey == sound.key;
                      final isPlaying = _currentlyPlayingKey == sound.key;
                      const primary = Color(0xFF1B4D3E);

                      return ListTile(
                        leading: Icon(
                          sound.icon,
                          color: isSelected ? primary : Colors.grey,
                        ),
                        title: Text(
                          sound.title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? primary : null,
                          ),
                        ),
                        subtitle: Text(
                          sound.subtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sound.key != 'silent')
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.stop_circle_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color:
                                      isPlaying ? Colors.redAccent : primary,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  await _togglePreview(sound.key);
                                  setModalState(() {});
                                },
                              ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: primary),
                          ],
                        ),
                        onTap: () {
                          onPicked(sound.key);
                          Navigator.pop(modalContext);
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _service.stopSound();
      setState(() => _currentlyPlayingKey = null);
    });
  }
}
