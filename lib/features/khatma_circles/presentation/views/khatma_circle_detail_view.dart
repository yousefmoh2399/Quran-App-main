import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import '../../data/models/khatma_circle_model.dart';
import '../../data/services/khatma_circles_service.dart';
import '../controllers/khatma_circles_controller.dart';
import 'khatma_qr_display_dialog.dart';
import 'khatma_qr_scanner_view.dart';

class KhatmaCircleDetailView extends StatefulWidget {
  final String? circleId;

  const KhatmaCircleDetailView({
    super.key,
    this.circleId,
  });

  @override
  State<KhatmaCircleDetailView> createState() => _KhatmaCircleDetailViewState();
}

class _KhatmaCircleDetailViewState extends State<KhatmaCircleDetailView> {
  late final KhatmaCirclesController _controller;

  String get _effectiveCircleId {
    if (widget.circleId != null && widget.circleId!.isNotEmpty) {
      return widget.circleId!;
    }
    if (Get.arguments is Map && (Get.arguments as Map).containsKey('circleId')) {
      return (Get.arguments as Map)['circleId'].toString();
    }
    if (Get.arguments is String) {
      return Get.arguments as String;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<KhatmaCirclesController>()
        ? Get.find<KhatmaCirclesController>()
        : Get.put(KhatmaCirclesController());
    _controller.loadCircleDetail(_effectiveCircleId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final circle = _controller.currentCircle.value;
      if (circle == null) {
        return Scaffold(
          backgroundColor: colors.bg,
          body: Center(child: CircularProgressIndicator(color: colors.primary)),
        );
      }

      final percent = (circle.progressPercentage * 100).toInt();

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              circle.title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: colors.text,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_2_rounded),
                color: const Color(0xFFD4AF37),
                tooltip: 'عرض رمز QR للختمة',
                onPressed: () {
                  final p = _controller.getCircleQrPayload(circle);
                  KhatmaQrDisplayDialog.show(
                    context,
                    title: circle.title,
                    subtitle: 'امسح هذا الرمز من هاتف أي شخص آخر للانضمام ومزامنة الأجزاء مباشرة',
                    payload: p,
                    type: KhatmaQrType.circleFull,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                color: colors.primary,
                tooltip: 'مسح إنجاز عضو (QR)',
                onPressed: () => Get.to(() => KhatmaQrScannerView(targetCircleId: circle.id)),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                color: colors.primary,
                tooltip: 'مشاركة عبر واتساب',
                onPressed: () => _controller.shareViaWhatsApp(circle),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.text),
                onSelected: (val) {
                  if (val == 'copy') {
                    final text = _controller.getShareText(circle);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ تقرير الختمة بنجاح'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else if (val == 'delete') {
                    _confirmDelete(context, circle.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Text('نسخ تقرير الختمة بالكامل'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف الختمة', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header Progress Card
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: circle.isCompleted ? Colors.green : colors.divider,
                      width: circle.isCompleted ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التقدم الكلي للختمة',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 13,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${circle.completedJuzCount} من 30 جزء ($percent%)',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: circle.isCompleted ? Colors.green.shade800 : colors.primary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: () => _controller.shareViaWhatsApp(circle),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text(
                              'إرسال لواتساب',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: circle.progressPercentage,
                          backgroundColor: colors.primary.withAlpha(25),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            circle.isCompleted ? Colors.green : colors.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB8860B),
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              onPressed: () {
                                final p = _controller.getCircleQrPayload(circle);
                                KhatmaQrDisplayDialog.show(
                                  context,
                                  title: circle.title,
                                  subtitle: 'امسح هذا الرمز من هاتف أي شخص آخر للانضمام ومزامنة الأجزاء مباشرة',
                                  payload: p,
                                  type: KhatmaQrType.circleFull,
                                );
                              },
                              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                              label: const Text(
                                'رمز الختمة (QR)',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              onPressed: () => Get.to(() => KhatmaQrScannerView(targetCircleId: circle.id)),
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                              label: const Text(
                                'مسح تقدم عضو',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (circle.isCompleted) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.celebration_rounded, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'مبارك! تمت الختمة كاملة، تقبل الله منا ومنكم.',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة الأجزاء الـ 30 (اضغط لتعديل المشارك أو الإتمام):',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // 30 Juz List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: circle.juzList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final juz = circle.juzList[index];
                      return _buildJuzTile(context, juz, colors);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildJuzTile(BuildContext context, KhatmaCircleJuz juz, AppColorsExtension colors) {
    Color statusBg;
    Color statusFg;
    String statusLabel;
    IconData statusIcon;

    if (juz.isCompleted) {
      statusBg = Colors.green.withAlpha(25);
      statusFg = Colors.green.shade800;
      statusLabel = 'تم الإتمام';
      statusIcon = Icons.check_circle_rounded;
    } else if (juz.isInProgress) {
      statusBg = colors.accent.withAlpha(25);
      statusFg = colors.accent;
      statusLabel = 'قيد القراءة';
      statusIcon = Icons.menu_book_rounded;
    } else {
      statusBg = colors.textMuted.withAlpha(15);
      statusFg = colors.textMuted;
      statusLabel = 'متاح للحجز';
      statusIcon = Icons.add_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: juz.isCompleted ? Colors.green.withAlpha(80) : colors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          onTap: () => _showAssignDialog(context, juz),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              '${juz.juzNumber}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colors.primary,
              ),
            ),
          ),
          title: Text(
            KhatmaCirclesService.getJuzTitle(juz.juzNumber),
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          subtitle: Text(
            juz.assignedTo.isNotEmpty ? 'القائم بالقراءة: ${juz.assignedTo}' : 'غير محجوز لأحد بعد',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              color: juz.assignedTo.isNotEmpty ? colors.primary : colors.textMuted,
              fontWeight: juz.assignedTo.isNotEmpty ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (juz.assignedTo.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded, size: 21),
                  color: const Color(0xFFD4AF37),
                  tooltip: 'رمز إنجاز القارئ (QR)',
                  onPressed: () {
                    final payload = _controller.getMemberProgressQrPayload(
                      circleId: juz.circleId,
                      memberName: juz.assignedTo,
                      juzNumbers: [juz.juzNumber],
                      status: juz.status,
                    );
                    KhatmaQrDisplayDialog.show(
                      context,
                      title: 'إنجاز القارئ: ${juz.assignedTo}',
                      subtitle: 'الجزء ${juz.juzNumber}: ${KhatmaCirclesService.getJuzTitle(juz.juzNumber)}',
                      payload: payload,
                      type: KhatmaQrType.memberProgress,
                      memberName: juz.assignedTo,
                      juzNumbers: [juz.juzNumber],
                    );
                  },
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusFg),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, KhatmaCircleJuz juz) {
    final nameController = TextEditingController(text: juz.assignedTo);
    final currentStatus = juz.status.obs;

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
                'تعديل الجزء ${juz.juzNumber}: ${KhatmaCirclesService.getJuzTitle(juz.juzNumber)}',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: ctx.appColors.text,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القارئ / المكلَّف بالجزء',
                  hintText: 'مثال: يوسف، أحمد، الوالدة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'حالة قراءة هذا الجزء:',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  color: ctx.appColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Obx(() => Row(
                children: [
                  _buildStatusChip('متاح', 'available', currentStatus, ctx.appColors),
                  const SizedBox(width: 8),
                  _buildStatusChip('قيد القراءة', 'in_progress', currentStatus, ctx.appColors),
                  const SizedBox(width: 8),
                  _buildStatusChip('تمت القراءة', 'completed', currentStatus, ctx.appColors),
                ],
              )),
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
                  Navigator.of(ctx).pop();
                  await _controller.updateJuzAssignment(
                    juz.juzNumber,
                    assignedTo: nameController.text.trim(),
                    status: currentStatus.value,
                  );
                },
                child: const Text(
                  'حفظ التعديل',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (juz.assignedTo.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB8860B),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final p = _controller.getMemberProgressQrPayload(
                      circleId: juz.circleId,
                      memberName: juz.assignedTo,
                      juzNumbers: [juz.juzNumber],
                      status: currentStatus.value,
                    );
                    KhatmaQrDisplayDialog.show(
                      context,
                      title: 'إنجاز القارئ: ${juz.assignedTo}',
                      subtitle: 'الجزء ${juz.juzNumber}: ${KhatmaCirclesService.getJuzTitle(juz.juzNumber)}',
                      payload: p,
                      type: KhatmaQrType.memberProgress,
                      memberName: juz.assignedTo,
                      juzNumbers: [juz.juzNumber],
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(
                    'عرض رمز إنجاز القارئ (QR)',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String value,
    RxString currentStatus,
    AppColorsExtension colors,
  ) {
    final isSelected = currentStatus.value == value;
    return Expanded(
      child: InkWell(
        onTap: () => currentStatus.value = value,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : colors.text,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String circleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الختمة'),
        content: const Text('هل أنت متأكد من حذف هذه الختمة وسجل الأجزاء الخاص بها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _controller.deleteCircle(circleId);
              Get.back();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
