import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            // ── Users ────────────────────────────────────────────────────
            _sectionLabel(context, 'Users'),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _statCard(
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
                  child: _statCard(
                    context,
                    isDark: isDark,
                    icon: CupertinoIcons.checkmark_circle_fill,
                    iconColor: AppColors.systemGreen,
                    label: 'Active Users',
                    value: stats.activeUsers.toString(),
                    badge: '${stats.activeUserPercentage.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            _statCard(
              context,
              isDark: isDark,
              icon: CupertinoIcons.person_add,
              iconColor: AppColors.tealBlue,
              label: 'New This Month',
              value: stats.newUsersThisMonth.toString(),
              fullWidth: true,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Financial Overview ────────────────────────────────────────
            _sectionLabel(context, 'Financial Overview'),
            const SizedBox(height: AppSizes.sm),
            _heroCard(
              context,
              icon: CupertinoIcons.money_dollar_circle,
              label: 'Total Net Worth',
              value: NumberFormat.compactCurrency(symbol: '\$')
                  .format(stats.totalNetWorth),
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
                    label: 'Income',
                    value: NumberFormat.compactCurrency(symbol: '\$')
                        .format(stats.totalIncome),
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
                    label: 'Expenses',
                    value: NumberFormat.compactCurrency(symbol: '\$')
                        .format(stats.totalExpense),
                    valueColor: AppColors.systemRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // ── System Data ───────────────────────────────────────────────
            _sectionLabel(context, 'System Data'),
            const SizedBox(height: AppSizes.sm),
            _statCard(
              context,
              isDark: isDark,
              icon: CupertinoIcons.arrow_right_arrow_left,
              iconColor: AppColors.brandTeal,
              label: 'Total Transactions',
              value: NumberFormat.decimalPattern()
                  .format(stats.totalTransactions),
              badge:
                  '${stats.averageTransactionsPerUser.toStringAsFixed(1)} avg/user',
              fullWidth: true,
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _statCard(
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
                  child: _statCard(
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

  // ── Hero gradient card (net worth) ─────────────────────────────────────────

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSizes.xs),
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

  // ── Stat card ──────────────────────────────────────────────────────────────

  Widget _statCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? badge,
    Color? valueColor,
    bool fullWidth = false,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
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
                  color: valueColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────

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
          const SizedBox(height: AppSizes.sm),
          LoadingSkeleton(
              height: 100,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: AppSizes.lg),
          LoadingSkeleton(
              width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.sm),
          LoadingSkeleton(
              height: 120,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
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
