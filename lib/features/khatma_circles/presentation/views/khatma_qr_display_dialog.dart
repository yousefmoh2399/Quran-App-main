import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/services/app_haptics_service.dart';

enum KhatmaQrType {
  circleFull,
  memberProgress,
}

class KhatmaQrDisplayDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String payload;
  final KhatmaQrType type;
  final String? memberName;
  final List<int>? juzNumbers;

  const KhatmaQrDisplayDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.payload,
    this.type = KhatmaQrType.circleFull,
    this.memberName,
    this.juzNumbers,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String payload,
    KhatmaQrType type = KhatmaQrType.circleFull,
    String? memberName,
    List<int>? juzNumbers,
  }) {
    AppHaptics.selection();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => KhatmaQrDisplayDialog(
        title: title,
        subtitle: subtitle,
        payload: payload,
        type: type,
        memberName: memberName,
        juzNumbers: juzNumbers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.6),
            width: 1.5,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type == KhatmaQrType.circleFull ? Icons.qr_code_2_rounded : Icons.person_pin_circle_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type == KhatmaQrType.circleFull ? 'رمز الختمة الجماعية' : 'رمز إنجاز العضو اليومي',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  color: colors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // QR Code Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1B4D3E),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Offline Explanation note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type == KhatmaQrType.circleFull
                            ? 'امسح هذا الرمز من هاتف أي شخص آخر عبر زر "مسح QR" للانضمام للختمة أوفلاين تماماً.'
                            : 'امسح هذا الرمز من هاتف منظم الختمة لتحديث إتمامك للأجزاء مباشرة دون إنترنت.',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Copy Code & Share Text)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: payload));
                        AppHaptics.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ شفرة الرمز إلى الحافظة ✅'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: const Text(
                        'نسخ الشفرة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.selection();
                        final shareMsg = type == KhatmaQrType.circleFull
                            ? '🌙 رمز الانضمام لختمة ($title):\n\n$payload\n\nافتح تطبيق تقرّب ثم ختمات العائلة > مسح QR ثم الصق الرمز للانضمام.'
                            : '✨ تحديث إنجاز $memberName في ختمة القرآن:\n\n$payload\n\nأتم الأجزاء: ${juzNumbers?.join('، ') ?? ''}';
                        Share.share(shareMsg);
                      },
                      icon: const Icon(Icons.share_rounded, size: 17),
                      label: const Text(
                        'مشاركة الرمز',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
