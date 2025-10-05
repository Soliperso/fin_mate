import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class CashFlowCard extends StatelessWidget {
  final double income;
  final double expenses;

  const CashFlowCard({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final balance = income - expenses;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Cash Flow',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildFlowItem(
                    context,
                    icon: Icons.arrow_downward,
                    label: 'Income',
                    amount: income,
                    color: AppColors.success,
                    currencyFormat: currencyFormat,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.textTertiary.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildFlowItem(
                    context,
                    icon: Icons.arrow_upward,
                    label: 'Expenses',
                    amount: expenses,
                    color: AppColors.error,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Divider(color: AppColors.textTertiary.withValues(alpha: 0.2)),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currencyFormat.format(balance),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: balance >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required NumberFormat currencyFormat,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: AppSizes.iconMd),
        const SizedBox(height: AppSizes.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          currencyFormat.format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
