import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/services/payoff_calculator.dart';

class DebtCostSplitCard extends StatelessWidget {
  final PayoffResult payoffResult;
  final double totalCurrentBalance;

  const DebtCostSplitCard({
    super.key,
    required this.payoffResult,
    required this.totalCurrentBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final principal = totalCurrentBalance;
    final interest = payoffResult.totalInterestPaid;
    final total = principal + interest;

    if (total <= 0) return const SizedBox.shrink();

    final principalFraction = principal / total;
    final interestFraction = interest / total;
    final interestExtraPercent =
        principal > 0 ? ((interest / principal) * 100).toStringAsFixed(0) : '0';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: AppColors.brandTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost of Your Debt',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Principal + interest over full payoff',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // ── Split bar ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: Row(
                children: [
                  Flexible(
                    flex: (principalFraction * 1000).round(),
                    child: Container(
                      height: 12,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  if (interestFraction > 0.005)
                    Flexible(
                      flex: (interestFraction * 1000).round(),
                      child: Container(
                        height: 12,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.sm),

            // ── Legend ────────────────────────────────────────────────────
            Row(
              children: [
                _LegendDot(color: AppColors.brandTeal, label: 'Principal'),
                const SizedBox(width: AppSizes.md),
                _LegendDot(color: AppColors.error, label: 'Interest'),
              ],
            ),

            const SizedBox(height: AppSizes.sm),

            // ── Amounts row ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray6,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AmountColumn(
                    label: 'Principal',
                    value: currency.format(principal),
                    color: AppColors.brandTeal,
                  ),
                  Container(
                    width: 0.5,
                    height: 32,
                    color: isDark
                        ? AppColors.separatorDark
                        : AppColors.separator,
                  ),
                  _AmountColumn(
                    label: 'Interest',
                    value: currency.format(interest),
                    color: AppColors.error,
                  ),
                  Container(
                    width: 0.5,
                    height: 32,
                    color: isDark
                        ? AppColors.separatorDark
                        : AppColors.separator,
                  ),
                  _AmountColumn(
                    label: 'Total',
                    value: currency.format(total),
                    color: isDark
                        ? AppColors.labelDark
                        : AppColors.label,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.sm),

            // ── Insight line ──────────────────────────────────────────────
            Center(
              child: Text(
                "You'll pay $interestExtraPercent% extra in interest",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
