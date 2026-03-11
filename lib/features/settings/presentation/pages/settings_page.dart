import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsOperationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.md),
              Text(
                'Failed to load settings',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(settingsOperationsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Display ───────────────────────────────────────────────
              _sectionLabel(context, 'Display'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.moon,
                  title: 'Theme',
                  subtitle: 'Light or dark theme',
                  onTap: () => context.push('/settings/display'),
                  trailingText: settings?.themeMode ?? 'System',
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.money_dollar,
                  title: 'Currency',
                  subtitle: 'Default currency format',
                  onTap: () => context.push('/settings/display'),
                  trailingText: 'USD',
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.calendar,
                  title: 'Date Format',
                  subtitle: 'How dates are displayed',
                  onTap: () => context.push('/settings/display'),
                  trailingText: 'MM/DD/YYYY',
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Notifications ─────────────────────────────────────────
              _sectionLabel(context, 'Notifications'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.bell,
                  title: 'Notification Preferences',
                  subtitle: 'Manage what you get notified about',
                  onTap: () => context.push('/settings/notifications'),
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Data & Privacy ────────────────────────────────────────
              _sectionLabel(context, 'Data & Privacy'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_down_to_line,
                  title: 'Export Data',
                  subtitle: 'Download your financial data',
                  onTap: () => context.push('/settings/data-privacy'),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.hand_raised,
                  title: 'Privacy & Security',
                  subtitle: 'Account deletion and data privacy',
                  onTap: () => context.push('/settings/data-privacy'),
                ),
              ]),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isDark,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
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
                color: AppColors.systemGray5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.secondaryLabel, size: 17),
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
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryLabel,
                    ),
              ),
              const SizedBox(width: AppSizes.xs),
            ],
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.systemGray3),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      color: isDark ? AppColors.separatorDark : AppColors.separator,
    );
  }
}
