import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/net_worth_card.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/net_worth_trend_chart.dart';
import '../widgets/money_health_score.dart';
import '../widgets/upcoming_bills_card.dart';
import '../widgets/quick_action_button.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    // Extract initials from user's full name
    String getInitials() {
      if (user?.fullName == null || user?.fullName?.isEmpty == true) {
        return 'U';
      }
      final names = user!.fullName!.trim().split(' ');
      if (names.length == 1) {
        return names[0][0].toUpperCase();
      }
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications page
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                backgroundColor: AppColors.emeraldGreen,
                radius: 18,
                child: Text(
                  getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Net Worth Card
                NetWorthCard(
                  netWorth: stats.netWorth,
                  changePercentage: stats.netWorthChangePercentage,
                  isPositive: stats.isNetWorthPositive,
                ),
                const SizedBox(height: AppSizes.md),

                // Money Health Score
                MoneyHealthScore(score: stats.moneyHealthScore),
                const SizedBox(height: AppSizes.lg),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.add,
                        label: 'Add Expense',
                        color: AppColors.error,
                        onTap: () {
                          context.go('/transactions/add?type=expense');
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.arrow_upward,
                        label: 'Add Income',
                        color: AppColors.success,
                        onTap: () {
                          context.go('/transactions/add?type=income');
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.receipt,
                        label: 'Split Bill',
                        color: AppColors.slateBlue,
                        onTap: () {
                          context.go('/bills');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // Cash Flow Card
                CashFlowCard(
                  income: stats.monthlyIncome,
                  expenses: stats.monthlyExpenses,
                ),
                const SizedBox(height: AppSizes.md),

                // Cash Flow Chart
                Consumer(
                  builder: (context, ref, _) {
                    final flowDataAsync = ref.watch(monthlyFlowDataProvider);
                    return flowDataAsync.when(
                      data: (flowData) {
                        if (flowData.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            CashFlowChart(flowData: flowData),
                            const SizedBox(height: AppSizes.md),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),

                // Net Worth Trend Chart
                Consumer(
                  builder: (context, ref, _) {
                    final snapshotsAsync = ref.watch(netWorthSnapshotsProvider);
                    return snapshotsAsync.when(
                      data: (snapshots) {
                        if (snapshots.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            NetWorthTrendChart(snapshots: snapshots),
                            const SizedBox(height: AppSizes.md),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),

                // Upcoming Bills
                UpcomingBillsCard(
                  bills: stats.upcomingBills
                      .map((bill) => {
                            'name': bill.name,
                            'amount': bill.amount,
                            'dueDate': bill.dueDate.toIso8601String().split('T')[0],
                          })
                      .toList(),
                ),
                const SizedBox(height: AppSizes.md),

                // Recent Transactions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/transactions');
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        if (stats.recentTransactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.lg),
                              child: Text(
                                'No recent transactions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          )
                        else
                          ...stats.recentTransactions.map((transaction) {
                            final isIncome = transaction.type == TransactionType.income;
                            final amount = isIncome ? transaction.amount : -transaction.amount;
                            return _buildTransactionItem(
                              context,
                              icon: _getIconForTransaction(transaction),
                              title: transaction.description ?? 'Transaction',
                              category: transaction.categoryName ?? 'Uncategorized',
                              amount: amount,
                              date: transaction.date,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Failed to load dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
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
                  onPressed: () {
                    ref.read(dashboardNotifierProvider.notifier).loadDashboard();
                  },
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

  IconData _getIconForTransaction(TransactionEntity transaction) {
    if (transaction.type == TransactionType.income) {
      return Icons.attach_money;
    }

    // Map common category names to icons
    final categoryName = transaction.categoryName?.toLowerCase() ?? '';
    if (categoryName.contains('food') || categoryName.contains('dining') || categoryName.contains('restaurant')) {
      return Icons.restaurant;
    } else if (categoryName.contains('shopping') || categoryName.contains('retail')) {
      return Icons.shopping_bag;
    } else if (categoryName.contains('transport') || categoryName.contains('car') || categoryName.contains('gas')) {
      return Icons.directions_car;
    } else if (categoryName.contains('coffee') || categoryName.contains('cafe')) {
      return Icons.local_cafe;
    } else if (categoryName.contains('entertainment') || categoryName.contains('movie')) {
      return Icons.movie;
    } else if (categoryName.contains('health') || categoryName.contains('medical')) {
      return Icons.local_hospital;
    } else if (categoryName.contains('utility') || categoryName.contains('bill')) {
      return Icons.receipt;
    } else {
      return Icons.payment;
    }
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
  }) {
    final isPositive = amount >= 0;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: isPositive
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(
          icon,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        category,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : ''}${currencyFormat.format(amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormat('MMM d').format(date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
