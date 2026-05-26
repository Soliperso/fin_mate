import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_date_formats.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../providers/admin_providers.dart';

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        title: const Text('System Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.lg),

            // ── Categories Management ──────────────────────────────────────
            _sectionLabel(context, 'Categories Management'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.square_grid_2x2,
                iconColor: AppColors.brandTeal,
                title: 'Default Categories',
                subtitle: 'Manage system default transaction categories',
                onTap: () => context.push('/admin/categories'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.add_circled,
                iconColor: AppColors.tealBlue,
                title: 'Add Custom Category',
                subtitle: 'Create new transaction categories',
                onTap: () => context.push('/admin/categories?add=true'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Feature Flags ─────────────────────────────────────────────
            _sectionLabel(context, 'Feature Flags'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.slider_horizontal_3,
                iconColor: AppColors.systemBlue,
                title: 'Feature Toggles',
                subtitle: 'Enable or disable features for all users',
                onTap: () => context.push('/admin/feature-toggles'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.lab_flask,
                iconColor: AppColors.systemOrange,
                title: 'Beta Features',
                subtitle: 'Manage experimental features',
                onTap: () => context.push('/admin/feature-toggles?beta=true'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── App Versions ──────────────────────────────────────────────
            _sectionLabel(context, 'App Versions'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.arrow_up_circle,
                iconColor: AppColors.brandTeal,
                title: 'Version Manager',
                subtitle: 'Set minimum versions and force update per platform',
                onTap: () => context.push('/admin/app-versions'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Announcements & Feedback ──────────────────────────────────
            _sectionLabel(context, 'Announcements & Feedback'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.speaker_2,
                iconColor: AppColors.systemOrange,
                title: 'Announcement Banners',
                subtitle: 'Push dismissible banners to users\' dashboards',
                onTap: () => context.push('/admin/announcements'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.chat_bubble_text,
                iconColor: AppColors.systemBlue,
                title: 'User Feedback',
                subtitle: 'View bug reports and suggestions from users',
                onTap: () => context.push('/admin/feedback'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Data Health ───────────────────────────────────────────────
            _sectionLabel(context, 'Data Health'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.waveform_path_ecg,
                iconColor: AppColors.brandTeal,
                title: 'Data Health Monitor',
                subtitle: 'Check for data integrity issues across all users',
                onTap: () => context.push('/admin/data-health'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── System Maintenance ────────────────────────────────────────
            _sectionLabel(context, 'System Maintenance'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.trash,
                iconColor: AppColors.systemRed,
                title: 'Clean Old Data',
                subtitle: 'Remove old logs and temporary data',
                onTap: () => _cleanOldData(context, ref),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.archivebox,
                iconColor: AppColors.brandTeal,
                title: 'Database Backup',
                subtitle: 'Create a system-wide data backup',
                onTap: () => _showComingSoon(context, 'Database Backup'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.arrow_down_to_line,
                iconColor: AppColors.tealBlue,
                title: 'Export All Data',
                subtitle: 'Export complete system data (CSV / JSON)',
                onTap: () => _exportAllData(context, ref),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Notifications ─────────────────────────────────────────────
            _sectionLabel(context, 'Notifications'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.bell,
                iconColor: AppColors.systemOrange,
                title: 'System Notifications',
                subtitle: 'Send notifications to all users',
                onTap: () => _showBroadcastSheet(context, ref),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.envelope,
                iconColor: AppColors.systemBlue,
                title: 'Email Templates',
                subtitle: 'Manage system email templates',
                onTap: () => context.push('/admin/email-templates'),
              ),
            ]),
            const SizedBox(height: AppSizes.lg),

            // ── Security & Privacy ────────────────────────────────────────
            _sectionLabel(context, 'Security & Privacy'),
            const SizedBox(height: AppSizes.sm),
            _buildSettingsCard(context, isDark, tiles: [
              _SettingsTileData(
                icon: CupertinoIcons.shield,
                iconColor: AppColors.brandTeal,
                title: 'Security Settings',
                subtitle: 'Configure authentication and security policies',
                onTap: () => _showComingSoon(context, 'Security Settings'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.clock,
                iconColor: AppColors.systemBlue,
                title: 'Activity Logs',
                subtitle: 'View system and admin activity logs',
                onTap: () => _showActivityLogs(context, ref),
              ),
            ]),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.secondaryLabelDark
                  : AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark, {
    required List<_SettingsTileData> tiles,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0,
                thickness: 0.5,
                indent: AppSizes.md + 32 + AppSizes.md,
                endIndent: AppSizes.md,
                color: Theme.of(context).dividerColor,
              ),
            _buildTile(context, isDark, tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, bool isDark, _SettingsTileData data) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: data.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 17),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color:
                  isDark ? AppColors.tertiaryLabelDark : AppColors.systemGray3,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(CupertinoIcons.hammer,
            size: 40, color: AppColors.systemOrange),
        title: const Text('Coming Soon'),
        content: Text(
          '$feature is not yet implemented and will be available in a future update.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final shareRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromCenter(center: const Offset(200, 400), width: 1, height: 1);

    try {
      final csv = await ref
          .read(adminRemoteDataSourceProvider)
          .exportAllTransactionsCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/finmate_export.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Finmate System Data Export',
        sharePositionOrigin: shareRect,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cleanOldData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clean Old Data'),
        content: const Text(
          'This will permanently delete analytics events older than 90 days. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.systemRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRemoteDataSourceProvider).cleanOldData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Old analytics data removed successfully.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBroadcastSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final datasource = ref.read(adminRemoteDataSourceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BroadcastSheet(isDark: isDark, datasource: datasource),
    );
  }

  void _showActivityLogs(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.secondarySystemBackgroundDark
                  : AppColors.systemBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusCard),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: AppSizes.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.tertiaryLabelDark
                          : AppColors.systemGray4,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                    vertical: AppSizes.md,
                  ),
                  child: Text(
                    'Activity Logs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                // Content
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) =>
                        ref.watch(systemAuditLogProvider).when(
                        data: (logs) {
                          if (logs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text,
                                    size: 48,
                                    color: isDark
                                        ? AppColors.secondaryLabelDark
                                        : AppColors.secondaryLabel,
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  Text(
                                    'No activity recorded yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.secondaryLabelDark
                                              : AppColors.secondaryLabel,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final userIds = logs
                              .map((e) => e['user_id'] as String? ?? '')
                              .toSet()
                              .toList();
                          final userIndex = {
                            for (var i = 0; i < userIds.length; i++)
                              userIds[i]: i + 1
                          };

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(AppSizes.pagePadding),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.separatorDark
                                  : AppColors.separator,
                            ),
                            itemBuilder: (context, index) {
                              final entry = logs[index];
                              final action =
                                  entry['action'] as String? ?? 'Unknown Action';
                              final createdAt = entry['created_at'] ?? 'N/A';
                              final userId = entry['user_id'] as String? ?? '';

                              // Format timestamp
                              String formattedTime = 'N/A';
                              try {
                                if (createdAt != 'N/A') {
                                  final dateTime = DateTime.parse(createdAt);
                                  formattedTime =
                                      DateFormat(AppDateFormats.dateTime)
                                          .format(dateTime);
                                }
                              } catch (_) {
                                formattedTime = createdAt;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatEventName(action),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.labelDark.withValues(alpha: 0.9)
                                                : AppColors.label.withValues(alpha: 0.9),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedTime,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.secondaryLabelDark
                                                : AppColors.secondaryLabel,
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry['user_name'] as String? ??
                                          'User #${userIndex[userId] ?? '?'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.tertiaryLabelDark
                                                : AppColors.secondaryLabel,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSizes.pagePadding),
                          itemCount: 5,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LoadingSkeleton(
                                width: 150,
                                height: 12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              LoadingSkeleton(
                                width: 200,
                                height: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              LoadingSkeleton(
                                width: 100,
                                height: 9,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_circle,
                                size: 48,
                                color: AppColors.systemRed,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                'Error loading logs',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.systemRed),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatEventName(String key) =>
    key.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

class _SettingsTileData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTileData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _BroadcastSheet extends StatefulWidget {
  const _BroadcastSheet({required this.isDark, required this.datasource});

  final bool isDark;
  final AdminRemoteDataSource datasource;

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  static const int _maxTitle = 60;
  static const int _maxBody = 200;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await widget.datasource.broadcastNotification(title, body);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Notification sent to all users.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusCard),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.md,
          AppSizes.pagePadding,
          AppSizes.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.tertiaryLabelDark
                      : AppColors.systemGray4,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Send Broadcast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'This notification will be sent to every user.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title field
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => TextField(
                controller: _titleController,
                maxLength: _maxTitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title',
                  counterText: '${_titleController.text.length}/$_maxTitle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Body field
            ListenableBuilder(
              listenable: _bodyController,
              builder: (context, _) => TextField(
                controller: _bodyController,
                maxLength: _maxBody,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  counterText: '${_bodyController.text.length}/$_maxBody',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.systemRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.systemRed,
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.lg),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandTeal, AppColors.tealBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: TextButton(
                  onPressed: _loading ? null : _send,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                  child: _loading
                      ? const LoadingIndicator(color: Colors.white)
                      : const Text(
                          'Send to All Users',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
