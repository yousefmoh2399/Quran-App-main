import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/components/app_card.dart';

class BackupRestoreView extends StatefulWidget {
  const BackupRestoreView({super.key});

  @override
  State<BackupRestoreView> createState() => _BackupRestoreViewState();
}

class _BackupRestoreViewState extends State<BackupRestoreView> {
  final UserRepository _userRepo = UserRepository();
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = true;

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final jsonStr = await _userRepo.exportUserDataJson();
      final tempDir = await getTemporaryDirectory();
      final timeStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${tempDir.path}/taqarrab_backup_$timeStr.json';
      final file = File(filePath);
      await file.writeAsString(jsonStr, encoding: utf8);

      final xfile = XFile(filePath, mimeType: 'application/json');
      await Share.shareXFiles(
        [xfile],
        subject: 'نسخة احتياطية لتطبيق تقرب ($timeStr)',
        text: 'ملف النسخة الاحتياطية لبيانات الورد والعلامات والصلوات في تطبيق تقرب.',
      );

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'تم تصدير النسخة الاحتياطية بنجاح.';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'فشل تصدير النسخة: $e';
      });
    }
  }

  void _showImportDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الصق محتوى ملف النسخة الاحتياطية (JSON) هنا لاستعادة بياناتك:',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '{"version": 2, ...}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = textController.text.trim();
              if (content.isEmpty) return;
              Navigator.pop(ctx);

              setState(() {
                _isProcessing = true;
                _statusMessage = null;
              });

              final success = await _userRepo.importUserDataJson(content);
              setState(() {
                _isProcessing = false;
                _isSuccess = success;
                _statusMessage = success
                    ? 'تم استيراد واسترجاع جميع بياناتك بنجاح!'
                    : 'فشل الاستيراد: تأكد من صحة ملف النسخة الاحتياطية.';
              });
            },
            child: const Text('استيراد الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational Card
            AppCard(
              variant: AppCardVariant.elevated,
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_sync_rounded, size: 48, color: colors.primary),
                  ),
                  AppSpacing.verticalMd,
                  const Text(
                    'احفظ إنجازك ووردك من الضياع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يمكنك تصدير نسخة احتياطية كاملة من علاماتك المرجعية، الآيات المحفوظة، خطة الورد وسجل القراءة والصلوات، واستعادتها في أي وقت أو عند تغيير هاتفك.',
                    style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            // Status message banner
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(_isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalLg,
            ],

            // Export Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('تصدير نسخة احتياطية ومشاركتها', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isProcessing ? null : _exportBackup,
              ),
            ),
            AppSpacing.verticalMd,

            // Import Button
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('استيراد نسخة احتياطية من ملف', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isProcessing ? null : _showImportDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
