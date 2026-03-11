import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Apple Wallet-style hero card showing total net worth
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = netWorth >= 0
        ? [AppColors.brandTeal, const Color(0xFF1A6B76)]
        : [AppColors.systemRed, const Color(0xFFB52D23)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Worth',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: -0.24,
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
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${changePercentage.abs().toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.08,
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
            style: const TextStyle(
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white60,
              letterSpacing: -0.08,
            ),
          ),
        ],
      ),
    );
  }
}
