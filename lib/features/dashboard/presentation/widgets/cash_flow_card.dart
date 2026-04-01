import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';

/// Apple Wallet-style cash flow summary card
class CashFlowCard extends ConsumerWidget {
  final double income;
  final double expenses;

  const CashFlowCard({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat0Provider);
    final balance = income - expenses;
    final isPositive = balance >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Cash Flow',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'This month',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Income / Expenses row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  child: _FlowCell(
                    label: 'Income',
                    amount: income,
                    color: AppColors.systemGreen,
                    icon: CupertinoIcons.arrow_down,
                    currencyFormat: currencyFormat,
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 56,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _FlowCell(
                    label: 'Expenses',
                    amount: expenses,
                    color: AppColors.systemRed,
                    icon: CupertinoIcons.arrow_up,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: AppSizes.md + AppSizes.sm,
            thickness: 0.5,
            indent: AppSizes.md,
            endIndent: AppSizes.md,
            color: Theme.of(context).dividerColor,
          ),

          // Net balance row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md, 0, AppSizes.md, AppSizes.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                ),
                Text(
                  '${isPositive ? '+' : ''}${currencyFormat.format(balance)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPositive
                            ? AppColors.systemGreen
                            : AppColors.systemRed,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currencyFormat;

  const _FlowCell({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            currencyFormat.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
