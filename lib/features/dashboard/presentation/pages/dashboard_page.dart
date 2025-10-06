import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/net_worth_card.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/money_health_score.dart';
import '../widgets/upcoming_bills_card.dart';
import '../widgets/quick_action_button.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
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
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Card
              const NetWorthCard(
                netWorth: 45320,
                changePercentage: 12.5,
                isPositive: true,
              ),
              const SizedBox(height: AppSizes.md),

              // Money Health Score
              const MoneyHealthScore(score: 78),
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
                      color: AppColors.royalPurple,
                      onTap: () {
                        context.go('/bills');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Cash Flow Card
              const CashFlowCard(
                income: 8500,
                expenses: 5320,
              ),
              const SizedBox(height: AppSizes.md),

              // Upcoming Bills
              const UpcomingBillsCard(
                bills: [
                  {'name': 'Rent', 'amount': 1500.0, 'dueDate': '2025-10-15'},
                  {'name': 'Electric Bill', 'amount': 120.0, 'dueDate': '2025-10-18'},
                  {'name': 'Internet', 'amount': 80.0, 'dueDate': '2025-10-20'},
                ],
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
                      _buildTransactionItem(
                        context,
                        icon: Icons.shopping_bag,
                        title: 'Grocery Shopping',
                        category: 'Food & Dining',
                        amount: -125.50,
                        date: DateTime.now().subtract(const Duration(days: 1)),
                      ),
                      _buildTransactionItem(
                        context,
                        icon: Icons.local_cafe,
                        title: 'Coffee Shop',
                        category: 'Food & Dining',
                        amount: -5.50,
                        date: DateTime.now().subtract(const Duration(days: 2)),
                      ),
                      _buildTransactionItem(
                        context,
                        icon: Icons.attach_money,
                        title: 'Salary Deposit',
                        category: 'Income',
                        amount: 8500.00,
                        date: DateTime.now().subtract(const Duration(days: 3)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
