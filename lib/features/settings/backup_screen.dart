import 'package:flutter/material.dart';

import '../../app/localization/app_localization.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/depth_card.dart';
import '../../data/services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();

  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  bool _isExporting = false;
  bool _autoBackupEnabled = false;
  String? _statusMessage;
  Color? _statusColor;
  List<BackupMetadata> _cloudBackups = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final autoBackup = await _backupService.isAutoBackupEnabled();
      final backups = await _backupService.listCloudBackups();
      if (mounted) {
        setState(() {
          _autoBackupEnabled = autoBackup;
          _cloudBackups = backups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = context.tr(
            ar: 'تعذر تحميل بيانات النسخ الاحتياطي. تحقق من اتصالك بالإنترنت.',
            en: 'Could not load backup data. Check your internet connection.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
  }

  Future<void> _createCloudBackup() async {
    setState(() {
      _isCreatingBackup = true;
      _statusMessage = null;
    });

    try {
      final metadata = await _backupService.createCloudBackup();
      final backups = await _backupService.listCloudBackups();
      if (mounted) {
        setState(() {
          _cloudBackups = backups;
          _isCreatingBackup = false;
          _statusMessage = context.tr(
            ar: 'تم إنشاء النسخة الاحتياطية السحابية بنجاح (${metadata.formattedDate})',
            en: 'Cloud backup created successfully (${metadata.formattedDate})',
          );
          _statusColor = AppPalette.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
          _statusMessage = context.tr(
            ar: 'فشل إنشاء النسخة الاحتياطية. تأكد من تسجيل الدخول ومن اتصال الإنترنت.',
            en: 'Backup failed. Make sure you are signed in and have internet access.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  Future<void> _restoreFromCloud(BackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      context.tr(
        ar: 'استعادة البيانات',
        en: 'Restore data',
      ),
      context.tr(
        ar: 'سيتم استعادة البيانات من النسخة الاحتياطية المؤرخة ${backup.formattedDate}. هل تريد المتابعة؟',
        en: 'This will restore data from the backup dated ${backup.formattedDate}. Continue?',
      ),
    );
    if (confirm != true) return;

    setState(() {
      _isRestoring = true;
      _statusMessage = null;
    });

    try {
      final summary = await _backupService.restoreFromCloud(backup.storagePath);
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _statusMessage = context.tr(
            ar: 'تمت الاستعادة بنجاح.\n$summary',
            en: 'Restore completed.\n$summary',
          );
          _statusColor = AppPalette.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _statusMessage = context.tr(
            ar: 'فشلت الاستعادة. تأكد من صحة ملف النسخة الاحتياطية.',
            en: 'Restore failed. Verify the backup file is valid.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  Future<void> _deleteCloudBackup(BackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      context.tr(
        ar: 'حذف النسخة الاحتياطية',
        en: 'Delete backup',
      ),
      context.tr(
        ar: 'هل أنت متأكد من حذف النسخة الاحتياطية المؤرخة ${backup.formattedDate}؟',
        en: 'Are you sure you want to delete the backup from ${backup.formattedDate}?',
      ),
    );
    if (confirm != true) return;

    try {
      await _backupService.deleteCloudBackup(backup.storagePath);
      final backups = await _backupService.listCloudBackups();
      if (mounted) {
        setState(() {
          _cloudBackups = backups;
          _statusMessage = context.tr(
            ar: 'تم حذف النسخة الاحتياطية.',
            en: 'Backup deleted.',
          );
          _statusColor = AppPalette.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = context.tr(
            ar: 'فشل الحذف. حاول مرة أخرى.',
            en: 'Delete failed. Try again.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  Future<void> _exportLocalFile() async {
    setState(() {
      _isExporting = true;
      _statusMessage = null;
    });

    try {
      await _backupService.shareBackupFile();
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = context.tr(
            ar: 'تم تصدير ملف النسخة الاحتياطية بنجاح.',
            en: 'Backup file exported successfully.',
          );
          _statusColor = AppPalette.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = context.tr(
            ar: 'فشل التصدير. حاول مرة أخرى.',
            en: 'Export failed. Try again.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  Future<void> _importLocalFile() async {
    final controller = TextEditingController();
    final jsonString = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(
          ar: 'لصق محتوى النسخة الاحتياطية',
          en: 'Paste backup content',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(
                ar: 'افتح ملف JSON الذي قمت بتصديره، وانسخ المحتوى بالكامل وألصقه هنا.',
                en: 'Open the exported JSON file, copy all content and paste it here.',
              ),
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: AppFontSize.body,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: context.tr(
                  ar: 'الصق محتوى JSON هنا...',
                  en: 'Paste JSON content here...',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr(ar: 'إلغاء', en: 'Cancel'),
              style: const TextStyle(color: AppPalette.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              context.tr(ar: 'استعادة', en: 'Restore'),
              style: const TextStyle(
                color: AppPalette.patientPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
    if (jsonString == null || jsonString.trim().isEmpty) return;

    setState(() {
      _isRestoring = true;
      _statusMessage = null;
    });

    try {
      final summary = await _backupService.restoreFromJsonString(jsonString);
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _statusMessage = context.tr(
            ar: 'تمت الاستعادة بنجاح.\n$summary',
            en: 'Restore completed.\n$summary',
          );
          _statusColor = AppPalette.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _statusMessage = context.tr(
            ar: 'فشلت الاستعادة. تأكد من أن المحتوى المنسوخ صحيح.',
            en: 'Restore failed. Make sure the pasted content is valid.',
          );
          _statusColor = AppPalette.coral;
        });
      }
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackupEnabled = value);
    try {
      await _backupService.setAutoBackupEnabled(value);
      if (value) {
        await _backupService.createCloudBackup(isAutomatic: true);
      }
      if (mounted) {
        _showStatus(
          value
              ? context.tr(
                  ar: 'تم تفعيل النسخ الاحتياطي التلقائي.',
                  en: 'Automatic backup enabled.',
                )
              : context.tr(
                  ar: 'تم إيقاف النسخ الاحتياطي التلقائي.',
                  en: 'Automatic backup disabled.',
                ),
          AppPalette.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _autoBackupEnabled = !value);
        _showStatus(
          context.tr(ar: 'فشل تحديث الإعدادات.', en: 'Failed to update settings.'),
          AppPalette.coral,
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr(ar: 'إلغاء', en: 'Cancel'),
              style: const TextStyle(color: AppPalette.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr(ar: 'تأكيد', en: 'Confirm'),
              style: const TextStyle(
                color: AppPalette.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(ar: 'النسخ الاحتياطي', en: 'Backup & Restore')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F7FF), Color(0xFFEAF2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: AppSpacing.pagePaddingWide,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatusBanner(),
                        const SizedBox(height: AppSpacing.md),
                        _buildCloudSection(),
                        const SizedBox(height: AppSpacing.md),
                        _buildLocalSection(),
                        const SizedBox(height: AppSpacing.md),
                        _buildAutoBackupSection(),
                        const SizedBox(height: AppSpacing.lg),
                        if (_cloudBackups.isNotEmpty) ...[
                          _buildBackupsListHeader(),
                          const SizedBox(height: AppSpacing.sm),
                          ..._cloudBackups.map(_buildBackupTile),
                        ] else
                          _buildEmptyBackups(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppPalette.patientPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: AppPalette.patientPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr(
                    ar: 'النسخ الاحتياطي',
                    en: 'Backup & Restore',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.pageTitle,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              ar: 'احفظ بياناتك بأمان في السحابة أو على جهازك. يمكنك استعادتها في أي وقت.',
              en: 'Keep your data safe with cloud or local backups. Restore anytime.',
            ),
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: AppFontSize.body,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_statusMessage == null) return const SizedBox.shrink();
    return DepthCard(
      borderColor: (_statusColor ?? AppPalette.success).withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(
            _statusColor == AppPalette.success
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            color: _statusColor ?? AppPalette.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: AppPalette.text,
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSection() {
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.cloud_rounded,
            context.tr(ar: 'النسخ الاحتياطي السحابي', en: 'Cloud Backup'),
            context.tr(
              ar: 'خزّن بياناتك في Firebase Storage بشكل آمن',
              en: 'Store your data securely in the cloud',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _actionButton(
            icon: Icons.cloud_upload_rounded,
            label: context.tr(ar: 'إنشاء نسخة احتياطية سحابية', en: 'Create cloud backup'),
            isLoading: _isCreatingBackup,
            onTap: _createCloudBackup,
          ),
          if (_cloudBackups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _actionButton(
              icon: Icons.refresh_rounded,
              label: context.tr(ar: 'تحديث القائمة', en: 'Refresh list'),
              isLoading: false,
              onTap: _loadInitialData,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalSection() {
    return DepthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.phone_android_rounded,
            context.tr(ar: 'نسخة احتياطية محلية', en: 'Local Backup'),
            context.tr(
              ar: 'صدّر بياناتك كملف أو استورد نسخة سابقة',
              en: 'Export data as a file or import a previous backup',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _actionButton(
            icon: Icons.download_rounded,
            label: context.tr(ar: 'تصدير ملف النسخة الاحتياطية', en: 'Export backup file'),
            isLoading: _isExporting,
            onTap: _exportLocalFile,
          ),
          const SizedBox(height: AppSpacing.sm),
          _actionButton(
            icon: Icons.upload_file_rounded,
            label: context.tr(ar: 'استيراد من ملف', en: 'Import from file'),
            isLoading: _isRestoring && _statusMessage == null,
            isSecondary: true,
            onTap: _importLocalFile,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupSection() {
    return DepthCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppPalette.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppPalette.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    ar: 'النسخ الاحتياطي التلقائي',
                    en: 'Automatic backup',
                  ),
                  style: const TextStyle(
                    fontSize: AppFontSize.bodyLarge,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                Text(
                  context.tr(
                    ar: 'إنشاء نسخة احتياطية سحابية تلقائياً عند التفعيل',
                    en: 'Automatically create a cloud backup when enabled',
                  ),
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoBackupEnabled,
            activeThumbColor: AppPalette.success,
            onChanged: _toggleAutoBackup,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        context.tr(
          ar: 'النسخ الاحتياطية السحابية المتاحة',
          en: 'Available cloud backups',
        ),
        style: const TextStyle(
          fontSize: AppFontSize.title,
          fontWeight: FontWeight.w800,
          color: AppPalette.text,
        ),
      ),
    );
  }

  Widget _buildBackupTile(BackupMetadata backup) {
    final isAutomatic = backup.backupType == 'automatic';
    return DepthCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isAutomatic ? AppPalette.success : AppPalette.patientPrimary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isAutomatic ? Icons.schedule_rounded : Icons.cloud_done_rounded,
                  size: 20,
                  color: isAutomatic ? AppPalette.success : AppPalette.patientPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.formattedDate,
                      style: const TextStyle(
                        fontSize: AppFontSize.bodyLarge,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${backup.medicationsCount} ${context.tr(ar: 'أدوية', en: 'meds')} · '
                      '${backup.doseLogsCount} ${context.tr(ar: 'جرعة', en: 'doses')}'
                      '${backup.tasksCount > 0 ? ' · ${backup.tasksCount} ${context.tr(ar: 'مهام', en: 'tasks')}' : ''}',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppPalette.muted),
                onSelected: (value) {
                  if (value == 'restore') {
                    _restoreFromCloud(backup);
                  } else if (value == 'delete') {
                    _deleteCloudBackup(backup);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        const Icon(Icons.restore_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(context.tr(ar: 'استعادة', en: 'Restore')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_rounded, size: 18, color: AppPalette.coral),
                        const SizedBox(width: 8),
                        Text(
                          context.tr(ar: 'حذف', en: 'Delete'),
                          style: const TextStyle(color: AppPalette.coral),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isRestoring) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyBackups() {
    return DepthCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppPalette.muted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(
                  ar: 'لا توجد نسخ احتياطية سحابية بعد',
                  en: 'No cloud backups yet',
                ),
                style: const TextStyle(
                  color: AppPalette.muted,
                  fontSize: AppFontSize.bodyLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppPalette.patientPrimary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.title,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: AppFontSize.body,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? AppPalette.surfaceAlt
              : AppPalette.patientPrimary,
          foregroundColor: isSecondary ? AppPalette.text : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
