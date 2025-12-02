import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/theme_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.profile;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: profile == null && profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null && profileState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSizes.md),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                        child: Text(
                          profileState.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(currentUserProfileProvider.notifier)
                            .loadProfile(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(currentUserProfileProvider.notifier)
                        .loadProfile();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryTeal,
                              AppColors.tealBlue
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(AppSizes.radiusXl),
                            bottomRight: Radius.circular(AppSizes.radiusXl),
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Column(
                          children: [
                            // Profile Picture
                            _buildProfilePicture(profile),
                            const SizedBox(height: AppSizes.md),
                            // User Name
                            Text(
                              profile?.displayName ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            // User Email
                            Text(
                              profile?.email ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            // Admin Badge
                            if (profile?.isAdmin == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md,
                                  vertical: AppSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                  border: Border.all(
                                    color: AppColors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: AppSizes.xs),
                                    Text(
                                      'Admin',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSizes.lg),
                            // Edit Profile Button
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push('/profile/edit');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.white,
                                side: const BorderSide(
                                    color: AppColors.white, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusMd),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Account Section
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSettingsCard(
                              context,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.person_outline,
                                  title: 'Personal Information',
                                  subtitle: 'Update your name, email, and phone',
                                  onTap: () => context.push('/profile/edit'),
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.lock_outline,
                                  title: 'Security',
                                  subtitle: 'Password, biometric, 2FA',
                                  onTap: () => context.push('/profile/security'),
                                ),
                                // [MVP: Subscription & Payment - Commented out for initial launch]
                                // All features are free during beta testing
                                // _buildDivider(),
                                // _buildSettingsTile(
                                //   icon: Icons.workspace_premium,
                                //   title: 'Subscription',
                                //   subtitle: 'Manage your premium subscription',
                                //   onTap: () => context.push('/profile/subscription'),
                                // ),
                                // _buildDivider(),
                                // _buildSettingsTile(
                                //   icon: Icons.credit_card,
                                //   title: 'Payment Methods',
                                //   subtitle: 'Manage your linked accounts',
                                //   onTap: () {},
                                // ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.lg),

                            // Preferences Section
                            Text(
                              'Preferences',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSettingsCard(
                              context,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.notifications_none,
                                  title: 'Notifications',
                                  subtitle: 'Manage notification preferences',
                                  onTap: () {},
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  context: context,
                                  icon: Icons.dark_mode_outlined,
                                  title: 'Appearance',
                                  subtitle: _getThemeModeLabel(themeMode),
                                  onTap: () => _showThemeDialog(context, ref),
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.language,
                                  title: 'Language',
                                  subtitle: 'English (US)',
                                  onTap: () {},
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.attach_money,
                                  title: 'Currency',
                                  subtitle: profile?.currency ?? 'USD',
                                  onTap: () => context.push('/profile/edit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.lg),

                            // Support Section
                            Text(
                              'Support',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSettingsCard(
                              context,
                              children: [
                                _buildSettingsTile(
                                  icon: Icons.help_outline,
                                  title: 'Help Center',
                                  subtitle: 'FAQs and support articles',
                                  onTap: () {},
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'Legal & Compliance',
                                  subtitle: 'View privacy policy and terms',
                                  onTap: () => context.push('/profile/legal'),
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.info_outline,
                                  title: 'About',
                                  subtitle: 'Version 1.0.0',
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.lg),

                            // [MVP: Admin Section - Commented out for initial launch]
                            // Admin routes are disabled to prevent navigation errors
                            // Uncomment after enabling admin routes in router.dart
                            // if (profile?.isAdmin == true) ...[
                            //   Text(
                            //     'Admin',
                            //     style: Theme.of(context)
                            //         .textTheme
                            //         .titleMedium
                            //         ?.copyWith(
                            //           fontWeight: FontWeight.w600,
                            //           color: AppColors.textSecondary,
                            //         ),
                            //   ),
                            //   const SizedBox(height: AppSizes.sm),
                            //   _buildSettingsCard(
                            //     context,
                            //     children: [
                            //       _buildSettingsTile(
                            //         icon: Icons.people_outline,
                            //         title: 'User Management',
                            //         subtitle: 'View and manage all users',
                            //         onTap: () => context.push('/admin/users'),
                            //       ),
                            //       _buildDivider(),
                            //       _buildSettingsTile(
                            //         icon: Icons.analytics_outlined,
                            //         title: 'System Analytics',
                            //         subtitle: 'View system-wide statistics',
                            //         onTap: () => context.push('/admin/analytics'),
                            //       ),
                            //       _buildDivider(),
                            //       _buildSettingsTile(
                            //         icon: Icons.settings_outlined,
                            //         title: 'System Settings',
                            //         subtitle: 'Configure system parameters',
                            //         onTap: () => context.push('/admin/settings'),
                            //       ),
                            //     ],
                            //   ),
                            //   const SizedBox(height: AppSizes.lg),
                            // ],

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showLogoutDialog(context, ref),
                                icon: const Icon(Icons.logout,
                                    color: AppColors.error),
                                label: const Text(
                                  'Log Out',
                                  style: TextStyle(color: AppColors.error),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusMd),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.xl),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfilePicture(dynamic profile) {
    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2), width: 2),
          image: DecorationImage(
            image: NetworkImage(profile.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(
        child: Text(
          profile?.initials ?? 'U',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    BuildContext? context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
      trailing: const Icon(
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

  String _getThemeModeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXl),
            topRight: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white.withValues(alpha: 0.3)
                    : AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Row(
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            // Options
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.light,
              title: 'Light',
              subtitle: 'Use light theme',
              icon: Icons.light_mode,
              isSelected: currentThemeMode == ThemeMode.light,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.dark,
              title: 'Dark',
              subtitle: 'Use dark theme',
              icon: Icons.dark_mode,
              isSelected: currentThemeMode == ThemeMode.dark,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.system,
              title: 'System default',
              subtitle: 'Follow system settings',
              icon: Icons.settings_suggest,
              isSelected: currentThemeMode == ThemeMode.system,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.md),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode themeMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.tealLight : AppColors.primaryTeal;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : (isDark ? AppColors.white.withValues(alpha: 0.6) : AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? primaryColor : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.white.withValues(alpha: 0.6) : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: primaryColor)
          : null,
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md * 3),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.lightGray.withValues(alpha: 0.5),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ErrorSnackbar.show(
                    context,
                    message: 'Failed to sign out: $e',
                  );
                }
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
