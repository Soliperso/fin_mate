import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/admin_providers.dart';

class SystemAnalyticsPage extends ConsumerWidget {
  const SystemAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(systemStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(systemStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(systemStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card - Gradient like dashboard
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.tealBlue, AppColors.primaryTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: AppColors.white,
                        size: 40,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'System Overview',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        'Real-time system statistics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Users Section
                _buildSectionHeader(context, 'Users'),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.people,
                        label: 'Total Users',
                        value: stats.totalUsers.toString(),
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.check_circle,
                        label: 'Active Users',
                        value: stats.activeUsers.toString(),
                        subtitle: '${stats.activeUserPercentage.toStringAsFixed(0)}%',
                        color: AppColors.tealBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _buildStatCard(
                  context,
                  isDark: isDark,
                  icon: Icons.person_add,
                  label: 'New This Month',
                  value: stats.newUsersThisMonth.toString(),
                  color: AppColors.info,
                ),
                const SizedBox(height: AppSizes.xl),

                // Financial Section
                _buildSectionHeader(context, 'Financial Overview'),
                const SizedBox(height: AppSizes.md),
                _buildStatCard(
                  context,
                  isDark: isDark,
                  icon: Icons.account_balance_wallet,
                  label: 'Total Net Worth',
                  value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalNetWorth),
                  color: AppColors.primaryTeal,
                  isLarge: true,
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.arrow_upward,
                        label: 'Total Income',
                        value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalIncome),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.arrow_downward,
                        label: 'Total Expense',
                        value: NumberFormat.compactCurrency(symbol: '\$').format(stats.totalExpense),
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // System Data Section
                _buildSectionHeader(context, 'System Data'),
                const SizedBox(height: AppSizes.md),
                _buildStatCard(
                  context,
                  isDark: isDark,
                  icon: Icons.receipt_long,
                  label: 'Total Transactions',
                  value: NumberFormat.decimalPattern().format(stats.totalTransactions),
                  subtitle: '${stats.averageTransactionsPerUser.toStringAsFixed(1)} avg per user',
                  color: AppColors.tealBlue,
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.account_balance,
                        label: 'Accounts',
                        value: stats.totalAccounts.toString(),
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isDark: isDark,
                        icon: Icons.pie_chart,
                        label: 'Budgets',
                        value: stats.totalBudgets.toString(),
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                _buildStatCard(
                  context,
                  isDark: isDark,
                  icon: Icons.group_work,
                  label: 'Bill Groups',
                  value: stats.totalBillGroups.toString(),
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Failed to load analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(systemStatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
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

  Widget _buildStatCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
    bool isLarge = false,
  }) {
    final cardColor = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.borderLight;

    return Container(
      padding: EdgeInsets.all(isLarge ? AppSizes.lg : AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, color: color, size: isLarge ? 28 : 24),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: isLarge ? AppSizes.md : AppSizes.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isLarge ? 32 : null,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
