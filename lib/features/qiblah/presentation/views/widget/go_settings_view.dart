import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_button.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/features/qiblah/presentation/view_model/qiblah_view_model.dart';

class GoSettingsView extends StatelessWidget {
  const GoSettingsView({super.key});

  static const List<Map<String, dynamic>> popularCities = [
    {'name': 'القاهرة', 'lat': 30.0444, 'lng': 31.2357},
    {'name': 'مكة المكرمة', 'lat': 21.3891, 'lng': 39.8579},
    {'name': 'المدينة المنورة', 'lat': 24.5247, 'lng': 39.5692},
    {'name': 'الرياض', 'lat': 24.7136, 'lng': 46.6753},
    {'name': 'الإسكندرية', 'lat': 31.2001, 'lng': 29.9187},
    {'name': 'القدس الشريف', 'lat': 31.7683, 'lng': 35.2137},
    {'name': 'دبي', 'lat': 25.2048, 'lng': 55.2708},
  ];

  void _showCityPickerDialog(BuildContext context, QiblahViewModel vm) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: AppRadius.borderSm,
                    ),
                  ),
                ),
                Text(
                  'اختر مدينتك لتحديد القبلة يدوياً',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalMd,
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: popularCities.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final city = popularCities[index];
                      return ListTile(
                        leading: Icon(Icons.location_city_rounded, color: colors.primary),
                        title: Text(city['name'] as String, style: TextStyle(color: colors.text)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          vm.setManualCity(
                            city['name'] as String,
                            city['lat'] as double,
                            city['lng'] as double,
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<QiblahViewModel>();
    final colors = context.appColors;

    return Obx(() {
      final isServiceDisabled = !vm.isLocationServiceEnabled.value;
      final isPermDenied = vm.isPermanentlyDenied.value;

      String title = 'تحديد الموقع مطلوب للقبلة';
      String message = 'يرجى السماح بالوصول لموقعك لحساب زاوية الكعبة المشرفة بدقة لموضعك الحالي';
      IconData icon = Icons.location_off_rounded;

      if (isServiceDisabled) {
        title = 'خدمات الموقع معطّلة بالجهاز';
        message = 'يرجى تشغيل خدمات الموقع (Location Services / GPS) من إعدادات جهازك';
        icon = Icons.gps_off_rounded;
      } else if (isPermDenied) {
        title = 'إذن الموقع مرفوض';
        message = 'تم رفض الإذن سابقاً، يرجى فتحه من إعدادات التطبيق أو اختيار مدينتك يدوياً';
      }

      return SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              EmptyState(
                icon: icon,
                title: title,
                message: message,
              ),
              AppSpacing.verticalLg,
              if (isServiceDisabled) ...[
                AppButton.primary(
                  label: 'فتح إعدادات الموقع بالجهاز',
                  icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                  onPressed: () => Geolocator.openLocationSettings(),
                ),
                AppSpacing.verticalMd,
                AppButton.secondary(
                  label: 'إعادة الفحص',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => vm.refreshLocationState(),
                ),
              ] else if (isPermDenied) ...[
                AppButton.primary(
                  label: 'فتح إعدادات التطبيق',
                  icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                  onPressed: () => openAppSettings(),
                ),
                AppSpacing.verticalMd,
                AppButton.secondary(
                  label: 'إعادة المحاولة بعد التفعيل',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => vm.refreshLocationState(),
                ),
              ] else ...[
                AppButton.primary(
                  label: 'طلب إذن الموقع الآن',
                  icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  onPressed: () => vm.requestLocationPermission(),
                ),
              ],
              AppSpacing.verticalLg,
              Divider(color: colors.divider),
              AppSpacing.verticalMd,
              OutlinedButton.icon(
                icon: Icon(Icons.edit_location_alt_rounded, color: colors.primary),
                label: Text(
                  'اختيار المدينة يدوياً بدون إذن الموقع',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                onPressed: () => _showCityPickerDialog(context, vm),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }
}
