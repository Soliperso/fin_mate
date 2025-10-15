import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.tealBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    color: AppColors.white,
                    size: 40,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'System Configuration',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Manage system-wide settings and configurations',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Categories Management
            _buildSectionHeader(context, 'Categories Management'),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.category_outlined,
              title: 'Default Categories',
              subtitle: 'Manage system default transaction categories',
              onTap: () {
                _showComingSoonDialog(context, 'Default Categories Management');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.add_circle_outline,
              title: 'Add Custom Category',
              subtitle: 'Create new transaction categories',
              onTap: () {
                _showComingSoonDialog(context, 'Add Custom Category');
              },
            ),
            const SizedBox(height: AppSizes.xl),

            // Feature Flags
            _buildSectionHeader(context, 'Feature Flags'),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.toggle_on_outlined,
              title: 'Feature Toggles',
              subtitle: 'Enable or disable features for all users',
              onTap: () {
                _showComingSoonDialog(context, 'Feature Toggles');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.science_outlined,
              title: 'Beta Features',
              subtitle: 'Manage experimental features',
              onTap: () {
                _showComingSoonDialog(context, 'Beta Features');
              },
            ),
            const SizedBox(height: AppSizes.xl),

            // System Maintenance
            _buildSectionHeader(context, 'System Maintenance'),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.cleaning_services_outlined,
              title: 'Clean Old Data',
              subtitle: 'Remove old logs and temporary data',
              onTap: () {
                _showComingSoonDialog(context, 'Clean Old Data');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.backup_outlined,
              title: 'Database Backup',
              subtitle: 'Create system-wide data backup',
              onTap: () {
                _showComingSoonDialog(context, 'Database Backup');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.download_outlined,
              title: 'Export All Data',
              subtitle: 'Export complete system data (CSV/JSON)',
              onTap: () {
                _showComingSoonDialog(context, 'Export All Data');
              },
            ),
            const SizedBox(height: AppSizes.xl),

            // Notifications
            _buildSectionHeader(context, 'Notifications'),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.notifications_outlined,
              title: 'System Notifications',
              subtitle: 'Send notifications to all users',
              onTap: () {
                _showComingSoonDialog(context, 'System Notifications');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.email_outlined,
              title: 'Email Templates',
              subtitle: 'Manage system email templates',
              onTap: () {
                _showComingSoonDialog(context, 'Email Templates');
              },
            ),
            const SizedBox(height: AppSizes.xl),

            // Security
            _buildSectionHeader(context, 'Security & Privacy'),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.security_outlined,
              title: 'Security Settings',
              subtitle: 'Configure authentication and security policies',
              onTap: () {
                _showComingSoonDialog(context, 'Security Settings');
              },
            ),
            const SizedBox(height: AppSizes.md),
            _buildSettingCard(
              context,
              isDark: isDark,
              icon: Icons.history_outlined,
              title: 'Activity Logs',
              subtitle: 'View system and admin activity logs',
              onTap: () {
                _showComingSoonDialog(context, 'Activity Logs');
              },
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.construction_outlined,
          size: 48,
          color: AppColors.warning,
        ),
        title: const Text('Coming Soon'),
        content: Text(
          '$feature is not yet implemented.\n\nThis feature will allow admins to manage system-wide configurations.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
