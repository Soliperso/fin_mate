import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings page
            },
          ),
        ],
      ),
      body: profileState.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profileState.errorMessage != null && profile == null
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
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.credit_card,
                                  title: 'Payment Methods',
                                  subtitle: 'Manage your linked accounts',
                                  onTap: () {},
                                ),
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
                                  icon: Icons.dark_mode_outlined,
                                  title: 'Appearance',
                                  subtitle: 'Light or dark theme',
                                  onTap: () {},
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
                                  title: 'Privacy Policy',
                                  subtitle: 'Read our privacy policy',
                                  onTap: () {},
                                ),
                                _buildDivider(),
                                _buildSettingsTile(
                                  icon: Icons.description_outlined,
                                  title: 'Terms of Service',
                                  subtitle: 'Read our terms',
                                  onTap: () {},
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

                            // Admin Section (only visible for admins)
                            if (profile?.isAdmin == true) ...[
                              Text(
                                'Admin',
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
                                    icon: Icons.people_outline,
                                    title: 'User Management',
                                    subtitle: 'View and manage all users',
                                    onTap: () => context.push('/admin/users'),
                                  ),
                                  _buildDivider(),
                                  _buildSettingsTile(
                                    icon: Icons.analytics_outlined,
                                    title: 'System Analytics',
                                    subtitle: 'View system-wide statistics',
                                    onTap: () => context.push('/admin/analytics'),
                                  ),
                                  _buildDivider(),
                                  _buildSettingsTile(
                                    icon: Icons.settings_outlined,
                                    title: 'System Settings',
                                    subtitle: 'Configure system parameters',
                                    onTap: () => context.push('/admin/settings'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.lg),
                            ],

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
          border: Border.all(color: AppColors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
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
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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

  Widget _buildSettingsTile({
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
