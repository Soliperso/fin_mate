import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/net_worth_card.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/net_worth_trend_chart.dart';
import '../widgets/money_health_score.dart';
import '../widgets/upcoming_bills_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/emergency_fund_card.dart';
import '../providers/emergency_fund_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final profileState = ref.watch(currentUserProfileProvider);

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
              child: profileState.profile?.avatarUrl != null &&
                      profileState.profile!.avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          NetworkImage(profileState.profile!.avatarUrl!),
                    )
                  : CircleAvatar(
                      backgroundColor: AppColors.primaryTeal,
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
            ref.invalidate(emergencyFundStatusProvider);
            ref.invalidate(monthlyFlowDataProvider);
            ref.invalidate(netWorthSnapshotsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: AppSizes.md),

                // Emergency Fund Status
                Consumer(
                  builder: (context, ref, _) {
                    final statusAsync = ref.watch(emergencyFundStatusProvider);
                    return statusAsync.when(
                      data: (status) => EmergencyFundCard(status: status),
                      loading: () => const SkeletonCard(height: 240),
                      error: (error, stack) => const SizedBox.shrink(),
                    );
                  },
                ),
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
                      error: (_, _) => const SizedBox.shrink(),
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
                      error: (_, _) => const SizedBox.shrink(),
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
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'No recent transactions',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.go('/transactions/add?type=expense');
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Transaction'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryTeal,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
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
                              title: transaction.description ?? 'No description',
                              subtitle: transaction.categoryName ?? 'Uncategorized',
                              amount: amount,
                              date: transaction.date,
                              onTap: () {
                                context.go('/transactions/add?type=${transaction.type.name}&id=${transaction.id}');
                              },
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
        loading: () => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              const SkeletonCard(height: 150),
              const SkeletonCard(height: 100),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(child: const SkeletonCard(height: 80)),
                  const SizedBox(width: AppSizes.md),
                  Expanded(child: const SkeletonCard(height: 80)),
                  const SizedBox(width: AppSizes.md),
                  Expanded(child: const SkeletonCard(height: 80)),
                ],
              ),
              const SkeletonCard(height: 120),
              const SkeletonChart(height: 200),
              const SkeletonCard(height: 150),
            ],
          ),
        ),
        error: (error, stack) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
            ref.invalidate(emergencyFundStatusProvider);
            ref.invalidate(monthlyFlowDataProvider);
            ref.invalidate(netWorthSnapshotsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load dashboard',
                message: 'Unable to fetch your financial data. Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(dashboardNotifierProvider.notifier).loadDashboard();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTransaction(TransactionEntity transaction) {
    // Map category names to icons based on database categories
    final categoryName = transaction.categoryName?.toLowerCase() ?? '';

    // Income categories
    if (transaction.type == TransactionType.income) {
      if (categoryName.contains('salary')) {
        return Icons.work_outline;
      } else if (categoryName.contains('freelance')) {
        return Icons.laptop_mac;
      } else if (categoryName.contains('investment')) {
        return Icons.trending_up;
      } else if (categoryName.contains('gift')) {
        return Icons.card_giftcard;
      } else {
        return Icons.attach_money;
      }
    }

    // Expense categories
    if (categoryName.contains('food') || categoryName.contains('dining')) {
      return Icons.restaurant;
    } else if (categoryName.contains('transportation')) {
      return Icons.directions_car;
    } else if (categoryName.contains('shopping')) {
      return Icons.shopping_bag;
    } else if (categoryName.contains('entertainment')) {
      return Icons.movie;
    } else if (categoryName.contains('bills') || categoryName.contains('utilities')) {
      return Icons.receipt_long;
    } else if (categoryName.contains('healthcare') || categoryName.contains('health')) {
      return Icons.local_hospital;
    } else if (categoryName.contains('education')) {
      return Icons.school;
    } else if (categoryName.contains('housing')) {
      return Icons.home;
    } else if (categoryName.contains('personal care')) {
      return Icons.spa;
    } else {
      return Icons.payment;
    }
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double amount,
    required DateTime date,
    VoidCallback? onTap,
  }) {
    final isPositive = amount >= 0;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Calculate relative date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(transactionDate).inDays;

    String dateText;
    if (difference == 0) {
      dateText = 'Today';
    } else if (difference == 1) {
      dateText = 'Yesterday';
    } else if (difference < 7) {
      dateText = '$difference days ago';
    } else {
      dateText = DateFormat('MMM d').format(date);
    }

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
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : ''}${currencyFormat.format(amount)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            dateText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
