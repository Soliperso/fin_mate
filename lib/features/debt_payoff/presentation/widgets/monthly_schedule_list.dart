import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart';

/// Same palette as the payoff timeline chart — keeps chips in sync with lines.
const _kDebtColors = [
  AppColors.error,
  AppColors.info,
  AppColors.warning,
  AppColors.success,
  AppColors.primaryTeal,
  AppColors.systemGray,
];

String _debtTypeLabel(String debtType) {
  switch (debtType) {
    case 'credit_card':
      return 'CC';
    case 'student_loan':
      return 'SL';
    case 'auto_loan':
      return 'Auto';
    case 'mortgage':
      return 'Mort';
    case 'medical':
      return 'Med';
    case 'personal_loan':
      return 'PL';
    default:
      return 'Debt';
  }
}

class MonthlyScheduleList extends StatelessWidget {
  final PayoffResult result;
  final List<DebtEntity> debts;
  final int monthsToShow;

  const MonthlyScheduleList({
    super.key,
    required this.result,
    required this.debts,
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
                      ? const Color(0xFF141416)
                      : AppColors.systemGray5)
                  : (isDark
                      ? AppColors.secondarySystemBackgroundDark
                      : AppColors.systemGray6);

              return Container(
                color: rowBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month label
                    SizedBox(
                      width: 48,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          DateFormat('MMM yy').format(snap.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: idx == 0
                                    ? AppColors.primaryTeal
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    // Per-debt breakdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: debts.asMap().entries.map((debtEntry) {
                          final debt = debtEntry.value;
                          final chipColor = _kDebtColors[
                              debtEntry.key % _kDebtColors.length];
                          final chipLabel = _debtTypeLabel(debt.debtType);
                          final payment = snap.debtPayments[debt.id] ?? 0.0;
                          final remaining =
                              snap.debtBalancesAfter[debt.id] ?? 0.0;
                          final isPaidOff = remaining < 0.01;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                // Type chip (color synced with chart lines)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: chipColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
                                  ),
                                  child: Text(
                                    chipLabel,
                                    style: TextStyle(
                                      color: chipColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    debt.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPaidOff)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusFull),
                                    ),
                                    child: Text(
                                      'Paid off',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                    ),
                                  )
                                else ...[
                                  Text(
                                    '${currencyFormat.format(payment)} paid',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '· ${currencyFormat.format(remaining)} left',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Total payment
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        currencyFormat.format(snap.totalPaymentThisMonth),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
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
