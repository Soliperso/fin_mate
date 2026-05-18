import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetHeroCard extends ConsumerWidget {
  final List<BudgetEntity> budgets;

  const BudgetHeroCard({super.key, required this.budgets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);

    final totalBudgeted =
        budgets.fold<double>(0, (sum, b) => sum + b.effectiveAmount);
    final totalSpent =
        budgets.fold<double>(0, (sum, b) => sum + (b.spent ?? 0));
    final totalRemaining = totalBudgeted - totalSpent;
    final overallProgress =
        totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;
    final pct = overallProgress * 100;

    final periodBudget = budgets.firstWhere(
      (b) => b.period == BudgetPeriod.monthly,
      orElse: () => budgets.first,
    );
    final periodLabel =
        DateFormat('MMMM yyyy').format(periodBudget.currentPeriodStart).toUpperCase();
    final daysRemaining = periodBudget.currentPeriodEnd
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final badgeColor = pct >= 100
        ? AppColors.systemRed
        : pct >= 80
            ? AppColors.systemOrange
            : AppColors.systemGreen;

    final progressColor = pct >= 100
        ? AppColors.systemRed
        : pct >= 80
            ? AppColors.systemOrange
            : AppColors.brandTeal;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                periodLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)} %',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: currency.format(totalSpent * convFactor),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextSpan(
                  text: ' / ${currency.format(totalBudgeted * convFactor)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: overallProgress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Builder(
            builder: (context) {
              final totalDays = periodBudget.currentPeriodEnd
                  .difference(periodBudget.currentPeriodStart)
                  .inDays
                  .clamp(1, 999);
              final daysElapsed = (totalDays - daysRemaining).clamp(1, totalDays);
              final dailyBudget = totalBudgeted / totalDays;
              final dailyActual = totalSpent / daysElapsed;
              final isDailyOver = dailyActual > dailyBudget;

              return Text(
                '${currency.format(dailyActual * convFactor)}/day avg  ·  '
                '${currency.format(dailyBudget * convFactor)}/day budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDailyOver ? AppColors.systemOrange : AppColors.brandTeal,
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currency.format(totalRemaining.abs() * convFactor)} ${'budgets.leftToSpend'.tr()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                '$daysRemaining ${'budgets.daysRemaining'.tr()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
