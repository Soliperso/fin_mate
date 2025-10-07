import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class NetWorthCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Determine gradient colors based on net worth
    final gradientColors = netWorth > 0
        ? [AppColors.emeraldGreen, AppColors.tealBlue]
        : [AppColors.error, const Color(0xFFD32F2F)]; // Red gradient for zero or negative

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Net Worth',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            currencyFormat.format(netWorth),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: AppColors.white,
                size: AppSizes.iconSm,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '${isPositive ? '+' : '-'}${changePercentage.abs()}% this month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
