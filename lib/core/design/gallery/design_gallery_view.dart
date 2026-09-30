import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_theme.dart';
import '../app_typography.dart';
import '../components/components.dart';

/// Debug-only reference gallery demonstrating all design system components
/// across Light, Dark, and Reading Night modes and variable textScalers (1.0 to 2.0).
class DesignGalleryView extends StatefulWidget {
  const DesignGalleryView({super.key});

  @override
  State<DesignGalleryView> createState() => _DesignGalleryViewState();
}

enum _GalleryThemeMode { light, dark, readingNight }

class _DesignGalleryViewState extends State<DesignGalleryView> {
  _GalleryThemeMode _mode = _GalleryThemeMode.light;
  double _textScale = 1.0;

  ThemeData _getTheme() {
    switch (_mode) {
      case _GalleryThemeMode.light:
        return AppTheme.light;
      case _GalleryThemeMode.dark:
        return AppTheme.dark;
      case _GalleryThemeMode.readingNight:
        // Build theme using readingNight palette
        const colors = AppColorsExtension.readingNight;
        final textTheme = AppTypography.createTextTheme(colors.text, colors.textMuted);
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: AppTypography.uiFont,
          scaffoldBackgroundColor: colors.bg,
          colorScheme: ColorScheme.dark(
            primary: colors.primary,
            onPrimary: Colors.black,
            surface: colors.surface,
            onSurface: colors.text,
            outline: colors.divider,
          ),
          textTheme: textTheme,
          extensions: const [colors],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _getTheme();

    return Theme(
      data: activeTheme,
      child: Builder(
        builder: (themedContext) {
          final colors = themedContext.appColors;

          return MediaQuery(
            data: MediaQuery.of(themedContext).copyWith(
              textScaler: TextScaler.linear(_textScale),
            ),
            child: Scaffold(
              backgroundColor: colors.bg,
              appBar: AppBar(
                title: const Text('معرض نظام التصميم (Design Gallery)'),
                actions: [
                  if (kDebugMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Chip(
                        label: Text('${_textScale.toStringAsFixed(1)}x'),
                        backgroundColor: colors.primary.withOpacity(0.12),
                        labelStyle: TextStyle(color: colors.primary, fontSize: 12),
                      ),
                    ),
                ],
              ),
              body: ListView(
                padding: AppSpacing.screen,
                children: [
                  // --- Controls Bar ---
                  _buildControls(themedContext),
                  AppSpacing.verticalLg,

                  // --- Section 1: Colors Palette ---
                  const SectionHeader(title: 'لوحة الألوان (Color Tokens)'),
                  AppSpacing.verticalSm,
                  _buildColorPalette(themedContext),
                  AppSpacing.verticalXl,

                  // --- Section 2: Typography ---
                  const SectionHeader(title: 'مقياس النصوص (Typography)'),
                  AppSpacing.verticalSm,
                  _buildTypographyScale(themedContext),
                  AppSpacing.verticalXl,

                  // --- Section 3: Buttons ---
                  const SectionHeader(title: 'الأزرار (AppButtons)'),
                  AppSpacing.verticalSm,
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      AppButton.primary(
                        label: 'زر أساسي',
                        onPressed: () {},
                      ),
                      AppButton.primary(
                        label: 'مع أيقونة',
                        icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                        onPressed: () {},
                      ),
                      AppButton.secondary(
                        label: 'زر ثانوي',
                        onPressed: () {},
                      ),
                      AppButton.text(
                        label: 'زر نصي',
                        onPressed: () {},
                      ),
                      const AppButton.primary(
                        label: 'تحميل',
                        isLoading: true,
                        onPressed: null,
                      ),
                      const AppButton.primary(
                        label: 'معطل',
                        onPressed: null,
                      ),
                    ],
                  ),
                  AppSpacing.verticalXl,

                  // --- Section 4: Cards ---
                  const SectionHeader(title: 'البطاقات (AppCards)'),
                  AppSpacing.verticalSm,
                  AppCard(
                    variant: AppCardVariant.outlined,
                    child: Text(
                      'بطاقة محددة بإطار (Outlined Card)',
                      style: Theme.of(themedContext).textTheme.bodyMedium,
                    ),
                  ),
                  AppSpacing.verticalMd,
                  AppCard(
                    variant: AppCardVariant.elevated,
                    child: Text(
                      'بطاقة مرتفعة مع ظل خفيف (Elevated Card)',
                      style: Theme.of(themedContext).textTheme.bodyMedium,
                    ),
                  ),
                  AppSpacing.verticalXl,

                  // --- Section 5: ListTiles ---
                  const SectionHeader(title: 'عناصر القائمة (AppListTile)'),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        AppListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withOpacity(0.12),
                            child: Text('1', style: TextStyle(color: colors.primary)),
                          ),
                          title: const Text('سورة الفاتحة'),
                          subtitle: const Text('مكية • 7 آيات'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {},
                        ),
                        Divider(color: colors.divider, height: 1),
                        AppListTile(
                          selected: true,
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withOpacity(0.12),
                            child: Text('2', style: TextStyle(color: colors.primary)),
                          ),
                          title: const Text('سورة البقرة (محدد)'),
                          subtitle: const Text('مدنية • 286 آية'),
                          trailing: const Icon(Icons.check_circle_rounded, size: 18),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalXl,

                  // --- Section 6: Loading Skeleton ---
                  const SectionHeader(title: 'هيكل التحميل (Loading Skeletons)'),
                  AppSpacing.verticalSm,
                  const SkeletonListTile(),
                  const SkeletonListTile(),
                  AppSpacing.verticalXl,

                  // --- Section 7: Bottom Sheet Trigger ---
                  const SectionHeader(title: 'القوائم السفلية (AppBottomSheet)'),
                  AppSpacing.verticalSm,
                  AppButton.secondary(
                    label: 'تجربة القائمة السفلية (Open BottomSheet)',
                    onPressed: () {
                      AppBottomSheet.show(
                        context: themedContext,
                        title: 'خيارات التلاوة',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppListTile(
                              title: const Text('حفظ في العلامات المرجعية'),
                              leading: const Icon(Icons.bookmark_outline_rounded),
                              onTap: () => Navigator.pop(themedContext),
                            ),
                            AppListTile(
                              title: const Text('مشاركة الآية'),
                              leading: const Icon(Icons.share_outlined),
                              onTap: () => Navigator.pop(themedContext),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  AppSpacing.verticalXl,

                  // --- Section 8: Empty and Error States ---
                  const SectionHeader(title: 'حالات الشاشة (States)'),
                  AppSpacing.verticalSm,
                  AppCard(
                    child: const EmptyState(
                      title: 'لا توجد محفوظات',
                      message: 'لم تقم بحفظ أي آية أو ذكر في المفضلة بعد.',
                      actionLabel: 'استكشف القرآن',
                    ),
                  ),
                  AppSpacing.verticalMd,
                  AppCard(
                    child: ErrorState(
                      title: 'تعذر الاتصال بالشبكة',
                      message: 'يرجى التأكد من اتصالك بالإنترنت والمحاولة مجدداً.',
                      onRetry: () {},
                    ),
                  ),
                  AppSpacing.verticalXxl,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أوضاع المعاينة التفاعلية',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
          ),
          AppSpacing.verticalSm,
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_GalleryThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: _GalleryThemeMode.light,
                      label: Text('فاتح'),
                    ),
                    ButtonSegment(
                      value: _GalleryThemeMode.dark,
                      label: Text('داكن'),
                    ),
                    ButtonSegment(
                      value: _GalleryThemeMode.readingNight,
                      label: Text('ليلي'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (set) {
                    setState(() => _mode = set.first);
                  },
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,
          Row(
            children: [
              Text('مقياس النص: ${_textScale.toStringAsFixed(1)}x',
                  style: Theme.of(context).textTheme.bodySmall),
              Expanded(
                child: Slider(
                  value: _textScale,
                  min: 1.0,
                  max: 2.0,
                  divisions: 2,
                  label: '${_textScale.toStringAsFixed(1)}x',
                  onChanged: (v) {
                    setState(() => _textScale = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    final colors = context.appColors;

    final chips = [
      _ColorChip(label: 'Primary', color: colors.primary),
      _ColorChip(label: 'Accent', color: colors.accent),
      _ColorChip(label: 'Background', color: colors.bg),
      _ColorChip(label: 'Surface', color: colors.surface),
      _ColorChip(label: 'Text', color: colors.text),
      _ColorChip(label: 'TextMuted', color: colors.textMuted),
      _ColorChip(label: 'Divider', color: colors.divider),
      _ColorChip(label: 'Error', color: colors.error),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }

  Widget _buildTypographyScale(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Large: بِسْمِ اللَّهِ', style: tt.displayLarge),
          Text('Headline Large: سورة البقرة', style: tt.headlineLarge),
          Text('Title Large: القرآن الكريم', style: tt.titleLarge),
          Text('Title Medium: قراءة وتفسير الآيات', style: tt.titleMedium),
          Text('Body Large: متن الحديث الشريف', style: tt.bodyLarge),
          Text('Body Medium: النص التوضيحي الافتراضي', style: tt.bodyMedium),
          Text('Label Large: زر المتابعة', style: tt.labelLarge),
          Text('Body Small: ملحوظة هامشية صغيرة', style: tt.bodySmall),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
