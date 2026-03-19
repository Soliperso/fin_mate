import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart';

class DebtHeroCard extends StatelessWidget {
  final double totalBalance;
  final int debtCount;
  final PayoffResult? payoffResult;
  final List<DebtEntity> debts;

  const DebtHeroCard({
    super.key,
    required this.totalBalance,
    required this.debtCount,
    required this.debts,
    this.payoffResult,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final monthFormat = DateFormat('MMM yyyy');

    final debtFreeLabel = payoffResult != null
        ? monthFormat.format(payoffResult!.debtFreeDate)
        : '—';
    final totalInterestLabel = payoffResult != null
        ? currencyFormat.format(payoffResult!.totalInterestPaid)
        : '—';

    // Overall progress — only shown when at least one debt has originalBalance
    double? overallProgress;
    bool hasAnyOriginal = false;
    double totalOriginal = 0;
    double totalPaid = 0;
    for (final d in debts) {
      if (d.originalBalance != null && d.originalBalance! > 0) {
        hasAnyOriginal = true;
        totalOriginal += d.originalBalance!;
        totalPaid +=
            (d.originalBalance! - d.balance).clamp(0.0, d.originalBalance!);
      } else {
        totalOriginal += d.balance;
      }
    }
    if (hasAnyOriginal && totalOriginal > 0) {
      overallProgress = (totalPaid / totalOriginal).clamp(0.0, 1.0);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.debtRedStart, AppColors.debtRedEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Total Debt',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppSizes.xs),

          // Main balance
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totalBalance),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSizes.md),

          // Stats row
          Row(
            children: [
              _StatBadge(
                label: 'Debt-Free',
                value: debtFreeLabel,
              ),
              const SizedBox(width: AppSizes.sm),
              _StatBadge(
                label: 'Total Interest',
                value: totalInterestLabel,
              ),
              const SizedBox(width: AppSizes.sm),
              _StatBadge(
                label: 'Accounts',
                value: '$debtCount',
              ),
            ],
          ),

          // Overall progress bar
          if (overallProgress != null) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  '${(overallProgress * 100).toStringAsFixed(0)}% paid off',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
