import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';

/// Apple Wallet-style hero card showing total net worth
class NetWorthCard extends ConsumerWidget {
  final double netWorth;
  final double changePercentage;
  final bool isPositive;
  final double monthlyIncome;
  final double monthlyExpenses;

  const NetWorthCard({
    super.key,
    required this.netWorth,
    required this.changePercentage,
    required this.isPositive,
    required this.monthlyIncome,
    required this.monthlyExpenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat0Provider);
    final currencyFmt2 = ref.watch(currencyFormat2Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sign = isPositive ? '+' : '–';

    final gradientColors = netWorth >= 0
        ? [AppColors.brandTeal, AppColors.brandTealDark]
        : [AppColors.systemRed, AppColors.systemRedDeep];

    return GradientHeroCard(
      gradientColors: gradientColors,
      shadowColor: gradientColors.first.withValues(alpha: isDark ? 0.3 : 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'netWorthCard.label'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
              // Trend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? CupertinoIcons.arrow_up_right
                          : CupertinoIcons.arrow_down_right,
                      color: Colors.white,
                      size: AppSizes.iconXs - 5, // tight badge arrow
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$sign${changePercentage.abs().toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // Balance — large Apple Pay-style number
          Text(
            currencyFormat.format(netWorth),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
          ),

          const SizedBox(height: AppSizes.md),

          // Monthly stats mini-row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                _StatChip(
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  label: 'netWorthCard.income'.tr(),
                  value: currencyFmt2.format(monthlyIncome),
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                _StatChip(
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  label: 'netWorthCard.expenses'.tr(),
                  value: currencyFmt2.format(monthlyExpenses),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
