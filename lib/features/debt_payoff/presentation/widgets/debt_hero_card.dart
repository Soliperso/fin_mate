import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final monthFormat = DateFormat('MMM yyyy');

    final debtFreeLabel = payoffResult != null
        ? monthFormat.format(payoffResult!.debtFreeDate)
        : '—';
    final totalInterestLabel = payoffResult != null
        ? currencyFormat0.format(payoffResult!.totalInterestPaid)
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

    return GradientHeroCard(
      gradientColors: const [AppColors.debtRedStart, AppColors.debtRedEnd],
      shadowColor: AppColors.error.withValues(alpha: 0.35),
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
            currencyFormat2.format(totalBalance),
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
              HeroStatBadge(label: 'Debt-Free', value: debtFreeLabel),
              const SizedBox(width: AppSizes.sm),
              HeroStatBadge(label: 'Total Interest', value: totalInterestLabel),
              const SizedBox(width: AppSizes.sm),
              HeroStatBadge(label: 'Accounts', value: '$debtCount'),
            ],
          ),

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
                  const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    'Includes +\$${extraMonthly.toStringAsFixed(0)}/mo extra payment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
