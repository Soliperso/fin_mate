import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/services/payoff_calculator.dart';

class MonthlyScheduleList extends StatelessWidget {
  final PayoffResult result;
  final int monthsToShow;

  const MonthlyScheduleList({
    super.key,
    required this.result,
    this.monthsToShow = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final months = result.schedule.take(monthsToShow).toList();

    if (months.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next ${months.length} Payments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSizes.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Column(
            children: months.asMap().entries.map((entry) {
              final idx = entry.key;
              final snap = entry.value;
              final isEven = idx % 2 == 0;
              final rowBg = isEven
                  ? (isDark
                      ? AppColors.secondarySystemBackgroundDark
                      : AppColors.systemGray6)
                  : (isDark
                      ? AppColors.tertiarySystemBackgroundDark
                      : AppColors.white);

              return Container(
                color: rowBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm + 2,
                ),
                child: Row(
                  children: [
                    // Month
                    SizedBox(
                      width: 64,
                      child: Text(
                        DateFormat('MMM yy').format(snap.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: idx == 0
                                  ? AppColors.primaryTeal
                                  : (isDark
                                      ? AppColors.labelDark
                                      : AppColors.label),
                            ),
                      ),
                    ),
                    // Focus debt (with chip)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              snap.focusDebtName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Payment amount
                    Text(
                      currencyFormat.format(snap.totalPaymentThisMonth),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.labelDark
                                : AppColors.label,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
