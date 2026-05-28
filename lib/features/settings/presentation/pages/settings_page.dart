import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/settings_providers.dart';
import '../../../../core/providers/display_format_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsOperationsProvider);
    final displayFormat = ref.watch(displayFormatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: settingsState.when(
        loading: () => const SkeletonList(itemCount: 6, itemHeight: 56),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.md),
              Text(
                'settings.failedToLoad'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.md),
              FilledButton(
                onPressed: () {
                  // ignore: unused_result
                  ref.refresh(settingsOperationsProvider);
                },
                child: Text('common.retry'.tr()),
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
              // ── Finances ──────────────────────────────────────────────
              _sectionLabel(context, 'settings.finances'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.repeat,
                  title: 'settings.recurringTransactions'.tr(),
                  subtitle: 'settings.recurringTransactionsSub'.tr(),
                  onTap: () => context.push('/recurring-transactions'),
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Display ───────────────────────────────────────────────
              _sectionLabel(context, 'settings.display'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.moon,
                  title: 'settings.theme'.tr(),
                  subtitle: 'settings.lightOrDark'.tr(),
                  onTap: () => context.push('/settings/display?section=theme'),
                  trailingText:
                      settings?.themeMode ?? 'settings.themeSystem'.tr(),
                ),
                _buildDivider(context, isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.money_dollar,
                  title: 'settings.currency'.tr(),
                  subtitle: 'settings.currencyDefault'.tr(),
                  onTap: () =>
                      context.push('/settings/display?section=currency'),
                  trailingText: displayFormat.currencyCode,
                ),
                _buildDivider(context, isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.calendar,
                  title: 'settings.dateFormat'.tr(),
                  subtitle: 'settings.dateFormatDisplay'.tr(),
                  onTap: () =>
                      context.push('/settings/display?section=dateformat'),
                  trailingText: displayFormat.dateFormat,
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Notifications ─────────────────────────────────────────
              _sectionLabel(context, 'settings.notifications'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.bell,
                  title: 'settings.notificationPreferences'.tr(),
                  subtitle: 'settings.notificationPreferencesSub'.tr(),
                  onTap: () => context.push('/settings/notifications'),
                ),
              ]),
              const SizedBox(height: AppSizes.lg),

              // ── Data & Privacy ────────────────────────────────────────
              _sectionLabel(context, 'settings.dataPrivacy'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(context, isDark, children: [
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_down_to_line,
                  title: 'settings.exportData'.tr(),
                  subtitle: 'settings.exportDataSub'.tr(),
                  onTap: () => context.push('/settings/data-privacy'),
                ),
                _buildDivider(context, isDark),
                _buildSettingsTile(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.hand_raised,
                  title: 'settings.privacySecurity'.tr(),
                  subtitle: 'settings.privacySecuritySub'.tr(),
                  onTap: () => context.push('/profile/security'),
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

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }
}
