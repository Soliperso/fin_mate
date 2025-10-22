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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Settings Section
              _buildSectionTitle(context, 'Display'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Theme',
                    subtitle: 'Light or dark theme',
                    onTap: () => context.push('/settings/display'),
                    trailing: Text(
                      settings?.themeMode ?? 'System',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    icon: Icons.attach_money,
                    title: 'Currency',
                    subtitle: 'Default currency format',
                    onTap: () => context.push('/settings/display'),
                    trailing: const Text('USD'),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Date Format',
                    subtitle: 'How dates are displayed',
                    onTap: () => context.push('/settings/display'),
                    trailing: const Text('MM/DD/YYYY'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Notification Settings Section
              _buildSectionTitle(context, 'Notifications'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Notification Preferences',
                    subtitle: 'Manage what you get notified about',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Data & Privacy Section
              _buildSectionTitle(context, 'Data & Privacy'),
              const SizedBox(height: AppSizes.sm),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.download,
                    title: 'Export Data',
                    subtitle: 'Download your financial data',
                    onTap: () => context.push('/settings/data-privacy'),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Account deletion and data privacy',
                    onTap: () => context.push('/settings/data-privacy'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryTeal,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md * 3),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.lightGray.withValues(alpha: 0.5),
      ),
    );
  }
}
