import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';

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
                onTap: () => _showComingSoon(context, 'Default Categories'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.add_circled,
                iconColor: AppColors.tealBlue,
                title: 'Add Custom Category',
                subtitle: 'Create new transaction categories',
                onTap: () => _showComingSoon(context, 'Add Custom Category'),
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
                onTap: () => _showComingSoon(context, 'Feature Toggles'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.lab_flask,
                iconColor: AppColors.systemOrange,
                title: 'Beta Features',
                subtitle: 'Manage experimental features',
                onTap: () => _showComingSoon(context, 'Beta Features'),
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
                onTap: () => _showComingSoon(context, 'Clean Old Data'),
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
                onTap: () => _showComingSoon(context, 'Export All Data'),
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
                onTap: () => _showComingSoon(context, 'System Notifications'),
              ),
              _SettingsTileData(
                icon: CupertinoIcons.envelope,
                iconColor: AppColors.systemBlue,
                title: 'Email Templates',
                subtitle: 'Manage system email templates',
                onTap: () => _showComingSoon(context, 'Email Templates'),
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
                onTap: () => _showComingSoon(context, 'Activity Logs'),
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
              color: isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel,
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

  Widget _buildTile(
      BuildContext context, bool isDark, _SettingsTileData data) {
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
              color: isDark
                  ? AppColors.tertiaryLabelDark
                  : AppColors.systemGray3,
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
}

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
