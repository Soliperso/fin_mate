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

    final totalDays = periodBudget.currentPeriodEnd
        .difference(periodBudget.currentPeriodStart)
        .inDays
        .clamp(1, 999);
    final daysElapsed = (totalDays - daysRemaining).clamp(0, totalDays);
    final paceProgress = daysElapsed / totalDays;
    final dailyBudget = totalBudgeted / totalDays;
    final dailyActual = daysElapsed > 0 ? totalSpent / daysElapsed : 0.0;
    final isPaceOver = dailyActual > dailyBudget;

    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final String statusText;
    final Color statusColor;
    if (pct >= 100) {
      statusText = 'Budget exceeded this period';
      statusColor = AppColors.systemRed;
    } else if (pct >= 80) {
      statusText = 'Nearing your budget limit';
      statusColor = AppColors.systemOrange;
    } else if (isPaceOver) {
      statusText = 'Spending above daily pace';
      statusColor = AppColors.systemOrange;
    } else {
      statusText = 'On track this period';
      statusColor = AppColors.systemGreen;
    }

    final bool isOverBudget = totalRemaining < 0;
    final String remainingText = isOverBudget
        ? 'over budget by ${currency.format(totalRemaining.abs() * convFactor)}'
        : '${currency.format(totalRemaining * convFactor)} ${'budgets.leftToSpend'.tr()}';
    final Color remainingColor = isOverBudget ? AppColors.systemRed : progressColor;

    final baseCardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final cardColor = pct >= 100
        ? Color.lerp(baseCardColor, AppColors.systemRed, isDark ? 0.08 : 0.04)!
        : pct >= 80
            ? Color.lerp(baseCardColor, AppColors.systemOrange, isDark ? 0.08 : 0.04)!
            : baseCardColor;

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
              const SizedBox(width: AppSizes.xs),
              Text(
                '·',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '${budgets.length} ${budgets.length == 1 ? 'budget' : 'budgets.title'.tr().toLowerCase()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
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
                  Positioned(
                    left: (constraints.maxWidth * paceProgress)
                        .clamp(1.0, constraints.maxWidth - 2),
                    top: -3,
                    bottom: -3,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remainingText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: remainingColor,
                      fontWeight: FontWeight.w500,
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
