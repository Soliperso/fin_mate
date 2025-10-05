import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../widgets/net_worth_card.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/money_health_score.dart';
import '../widgets/upcoming_bills_card.dart';
import '../widgets/quick_action_button.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              // TODO: Navigate to profile
            },
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
                        // TODO: Add expense
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
                        // TODO: Add income
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
                        // TODO: Navigate to bill splitting
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
                              // TODO: View all transactions
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
