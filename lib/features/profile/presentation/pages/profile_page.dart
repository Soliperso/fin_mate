import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings, size: 22),
            onPressed: () => context.push('/settings'),
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
                      const Icon(CupertinoIcons.exclamationmark_circle,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSizes.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg),
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
                  color: AppColors.brandTeal,
                  onRefresh: () async {
                    await ref
                        .read(currentUserProfileProvider.notifier)
                        .loadProfile();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── iOS Profile Header ─────────────────────────────
                        const SizedBox(height: AppSizes.lg),
                        Center(
                          child: Column(
                            children: [
                              _buildProfilePicture(profile),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                profile?.displayName ?? 'User',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                profile?.email ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.secondaryLabel,
                                    ),
                              ),
                              if (profile?.isAdmin == true) ...[
                                const SizedBox(height: AppSizes.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md,
                                    vertical: AppSizes.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandTeal
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(CupertinoIcons.shield,
                                          size: 14, color: AppColors.brandTeal),
                                      SizedBox(width: AppSizes.xs),
                                      Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.brandTeal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSizes.md),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/profile/edit'),
                                icon:
                                    const Icon(CupertinoIcons.pencil, size: 16),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandTeal,
                                  side: const BorderSide(
                                      color: AppColors.brandTeal),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),

                        // ── Account ───────────────────────────────────────
                        _sectionLabel(context, 'Account'),
                        const SizedBox(height: AppSizes.sm),
                        _buildSettingsCard(context, isDark, children: [
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.person,
                            title: 'Personal Information',
                            subtitle: 'Update your name, email, and phone',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.lock,
                            title: 'Security',
                            subtitle: 'Password, biometric, 2FA',
                            onTap: () => context.push('/profile/security'),
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.money_dollar_circle,
                            title: 'Savings Goals',
                            subtitle: 'Track and manage your savings goals',
                            onTap: () => context.push('/goals'),
                          ),
                        ]),
                        const SizedBox(height: AppSizes.lg),

                        // ── Preferences ───────────────────────────────────
                        _sectionLabel(context, 'Preferences'),
                        const SizedBox(height: AppSizes.sm),
                        _buildSettingsCard(context, isDark, children: [
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.bell,
                            title: 'Notifications',
                            subtitle: 'Manage notification preferences',
                            onTap: () {},
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.moon,
                            title: 'Appearance',
                            subtitle: _getThemeModeLabel(themeMode),
                            onTap: () => _showThemeDialog(context, ref),
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.globe,
                            title: 'Language',
                            subtitle: 'English (US)',
                            onTap: () {},
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.money_dollar,
                            title: 'Currency',
                            subtitle: profile?.currency ?? 'USD',
                            onTap: () => context.push('/profile/edit'),
                          ),
                        ]),
                        const SizedBox(height: AppSizes.lg),

                        // ── Support ───────────────────────────────────────
                        _sectionLabel(context, 'Support'),
                        const SizedBox(height: AppSizes.sm),
                        _buildSettingsCard(context, isDark, children: [
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.question_circle,
                            title: 'Help Center',
                            subtitle: 'FAQs and support articles',
                            onTap: () {},
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.hand_raised,
                            title: 'Legal & Compliance',
                            subtitle: 'View privacy policy and terms',
                            onTap: () => context.push('/profile/legal'),
                          ),
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            context: context,
                            icon: CupertinoIcons.info_circle,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: AppSizes.lg),

                        // ── Log Out ───────────────────────────────────────
                        _buildSettingsCard(context, isDark, children: [
                          InkWell(
                            onTap: () => _showLogoutDialog(context, ref),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSizes.md, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.square_arrow_left,
                                      color: AppColors.systemRed, size: 18),
                                  SizedBox(width: AppSizes.sm),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: AppColors.systemRed,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      letterSpacing: -0.41,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildProfilePicture(dynamic profile) {
    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(profile.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.brandTeal,
      child: Text(
        profile?.initials ?? 'U',
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
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
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.labelDark, size: 17),
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
                          color: const Color(0xFF9E9EA3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXl),
            topRight: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.systemGray4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.light,
              title: 'Light',
              subtitle: 'Use light theme',
              icon: CupertinoIcons.sun_min,
              isSelected: currentThemeMode == ThemeMode.light,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.dark,
              title: 'Dark',
              subtitle: 'Use dark theme',
              icon: CupertinoIcons.moon,
              isSelected: currentThemeMode == ThemeMode.dark,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              themeMode: ThemeMode.system,
              title: 'System default',
              subtitle: 'Follow system settings',
              icon: CupertinoIcons.device_phone_portrait,
              isSelected: currentThemeMode == ThemeMode.system,
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppSizes.md),
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
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.brandTeal : AppColors.secondaryLabel,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.brandTeal : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.secondaryLabel),
      ),
      trailing: isSelected
          ? const Icon(CupertinoIcons.checkmark_circle_fill,
              color: AppColors.brandTeal)
          : null,
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
        if (context.mounted) Navigator.pop(context);
      },
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
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  showErrorDialog(context, 'Failed to sign out: $e');
                }
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.systemRed),
            ),
          ),
        ],
      ),
    );
  }
}
