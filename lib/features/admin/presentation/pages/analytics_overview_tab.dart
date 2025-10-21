import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../providers/admin_providers.dart';

class AnalyticsOverviewTab extends ConsumerWidget {
  const AnalyticsOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(systemStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Users Section
            _buildSectionHeader(context, 'Users'),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.people,
                    label: 'Total Users',
                    value: stats.totalUsers.toString(),
                    iconColor: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.check_circle,
                    label: 'Active Users',
                    value: stats.activeUsers.toString(),
                    subtitle: '${stats.activeUserPercentage.toStringAsFixed(0)}%',
                    iconColor: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            _buildCleanStatCard(
              context,
              icon: Icons.person_add,
              label: 'New This Month',
              value: stats.newUsersThisMonth.toString(),
              iconColor: AppColors.primaryTeal,
            ),
            const SizedBox(height: AppSizes.xl),

            // Financial Section
            _buildSectionHeader(context, 'Financial Overview'),
            const SizedBox(height: AppSizes.md),
            _buildPremiumNetWorthCard(
              context,
              icon: Icons.account_balance_wallet,
              label: 'Total Net Worth',
              value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalNetWorth),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.arrow_upward,
                    label: 'Total Income',
                    value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalIncome),
                    iconColor: AppColors.success,
                    valueColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.arrow_downward,
                    label: 'Total Expense',
                    value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalExpense),
                    iconColor: AppColors.error,
                    valueColor: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),

            // System Data Section
            _buildSectionHeader(context, 'System Data'),
            const SizedBox(height: AppSizes.md),
            _buildCleanStatCard(
              context,
              icon: Icons.receipt_long,
              label: 'Total Transactions',
              value: NumberFormat.decimalPattern().format(stats.totalTransactions),
              subtitle: '${stats.averageTransactionsPerUser.toStringAsFixed(1)} avg per user',
              iconColor: AppColors.primaryTeal,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.account_balance,
                    label: 'Accounts',
                    value: stats.totalAccounts.toString(),
                    iconColor: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _buildCleanStatCard(
                    context,
                    icon: Icons.pie_chart,
                    label: 'Budgets',
                    value: stats.totalBudgets.toString(),
                    iconColor: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            _buildCleanStatCard(
              context,
              icon: Icons.group_work,
              label: 'Bill Groups',
              value: stats.totalBillGroups.toString(),
              iconColor: AppColors.primaryTeal,
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: EmptyStateCard(
            icon: Icons.error_outline,
            title: 'Failed to Load Analytics',
            message: 'Unable to load system analytics. Please try again.',
            backgroundColor: AppColors.error,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildPremiumNetWorthCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryTeal, AppColors.tealBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Card(
      child: SizedBox(
        height: 140,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
