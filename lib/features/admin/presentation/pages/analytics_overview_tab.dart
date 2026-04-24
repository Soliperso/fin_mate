import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/admin_providers.dart';

class AnalyticsOverviewTab extends ConsumerWidget {
  const AnalyticsOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(systemStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Users — 3-column compact tiles ───────────────────────────
            _sectionLabel(context, 'Users', isDark),
            const SizedBox(height: AppSizes.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.person_2,
                      iconColor: AppColors.brandTeal,
                      label: 'Total Users',
                      value: stats.totalUsers.toString(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.checkmark_circle_fill,
                      iconColor: AppColors.systemGreen,
                      label: 'Active',
                      value: stats.activeUsers.toString(),
                      subtitle: '${stats.activeUserPercentage.toStringAsFixed(0)}% of total',
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.person_add,
                      iconColor: AppColors.tealBlue,
                      label: 'New This Month',
                      value: stats.newUsersThisMonth.toString(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Financial Overview — hero + 2-col ─────────────────────────
            _sectionLabel(context, 'Financial Overview', isDark),
            const SizedBox(height: AppSizes.sm),
            _heroCard(
              context,
              icon: CupertinoIcons.money_dollar_circle,
              label: 'Total Net Worth',
              value: NumberFormat.compactCurrency(symbol: '\$')
                  .format(stats.totalNetWorth),
            ),
            const SizedBox(height: AppSizes.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _financialCard(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.arrow_up_circle_fill,
                      iconColor: AppColors.systemGreen,
                      label: 'Income',
                      value: NumberFormat.compactCurrency(symbol: '\$')
                          .format(stats.totalIncome),
                      valueColor: AppColors.systemGreen,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _financialCard(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.arrow_down_circle_fill,
                      iconColor: AppColors.systemRed,
                      label: 'Expenses',
                      value: NumberFormat.compactCurrency(symbol: '\$')
                          .format(stats.totalExpense),
                      valueColor: AppColors.systemRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── System Data — 3-column compact tiles ──────────────────────
            _sectionLabel(context, 'System Data', isDark),
            const SizedBox(height: AppSizes.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      iconColor: AppColors.brandTeal,
                      label: 'Transactions',
                      value: NumberFormat.compact()
                          .format(stats.totalTransactions),
                      subtitle:
                          '${stats.averageTransactionsPerUser.toStringAsFixed(1)} avg/user',
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.creditcard,
                      iconColor: AppColors.systemBlue,
                      label: 'Accounts',
                      value: stats.totalAccounts.toString(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _miniTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.chart_pie_fill,
                      iconColor: AppColors.systemOrange,
                      label: 'Budgets',
                      value: stats.totalBudgets.toString(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Quick Actions — 2-column tiles ────────────────────────────
            _sectionLabel(context, 'Quick Actions', isDark),
            const SizedBox(height: AppSizes.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _quickActionTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.person_2_fill,
                      iconColor: AppColors.brandTeal,
                      label: 'Manage Users',
                      description: 'View, search and edit accounts',
                      onTap: () => context.push('/admin/users'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _quickActionTile(
                      context,
                      isDark: isDark,
                      icon: CupertinoIcons.gear_alt_fill,
                      iconColor: AppColors.systemBlue,
                      label: 'System Settings',
                      description: 'Flags, maintenance and logs',
                      onTap: () => context.push('/admin/settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
      loading: () => _buildSkeleton(context),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: EmptyStateCard(
            icon: CupertinoIcons.exclamationmark_circle,
            title: 'Failed to Load Analytics',
            message: 'Unable to load system analytics. Please try again.',
            backgroundColor: AppColors.error,
          ),
        ),
      ),
    );
  }

  // ── Hero gradient card ─────────────────────────────────────────────────────

  Widget _heroCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandTeal, AppColors.tealBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
          ),
        ],
      ),
    );
  }

  // ── Compact 3-column mini tile ─────────────────────────────────────────────

  Widget _miniTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: isDark
            ? null
            : Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(height: AppSizes.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Financial card (2-column, tighter than before) ─────────────────────────

  Widget _financialCard(
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: isDark
            ? null
            : Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: AppSizes.sm),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: valueColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Quick action tile (2-column vertical) ──────────────────────────────────

  Widget _quickActionTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: isDark
              ? null
              : Border.all(color: AppColors.separator, width: 0.5),
          boxShadow: AppColors.cardShadow(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    fontSize: 11,
                  ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label with horizontal rule ─────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text, bool isDark) {
    final ruleColor = isDark ? AppColors.separatorDark : AppColors.separator;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Container(height: 0.5, color: ruleColor)),
      ],
    );
  }

  // ── Loading skeleton ────────────────────────────────────────────────────────

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
              width: 60, height: 12, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: AppSizes.lg),
          LoadingSkeleton(
              width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          LoadingSkeleton(
              height: 110,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: AppSizes.sm),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: AppSizes.lg),
          LoadingSkeleton(
              width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
        ],
      ),
    );
  }
}
