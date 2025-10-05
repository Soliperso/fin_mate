import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final groupName = 'Roommates';
    final expenses = [
      {
        'id': '1',
        'description': 'Groceries',
        'amount': 120.50,
        'paidBy': 'You',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'split': 3,
      },
      {
        'id': '2',
        'description': 'Electric Bill',
        'amount': 180.0,
        'paidBy': 'John',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'split': 3,
      },
    ];

    final balances = [
      {'name': 'John', 'amount': -60.0},
      {'name': 'Sarah', 'amount': -40.0},
      {'name': 'You', 'amount': 100.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Group settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balances Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.royalPurple, AppColors.tealBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Balances',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  ...balances.map((balance) {
                    final amount = balance['amount'] as double;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            balance['name'] as String,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.white,
                                ),
                          ),
                          Text(
                            amount >= 0 ? '+\$${amount.toStringAsFixed(2)}' : '-\$${amount.abs().toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Expenses Section
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expenses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Add expense
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (expenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _buildExpenseItem(context, expense);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Settle up
        },
        child: const Icon(Icons.done_all),
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Map<String, dynamic> expense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: const Icon(
            Icons.receipt,
            color: AppColors.emeraldGreen,
          ),
        ),
        title: Text(expense['description'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.xs),
            Text(
              'Paid by ${expense['paidBy']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              dateFormat.format(expense['date'] as DateTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(expense['amount']),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Split ${expense['split']} ways',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
