import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../../../shared/widgets/hero_stat_badge.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetHeroCard extends ConsumerWidget {
  final List<BudgetEntity> budgets;

  const BudgetHeroCard({super.key, required this.budgets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyFormat0Provider);

    final totalBudgeted = budgets.fold<double>(0, (sum, b) => sum + b.effectiveAmount);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + (b.spent ?? 0));
    final totalRemaining = totalBudgeted - totalSpent;
    final atRisk = budgets.where((b) => b.isExceeded || b.isNearLimit).length;
    final overallProgress = totalBudgeted > 0
        ? (totalSpent / totalBudgeted).clamp(0.0, 1.0)
        : 0.0;

    return GradientHeroCard(
      gradientColors: const [AppColors.brandTeal, AppColors.brandTealDark],
      shadowColor: AppColors.brandTeal.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'budgetHero.totalBudgeted'.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
              HeroStatBadge(label: 'budgetHero.spent'.tr(), value: currency.format(totalSpent)),
              const SizedBox(width: AppSizes.sm),
              HeroStatBadge(label: 'budgetHero.remaining'.tr(), value: currency.format(totalRemaining.abs())),
              const SizedBox(width: AppSizes.sm),
              HeroStatBadge(
                label: 'budgetHero.atRisk'.tr(),
                value: atRisk == 0
                    ? 'budgetHero.none'.tr()
                    : atRisk == 1
                        ? 'budgetHero.oneBudget'.tr()
                        : 'budgetHero.budgetsAtRisk'.tr(namedArgs: {'count': '$atRisk'}),
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
                '${(overallProgress * 100).toStringAsFixed(0)}${'budgets.percentUsed'.tr()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
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
