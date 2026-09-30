import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_button.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';

class GoSettingsView extends StatelessWidget {
  const GoSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(
              icon: Icons.location_off_rounded,
              title: 'إذن الموقع مطلوب للقبلة',
              message: 'يرجى تفعيل إذن الموقع لتتمكن البوصلة من تحديد اتجاه الكعبة المشرفة بدقة',
            ),
            AppSpacing.verticalLg,
            AppButton.primary(
              label: 'فتح إعدادات الهاتف',
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
              onPressed: () => openAppSettings(),
            ),
          ],
        ),
      ),
    );
  }
}
