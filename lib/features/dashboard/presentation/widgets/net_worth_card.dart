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

  const NetWorthCard({
    super.key,
    required this.netWorth,
    required this.changePercentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat0Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Net Worth',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
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
                          ? CupertinoIcons.arrow_up
                          : CupertinoIcons.arrow_down,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${changePercentage.abs().toStringAsFixed(1)}%',
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

          const SizedBox(height: AppSizes.sm),

          // Subtitle
          Text(
            isPositive ? 'Growing this month' : 'Declining this month',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.white60,
                ),
          ),
        ],
      ),
    );
  }
}
