import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionListItem extends StatelessWidget {
  final RecurringTransactionEntity transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Function(bool)? onToggleActive;

  const RecurringTransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.md),
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: isIncome
                ? AppColors.success.withValues(alpha: 0.1)
                : isExpense
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : isExpense
                    ? Icons.arrow_upward
                    : Icons.swap_horiz,
            color: isIncome
                ? AppColors.success
                : isExpense
                    ? AppColors.error
                    : AppColors.primaryTeal,
          ),
        ),
        title: Text(
          transaction.description ?? 'Recurring ${transaction.type}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${transaction.frequency.displayName} • Next: ${DateFormat('MMM d').format(transaction.nextOccurrence)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            if (transaction.categoryName != null)
              Text(
                transaction.categoryName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : isExpense ? '-' : ''}${currencyFormat.format(transaction.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isIncome
                        ? AppColors.success
                        : isExpense
                            ? AppColors.error
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: transaction.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.isActive ? 'Active' : 'Inactive',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: transaction.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
