import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final budgets = [
      {
        'category': 'Food & Dining',
        'spent': 450.0,
        'limit': 600.0,
        'icon': Icons.restaurant,
        'color': AppColors.emeraldGreen,
      },
      {
        'category': 'Transportation',
        'spent': 280.0,
        'limit': 300.0,
        'icon': Icons.directions_car,
        'color': AppColors.tealBlue,
      },
      {
        'category': 'Entertainment',
        'spent': 180.0,
        'limit': 150.0,
        'icon': Icons.movie,
        'color': AppColors.royalPurple,
      },
      {
        'category': 'Shopping',
        'spent': 320.0,
        'limit': 400.0,
        'icon': Icons.shopping_bag,
        'color': AppColors.warning,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              // TODO: Show budget insights
            },
          ),
        ],
      ),
      body: budgets.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return _buildBudgetCard(context, budget);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Create new budget
        },
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 120,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'No Budgets Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Create budgets to track your spending by category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Map<String, dynamic> budget) {
    final spent = budget['spent'] as double;
    final limit = budget['limit'] as double;
    final percentage = (spent / limit).clamp(0.0, 1.0);
    final remaining = limit - spent;
    final isOverBudget = spent > limit;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: (budget['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    budget['icon'] as IconData,
                    color: budget['color'] as Color,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    budget['category'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  isOverBudget ? Icons.warning : Icons.check_circle,
                  color: isOverBudget ? AppColors.error : AppColors.success,
                  size: AppSizes.iconSm,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppColors.error : budget['color'] as Color,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$${spent.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isOverBudget ? 'Over by' : 'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$${remaining.abs().toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isOverBudget ? AppColors.error : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$${limit.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
