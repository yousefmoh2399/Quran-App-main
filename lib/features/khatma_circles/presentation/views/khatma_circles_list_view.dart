import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import '../../data/models/khatma_circle_model.dart';
import '../controllers/khatma_circles_controller.dart';
import 'khatma_circle_detail_view.dart';
import 'khatma_qr_display_dialog.dart';
import 'khatma_qr_scanner_view.dart';

class KhatmaCirclesListView extends StatefulWidget {
  const KhatmaCirclesListView({super.key});

  @override
  State<KhatmaCirclesListView> createState() => _KhatmaCirclesListViewState();
}

class _KhatmaCirclesListViewState extends State<KhatmaCirclesListView> {
  late final KhatmaCirclesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<KhatmaCirclesController>()
        ? Get.find<KhatmaCirclesController>()
        : Get.put(KhatmaCirclesController());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          title: Text(
            'ختمات العائلة والأصدقاء',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              color: colors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              tooltip: 'مسح رمز QR للانضمام',
              icon: const Icon(Icons.qr_code_scanner_rounded),
              color: colors.primary,
              onPressed: () => Get.to(() => const KhatmaQrScannerView()),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showCreateCircleDialog(context),
          icon: const Icon(Icons.group_add_rounded),
          label: const Text(
            'إنشاء ختمة جديدة',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          if (_controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }

          final circles = _controller.circles;
          if (circles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 64,
                      color: colors.primary.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد ختمات جماعية حالياً',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أنشئ ختمة ووزّع الأجزاء الـ 30 على أفراد العائلة أو الأصدقاء أو كصدقة جارية، وشارك التقدم عبر واتساب بضغطة زر.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13.5,
                        color: colors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () => _showCreateCircleDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'ابدأ ختمة الآن',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () => Get.to(() => const KhatmaQrScannerView()),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text(
                        'مسح رمز QR للانضمام لختمة عائلية',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: circles.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final circle = circles[index];
              return _buildCircleCard(context, circle, colors);
            },
          );
        }),
      ),
    );
  }

  Widget _buildCircleCard(BuildContext context, KhatmaCircle circle, AppColorsExtension colors) {
    final percent = (circle.progressPercentage * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: circle.isCompleted ? Colors.green.shade600 : colors.divider,
          width: circle.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            AppHaptics.selection();
            Get.to(() => KhatmaCircleDetailView(circleId: circle.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        circle.title,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                    ),
                    if (circle.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'مكتملة',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_2_rounded, size: 21),
                            color: const Color(0xFFD4AF37),
                            tooltip: 'رمز الاستجابة للختمة (QR)',
                            onPressed: () {
                              final payload = _controller.getCircleQrPayload(circle);
                              KhatmaQrDisplayDialog.show(
                                context,
                                title: circle.title,
                                subtitle: 'امسح هذا الرمز من هاتف أي شخص آخر للانضمام للختمة مباشرة',
                                payload: payload,
                                type: KhatmaQrType.circleFull,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 20),
                            color: colors.primary,
                            tooltip: 'مشاركة عبر واتساب',
                            onPressed: () => _controller.shareViaWhatsApp(circle),
                          ),
                        ],
                      ),
                  ],
                ),
                if (circle.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    circle.description,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: circle.progressPercentage,
                    backgroundColor: colors.primary.withAlpha(25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      circle.isCompleted ? Colors.green : colors.primary,
                    ),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 8),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تم إتمام ${circle.completedJuzCount} من 30 جزء ($percent%)',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'متاح: ${circle.availableJuzCount} | قيد القراءة: ${circle.inProgressJuzCount}',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateCircleDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إنشاء ختمة جماعية جديدة',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ctx.appColors.text,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم الختمة *',
                  hintText: 'مثال: ختمة العائلة لرمضان، ختمة للوالد رحمه الله',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'إهداء أو ملاحظة (اختياري)',
                  hintText: 'مثال: نسأل الله القبول لجميع المشاركين',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  Navigator.of(ctx).pop();
                  final created = await _controller.createCircle(
                    title: title,
                    description: descController.text.trim(),
                  );
                  Get.to(() => KhatmaCircleDetailView(circleId: created.id));
                },
                child: const Text(
                  'إنشاء وتوزيع الأجزاء الـ 30',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
