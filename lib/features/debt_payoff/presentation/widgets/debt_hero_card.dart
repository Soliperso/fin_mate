import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/services/payoff_calculator.dart';

class DebtHeroCard extends StatelessWidget {
  final double totalBalance;
  final int debtCount;
  final PayoffResult? payoffResult;

  const DebtHeroCard({
    super.key,
    required this.totalBalance,
    required this.debtCount,
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCC2B2B), Color(0xFF8B1A1A)],
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
