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
        data: (user) => _buildBody(context, isDark, user),
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

  Widget _buildBody(
      BuildContext context, bool isDark, AdminUserEntity user) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: AppSizes.sm),
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Account Info ─────────────────────────────────────────────────
          _sectionLabel(context, 'Account Info'),
          const SizedBox(height: AppSizes.sm),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                _infoRow(context, isDark,
                    icon: CupertinoIcons.calendar,
                    iconColor: AppColors.tealBlue,
                    label: 'Joined',
                    value: DateFormat('MMM d, yyyy').format(user.createdAt)),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.person_badge_plus,
                    iconColor: AppColors.systemBlue,
                    label: 'Role',
                    value: user.role.toUpperCase()),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.doc_text,
                    iconColor: AppColors.brandTeal,
                    label: 'Transactions',
                    value: user.transactionCount.toString()),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Financials ───────────────────────────────────────────────────
          _sectionLabel(context, 'Financials'),
          const SizedBox(height: AppSizes.sm),
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
          const SizedBox(height: AppSizes.sm),
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
              const SizedBox(width: AppSizes.sm),
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
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context,
      {required String label,
      required Color color,
      required IconData icon}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
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
          horizontal: AppSizes.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                ),
          ),
        ],
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
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: valueColor ??
                      (isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                LoadingSkeleton(
                    width: 80,
                    height: 80,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull)),
                const SizedBox(height: AppSizes.md),
                LoadingSkeleton(
                    width: 160,
                    height: 16,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: AppSizes.sm),
                LoadingSkeleton(
                    width: 220,
                    height: 12,
                    borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          LoadingSkeleton(
              width: 80,
              height: 12,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          LoadingSkeleton(
              height: 140,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: AppSizes.lg),
          LoadingSkeleton(
              width: 80,
              height: 12,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 100,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 100,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard))),
          ]),
        ],
      ),
    );
  }
}
