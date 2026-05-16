import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_providers.dart';
import '../../../../core/constants/app_date_formats.dart';

class DataPrivacyPage extends ConsumerStatefulWidget {
  const DataPrivacyPage({super.key});

  @override
  ConsumerState<DataPrivacyPage> createState() => _DataPrivacyPageState();
}

class _DataPrivacyPageState extends ConsumerState<DataPrivacyPage> {
  String? _activeExport; // 'all' | 'transactions' | 'budgets'

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsOperationsProvider);
    final settings = settingsAsync.valueOrNull;
    final schedule =
        settings?.notificationPreferences.autoBackupSchedule ?? 'off';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('dataPrivacy.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Data Management ───────────────────────────────────────
            _sectionLabel(context, 'dataPrivacy.dataManagement'.tr()),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              _buildOptionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.cloud_upload,
                title: 'dataPrivacy.backupSchedule'.tr(),
                subtitle: 'dataPrivacy.backupSub'.tr(),
                trailingText: _scheduleLabel(schedule),
                onTap: () => _showSchedulePicker(settings, schedule),
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.arrow_down_circle,
                title: 'dataPrivacy.exportAll'.tr(),
                subtitle: 'dataPrivacy.exportAllSub'.tr(),
                onTap: _activeExport != null ? null : _exportAllData,
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.table,
                title: 'dataPrivacy.exportTransactions'.tr(),
                subtitle: 'dataPrivacy.exportTransactionsSub'.tr(),
                onTap: _activeExport != null ? null : _exportTransactions,
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.chart_bar,
                title: 'dataPrivacy.exportBudgets'.tr(),
                subtitle: 'dataPrivacy.exportBudgetsSub'.tr(),
                onTap: _activeExport != null ? null : _exportBudgets,
              ),
            ]),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── Shared layout helpers ──────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text,
      {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDanger ? AppColors.error : AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.labelDark : AppColors.secondaryLabel,
                size: 17,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(CupertinoIcons.chevron_right,
                  size: 16, color: AppColors.systemGray3),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.labelDark : AppColors.secondaryLabel,
                size: 17,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              trailingText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryLabel,
                  ),
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.systemGray3),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _scheduleLabel(String schedule) {
    switch (schedule) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      default:
        return 'Off';
    }
  }

  void _showSchedulePicker(SettingsEntity? settings, String current) {
    final options = ['off', 'daily', 'weekly'];
    final labels = ['Off', 'Daily', 'Weekly'];

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('dataPrivacy.backupSchedule'.tr()),
        children: List.generate(options.length, (i) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (settings == null) return;
              final updated = settings.notificationPreferences
                  .copyWith(autoBackupSchedule: options[i]);
              ref
                  .read(settingsOperationsProvider.notifier)
                  .updateNotificationPreferences(updated);
            },
            child: Row(
              children: [
                Expanded(child: Text(labels[i])),
                if (options[i] == current)
                  const Icon(CupertinoIcons.checkmark,
                      size: 16, color: AppColors.primaryTeal),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _exportAllData() async =>
      _runExport('all', 'Preparing full data export…', () async {
        return ref.read(settingsOperationsProvider.notifier).exportDataAsJson();
      },
          filename: 'finmate_export',
          ext: 'json',
          mime: 'application/json',
          subject: 'Finmate Data Export');

  Future<void> _exportTransactions() async =>
      _runExport('transactions', 'Preparing transactions…', () async {
        return ref
            .read(settingsOperationsProvider.notifier)
            .exportTransactionsAsCsv();
      },
          filename: 'finmate_transactions',
          ext: 'csv',
          mime: 'text/csv',
          subject: 'Finmate Transactions');

  Future<void> _exportBudgets() async =>
      _runExport('budgets', 'Preparing budgets…', () async {
        return ref
            .read(settingsOperationsProvider.notifier)
            .exportBudgetsAsCsv();
      },
          filename: 'finmate_budgets',
          ext: 'csv',
          mime: 'text/csv',
          subject: 'Finmate Budgets');

  /// Fetches export data, dismisses the loading dialog, THEN opens share sheet.
  /// This way the dialog is never left hanging if Share.shareXFiles doesn't resolve.
  Future<void> _runExport(
    String key,
    String loadingMessage,
    Future<String> Function() fetchData, {
    required String filename,
    required String ext,
    required String mime,
    required String subject,
  }) async {
    setState(() => _activeExport = key);
    _showLoadingDialog(loadingMessage);
    String data;
    try {
      data = await fetchData();
    } catch (e) {
      if (!mounted || _activeExport == null) return;
      Navigator.of(context).pop(); // dismiss loading dialog
      setState(() => _activeExport = null);
      _showErrorDialog(e);
      return;
    }

    // Data is ready — dismiss loading dialog before opening share sheet
    if (!mounted || _activeExport == null) return;
    Navigator.of(context).pop();
    setState(() => _activeExport = null);

    // Share (fire-and-forget — share_plus future may not resolve on iOS)
    await _shareFile(data,
        filename: filename, ext: ext, mime: mime, subject: subject);
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) setState(() => _activeExport = null);
              },
              child: Text('common.cancel'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(
    String content, {
    required String filename,
    required String ext,
    required String mime,
    required String subject,
  }) async {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat(AppDateFormats.exportTimestamp).format(DateTime.now());
      final file = File('${dir.path}/${filename}_$stamp.$ext');
      await file.writeAsString(content);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mime)],
        subject: subject,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (!mounted) return;
      await Share.share(content, subject: subject, sharePositionOrigin: origin);
    }
  }

  void _showErrorDialog(Object e) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('dataPrivacy.exportFailed'.tr()),
        content: Text(e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Exception(', '')
            .replaceAll(')', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.done'.tr()),
          ),
        ],
      ),
    );
  }
}
