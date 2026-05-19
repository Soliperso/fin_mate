import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../../../shared/widgets/hero_stat_badge.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart';

class DebtHeroCard extends ConsumerWidget {
  final double totalBalance;
  final int debtCount;
  final PayoffResult? payoffResult;
  final List<DebtEntity> debts;
  final double extraMonthly;

  const DebtHeroCard({
    super.key,
    required this.totalBalance,
    required this.debtCount,
    required this.debts,
    this.payoffResult,
    this.extraMonthly = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat0 = ref.watch(currencyFormat0Provider);
    final currencyFormat2 = ref.watch(currencyFormat2Provider);

    final capHit = payoffResult?.hitMaxMonths == true;

    final totalMinMonthly =
        debts.fold<double>(0.0, (s, d) => s + d.minimumPayment);
    final totalMonthlyInterest =
        debts.fold<double>(0.0, (s, d) => s + d.monthlyInterest);

    // Overall progress — only shown when at least one debt has originalBalance
    double? overallProgress;
    double totalOriginal = 0;
    double totalPaid = 0;
    for (final d in debts) {
      final originalBalance = d.originalBalance;
      if (originalBalance != null && originalBalance > 0) {
        totalOriginal += originalBalance;
        totalPaid += (originalBalance - d.balance).clamp(0.0, originalBalance);
      }
    }
    if (totalOriginal > 0) {
      overallProgress = (totalPaid / totalOriginal).clamp(0.0, 1.0);
    }

    return GradientHeroCard(
      gradientColors: const [AppColors.debtRedStart, AppColors.debtRedEnd],
      shadowColor: AppColors.error.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row + Active badge
          Row(
            children: [
              Text(
                'debtHero.totalDebt'.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.arrow_up,
                        size: 9, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // Main balance
          Text(
            currencyFormat2.format(totalBalance),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 2),

          // Subtitle
          Text(
            'across $debtCount ${debtCount == 1 ? 'account' : 'accounts'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: AppSizes.md),

          // Stats row: MIN/MONTH + INTEREST/MO
          Row(
            children: [
              HeroStatBadge(
                label: 'Min / Month',
                value: currencyFormat2.format(totalMinMonthly),
              ),
              const SizedBox(width: AppSizes.sm),
              HeroStatBadge(
                label: 'Interest / Mo',
                value: currencyFormat2.format(totalMonthlyInterest),
              ),
            ],
          ),

          // Cap-hit warning: min payment < monthly interest
          if (capHit) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs + 1,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      'debtHero.neverPaysOffWarning'.tr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Extra payment active indicator
          if (extraMonthly > 0) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.bolt_fill,
                      color: Colors.white, size: AppSizes.iconXs),
                  const SizedBox(width: 4),
                  Text(
                    'debtHero.extraPayment'.tr(namedArgs: {
                      'amount': currencyFormat0.format(extraMonthly)
                    }),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],

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
                  '${(overallProgress * 100).toStringAsFixed(0)}${'debtHero.percentPaid'.tr()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
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
