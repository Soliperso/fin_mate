import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../providers/admin_providers.dart';

class UserDetailPage extends ConsumerWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailsProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: userAsync.maybeWhen(
          data: (user) => Text(user.displayName),
          orElse: () => const Text('User Details'),
        ),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) => _buildBody(context, isDark, user, ref),
        loading: () => _buildSkeleton(context, isDark),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Failed to load user',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userDetailsProvider(userId)),
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                      size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, AdminUserEntity user,
      WidgetRef ref) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(
                color: isDark
                    ? AppColors.separatorDark.withValues(alpha: 0.5)
                    : AppColors.separator.withValues(alpha: 0.3),
                width: 0.8,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
                  backgroundImage: user.avatarUrl != null &&
                          user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.initials,
                          style: const TextStyle(
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.labelDark : AppColors.label,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _badge(
                      context,
                      label: user.isAdmin ? 'Admin' : 'User',
                      color:
                          user.isAdmin ? AppColors.brandTeal : AppColors.tealBlue,
                      icon: user.isAdmin
                          ? CupertinoIcons.shield
                          : CupertinoIcons.person,
                    ),
                    _badge(
                      context,
                      label: user.isActive ? 'Active' : 'Inactive',
                      color: user.isActive
                          ? AppColors.systemGreen
                          : AppColors.systemRed,
                      icon: user.isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.xmark_circle_fill,
                    ),
                    _badge(
                      context,
                      label: 'Verified',
                      color: AppColors.systemGreen,
                      icon: CupertinoIcons.checkmark_seal_fill,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Financial Overview ───────────────────────────────────────────
          _buildSectionHeader(
            context,
            'Financial Overview',
            icon: CupertinoIcons.money_dollar,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.money_dollar_circle,
                  iconColor: AppColors.brandTeal,
                  label: 'Net Worth',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.netWorth),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  iconColor: AppColors.systemGreen,
                  label: 'Total Income',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalIncome),
                  valueColor: AppColors.systemGreen,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _statCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  iconColor: AppColors.systemRed,
                  label: 'Total Expenses',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalExpense),
                  valueColor: AppColors.systemRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Account Details ──────────────────────────────────────────────
          _buildSectionHeader(
            context,
            'Account Details',
            icon: CupertinoIcons.person_fill,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(
                color: isDark
                    ? AppColors.separatorDark.withValues(alpha: 0.5)
                    : AppColors.separator.withValues(alpha: 0.3),
                width: 0.8,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                _infoRow(context, isDark,
                    icon: CupertinoIcons.calendar,
                    iconColor: AppColors.tealBlue,
                    label: 'Joined',
                    value: DateFormat('MMM d, yyyy').format(user.createdAt)),
                _divider(context),
                _infoRowTappable(context, isDark,
                    icon: CupertinoIcons.person_badge_plus,
                    iconColor: AppColors.systemBlue,
                    label: 'Role',
                    value: user.role.toUpperCase(),
                    onTap: () => _handleRoleChange(context, ref, user)),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.doc_text,
                    iconColor: AppColors.brandTeal,
                    label: 'Transactions',
                    value: user.transactionCount.toString()),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.clock_fill,
                    iconColor: AppColors.systemBlue,
                    label: 'Last Active',
                    value: 'Today'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Usage Insights ────────────────────────────────────────────────
          _buildSectionHeader(
            context,
            'Usage Insights',
            icon: CupertinoIcons.chart_bar,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.doc_text_fill,
                  iconColor: AppColors.brandTeal,
                  label: 'Avg Monthly Spend',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalExpense / 12),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _insightCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.percent,
                  iconColor: AppColors.systemGreen,
                  label: 'Savings Rate',
                  value: _calculateSavingsRate(user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Admin Actions ────────────────────────────────────────────────
          _buildSectionHeader(
            context,
            'Admin Actions',
            icon: CupertinoIcons.shield_fill,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  icon: CupertinoIcons.lock,
                  label: 'Reset Password',
                  color: AppColors.systemBlue,
                  onTap: () => _handleResetPassword(context, ref, user),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _actionButton(
                  context,
                  icon: CupertinoIcons.doc_text,
                  label: 'View Audit Log',
                  color: AppColors.systemBlue,
                  onTap: () => _handleViewAuditLog(context, ref, user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: user.isActive
                ? _prominentActionButton(
                    context,
                    icon: CupertinoIcons.xmark_circle,
                    label: 'Disable Account',
                    color: AppColors.systemRed,
                    onTap: () => _handleDisableAccount(context, ref, user),
                  )
                : _prominentActionButton(
                    context,
                    icon: CupertinoIcons.checkmark_circle,
                    label: 'Enable Account',
                    color: AppColors.systemGreen,
                    onTap: () => _handleEnableAccount(context, ref, user),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: AppColors.brandTeal,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.labelDark : AppColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final child = Container(
      padding: EdgeInsets.symmetric(
        vertical: isFullWidth ? 10.5 : 12,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 19.5),
                  const SizedBox(height: 7.5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 10,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
      ),
    );

    return child;
  }

  Widget _prominentActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.systemRed,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateSavingsRate(AdminUserEntity user) {
    if (user.totalIncome == 0) return '0%';
    final rate = ((user.totalIncome - user.totalExpense) / user.totalIncome * 100)
        .toStringAsFixed(1);
    return '$rate%';
  }

  Future<void> _handleResetPassword(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Send a password reset email to ${user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.systemBlue,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending password reset email...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await ref.read(resetUserPasswordProvider(user.email).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${user.email}'),
          backgroundColor: AppColors.systemGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleViewAuditLog(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loading Audit Log'),
        content: const SizedBox(
          height: 50,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final auditLog = await ref.read(userAuditLogProvider(user.id).future);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show audit log dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Audit Log'),
          content: auditLog.isEmpty
              ? const Text('No audit log entries found')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    itemCount: auditLog.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = auditLog[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry['action'] ?? 'Unknown Action',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry['created_at'] ?? 'N/A',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading audit log: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleDisableAccount(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Account'),
        content: Text(
          'Are you sure you want to disable ${user.displayName}\'s account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.systemRed,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disabling account...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await ref.read(disableUserAccountProvider(user.id).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName}\'s account has been disabled'),
          backgroundColor: AppColors.systemGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh user details
      ref.invalidate(userDetailsProvider(user.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleEnableAccount(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Account'),
        content: Text(
          'Are you sure you want to enable ${user.displayName}\'s account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.systemGreen,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enabling account...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await ref.read(enableUserAccountProvider(user.id).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName}\'s account has been enabled'),
          backgroundColor: AppColors.systemGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh user details
      ref.invalidate(userDetailsProvider(user.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleRoleChange(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
  ) async {
    final currentRole = user.role.toLowerCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Role',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ListTile(
            leading: Icon(
              CupertinoIcons.person,
              color: AppColors.systemBlue,
            ),
            title: const Text('User'),
            trailing: currentRole == 'user'
                ? const Icon(CupertinoIcons.checkmark, color: AppColors.systemGreen)
                : null,
            onTap: () => _updateRole(context, ref, user, 'user'),
          ),
          ListTile(
            leading: Icon(
              CupertinoIcons.shield,
              color: AppColors.brandTeal,
            ),
            title: const Text('Admin'),
            trailing: currentRole == 'admin'
                ? const Icon(CupertinoIcons.checkmark, color: AppColors.systemGreen)
                : null,
            onTap: () => _updateRole(context, ref, user, 'admin'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _updateRole(
    BuildContext context,
    WidgetRef ref,
    AdminUserEntity user,
    String newRole,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    // If role is unchanged, do nothing
    if (user.role.toLowerCase() == newRole.toLowerCase()) return;

    // Show loading indicator
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating role...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await ref.read(updateUserRoleProvider((userId: user.id, role: newRole)).future);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName}\'s role changed to ${newRole.toUpperCase()}'),
          backgroundColor: AppColors.systemGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh user details
      ref.invalidate(userDetailsProvider(user.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.systemRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _badge(BuildContext context,
      {required String label,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 13.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.labelDark
                      : AppColors.label,
                  letterSpacing: -0.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowTappable(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 13.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.labelDark
                        : AppColors.label,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.pencil,
              size: 12,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _statCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.25),
          width: 0.7,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 16.5),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: valueColor ??
                      (isDark
                          ? AppColors.labelDark
                          : AppColors.label),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _insightCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.25),
          width: 0.7,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: iconColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                LoadingSkeleton(
                    width: 84,
                    height: 84,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull)),
                const SizedBox(height: 18),
                LoadingSkeleton(
                    width: 135,
                    height: 14,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 6),
                LoadingSkeleton(
                    width: 180,
                    height: 10,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 6),
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 6),
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Financial overview skeleton
          LoadingSkeleton(
              width: 90,
              height: 11,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          LoadingSkeleton(
              height: 95,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: 9),
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: 24),

          // Account details skeleton
          LoadingSkeleton(
              width: 90,
              height: 11,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          LoadingSkeleton(
              height: 135,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: 24),

          // Usage insights skeleton
          LoadingSkeleton(
              width: 90,
              height: 11,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: 9),
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: 24),

          // Admin actions skeleton
          LoadingSkeleton(
              width: 90,
              height: 11,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 81,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: 9),
            Expanded(
                child: LoadingSkeleton(
                    height: 81,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: 9),
          LoadingSkeleton(
              height: 42,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
        ],
      ),
    );
  }
}
