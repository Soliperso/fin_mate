import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_providers.dart';

class DataPrivacyPage extends ConsumerWidget {
  const DataPrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final schedule = settings?.notificationPreferences.autoBackupSchedule ?? 'off';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Data & Privacy'),
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
            _sectionLabel(context, 'Data Management'),
            const SizedBox(height: AppSizes.sm),
            _buildCard(context, isDark, children: [
              _buildOptionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.cloud_upload,
                title: 'Backup Schedule',
                subtitle: 'Automatically back up your data',
                trailingText: _scheduleLabel(schedule),
                onTap: () => _showSchedulePicker(context, ref, settings, schedule),
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.arrow_down_circle,
                title: 'Export All Data',
                subtitle: 'Download complete profile as JSON',
                onTap: () => _exportAllData(context, ref),
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.table,
                title: 'Export Transactions',
                subtitle: 'Download transactions as CSV',
                onTap: () => _exportTransactions(context, ref),
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.chart_bar,
                title: 'Export Budgets',
                subtitle: 'Download budgets as CSV',
                onTap: () => _exportBudgets(context, ref),
              ),
              _buildDivider(context, isDark),
              _buildActionTile(
                context,
                isDark: isDark,
                icon: CupertinoIcons.lock_shield,
                title: 'Data Protection',
                subtitle: 'Your data is encrypted and never shared',
                showChevron: false,
                onTap: null,
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Danger Zone ───────────────────────────────────────────
            _sectionLabel(context, 'Danger Zone', isDanger: true),
            const SizedBox(height: AppSizes.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showDeleteAccountDialog(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.trash,
                            color: AppColors.error, size: 17),
                      ),
                      const SizedBox(width: AppSizes.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Permanently delete your account and all data',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_right,
                          size: 16,
                          color: AppColors.error.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 12),
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 12),
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

  void _showSchedulePicker(
    BuildContext context,
    WidgetRef ref,
    SettingsEntity? settings,
    String current,
  ) {
    final options = ['off', 'daily', 'weekly'];
    final labels = ['Off', 'Daily', 'Weekly'];

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Backup Schedule'),
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

  void _exportAllData(BuildContext context, WidgetRef ref) async {
    try {
      final jsonData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportDataAsJson();
      if (!context.mounted) return;
      await _share(context, jsonData, subject: 'FinMate Data Export');
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, e);
    }
  }

  void _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final csvData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportTransactionsAsCsv();
      if (!context.mounted) return;
      await _share(context, csvData, subject: 'FinMate Transactions Export');
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, e);
    }
  }

  void _exportBudgets(BuildContext context, WidgetRef ref) async {
    try {
      final csvData = await ref
          .read(settingsOperationsProvider.notifier)
          .exportBudgetsAsCsv();
      if (!context.mounted) return;
      await _share(context, csvData, subject: 'FinMate Budgets Export');
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, e);
    }
  }

  Future<void> _share(BuildContext context, String text,
      {required String subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {
      // Share sheet unavailable or dismissed — show a non-intrusive message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is not available on this device')),
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, Object e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text('$e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: This action cannot be undone!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSizes.md),
            Text('Deleting your account will:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: AppSizes.xs),
            Text('• Permanently delete all your transactions'),
            Text('• Delete all budgets and goals'),
            Text('• Remove you from bill splitting groups'),
            Text('• Delete all uploaded documents'),
            SizedBox(height: AppSizes.md),
            Text(
              'This action cannot be reversed.',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmationDialog(context, ref);
            },
            child: const Text('Delete My Account',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showPasswordConfirmationDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to confirm account deletion:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSizes.lg),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAccountDeletion(context, ref);
            },
            child: const Text('Delete Account',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(
      BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsOperationsProvider.notifier).deleteAccount();
      if (context.mounted) {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Deletion Failed'),
            content: Text('Failed to delete account: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
