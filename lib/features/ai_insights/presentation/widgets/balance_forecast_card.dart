import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/balance_forecast.dart';

class BalanceForecastCard extends StatelessWidget {
  final BalanceForecast forecast;

  const BalanceForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primaryTeal,
                  size: 24,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Balance Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Current Balance
            _buildBalanceRow(
              context,
              'Current Balance',
              forecast.currentBalance,
              currencyFormat,
              AppColors.primaryTeal,
              true,
            ),
            const Divider(height: AppSizes.md),

            // Safe to Spend
            _buildBalanceRow(
              context,
              'Safe to Spend',
              forecast.safeToSpend,
              currencyFormat,
              AppColors.success,
              false,
            ),
            const SizedBox(height: AppSizes.sm),

            // 30-day projected
            if (forecast.dailyForecasts.isNotEmpty)
              _buildBalanceRow(
                context,
                'Projected (30 days)',
                forecast.dailyForecasts.last.projectedBalance,
                currencyFormat,
                forecast.dailyForecasts.last.status == BalanceStatus.healthy
                    ? AppColors.success
                    : forecast.dailyForecasts.last.status == BalanceStatus.warning
                        ? AppColors.warning
                        : AppColors.error,
                false,
              ),

            // Warnings
            if (forecast.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: forecast.warnings.take(2).map((warning) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              warning,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
    BuildContext context,
    String label,
    double amount,
    NumberFormat format,
    Color color,
    bool isBold,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          format.format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
