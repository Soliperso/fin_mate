import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/balance_forecast_provider.dart';

class SafeToSpendBanner extends ConsumerWidget {
  final VoidCallback? onTap;

  const SafeToSpendBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(balanceForecastProvider);
    final currencyFormat = ref.watch(currencyFormat2Provider);

    return forecastAsync.when(
      data: (forecast) => _BannerContent(
        safeToSpend: forecast.safeToSpend,
        currencyFormat: currencyFormat,
        onTap: onTap,
      ),
      loading: () => const _BannerSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final double safeToSpend;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  const _BannerContent({
    required this.safeToSpend,
    required this.currencyFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final monthProgress = (now.day - 1) / daysInMonth;
    final isPositive = safeToSpend > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSizes.md, AppSizes.sm, AppSizes.md, 0),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [AppColors.brandTeal, AppColors.brandTealLight]
                : [AppColors.systemRed, const Color(0xFFFF6961)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: [
            BoxShadow(
              color: (isPositive ? AppColors.brandTeal : AppColors.systemRed)
                  .withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.money_dollar_circle,
                    size: 16, color: Colors.white70),
                const SizedBox(width: AppSizes.xs),
                Text(
                  'Safe to Spend',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Text(
                  '$daysRemaining days left',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(width: AppSizes.xs),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: Colors.white54),
              ],
            ),
            const SizedBox(height: AppSizes.xs - 1),
            Text(
              currencyFormat.format(safeToSpend.abs()),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: AppSizes.xs + 1),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: monthProgress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.brandTeal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
    );
  }
}
