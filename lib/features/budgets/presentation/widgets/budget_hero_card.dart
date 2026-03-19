import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetHeroCard extends StatelessWidget {
  final List<BudgetEntity> budgets;

  const BudgetHeroCard({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final totalBudgeted = budgets.fold<double>(0, (sum, b) => sum + b.effectiveAmount);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + (b.spent ?? 0));
    final totalRemaining = totalBudgeted - totalSpent;
    final atRisk = budgets.where((b) => b.isExceeded || b.isNearLimit).length;
    final overallProgress = totalBudgeted > 0
        ? (totalSpent / totalBudgeted).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandTeal, AppColors.brandTealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budgeted',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            currency.format(totalBudgeted),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _StatBadge(label: 'Spent', value: currency.format(totalSpent)),
              const SizedBox(width: AppSizes.sm),
              _StatBadge(label: 'Remaining', value: currency.format(totalRemaining.abs())),
              const SizedBox(width: AppSizes.sm),
              _StatBadge(
                label: 'At Risk',
                value: atRisk == 0
                    ? 'None'
                    : atRisk == 1
                        ? '1 budget'
                        : '$atRisk budgets',
                highlight: atRisk > 0,
              ),
            ],
          ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                '${(overallProgress * 100).toStringAsFixed(0)}% used',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
  final bool highlight;

  const _StatBadge({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs + 2,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.systemRed.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.15),
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
