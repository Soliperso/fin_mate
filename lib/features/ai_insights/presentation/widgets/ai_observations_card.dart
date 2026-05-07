import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/balance_forecast.dart';

class AiObservationsCard extends StatelessWidget {
  final BalanceForecast forecast;

  const AiObservationsCard({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final observations = _buildObservations();
    if (observations.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                size: 16,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'AI Observations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ...observations.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(o.icon, size: 16, color: o.color),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      o.text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_Observation> _buildObservations() {
    final days = forecast.dailyForecasts;
    if (days.isEmpty) return [];

    final observations = <_Observation>[];
    final balance = forecast.currentBalance;
    final projected30 = days.last.projectedBalance;

    // 1. Trend direction
    if (balance != 0) {
      final deltaPct = ((projected30 - balance) / balance * 100).abs();
      if (projected30 >= balance) {
        observations.add(_Observation(
          icon: CupertinoIcons.arrow_up_right_circle_fill,
          color: AppColors.systemGreen,
          text:
              'Balance is projected to grow by ${deltaPct.toStringAsFixed(1)}% over the next 30 days.',
        ));
      } else {
        observations.add(_Observation(
          icon: CupertinoIcons.arrow_down_right_circle_fill,
          color: AppColors.systemOrange,
          text:
              'Balance may decrease by ${deltaPct.toStringAsFixed(1)}% over the next 30 days.',
        ));
      }
    }

    // 2. Critical / warning day count
    final criticalDays =
        days.where((d) => d.status == BalanceStatus.critical).length;
    final warningDays =
        days.where((d) => d.status == BalanceStatus.warning).length;
    if (criticalDays > 0) {
      observations.add(_Observation(
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        color: AppColors.systemRed,
        text:
            '$criticalDays day${criticalDays > 1 ? "s" : ""} with critically low balance detected this month.',
      ));
    } else if (warningDays > 0) {
      observations.add(_Observation(
        icon: CupertinoIcons.exclamationmark_circle_fill,
        color: AppColors.systemOrange,
        text:
            '$warningDays day${warningDays > 1 ? "s" : ""} where balance may drop to warning levels.',
      ));
    }

    // 3. Upcoming bill pressure (next 7 days with scheduled transactions)
    final billDays = days
        .take(7)
        .where((d) => d.scheduledTransactions.isNotEmpty)
        .length;
    if (billDays > 0) {
      observations.add(_Observation(
        icon: CupertinoIcons.calendar_badge_plus,
        color: AppColors.systemBlue,
        text:
            '$billDays scheduled payment${billDays > 1 ? "s" : ""} due in the next 7 days.',
      ));
    }

    return observations.take(3).toList();
  }
}

class _Observation {
  final IconData icon;
  final Color color;
  final String text;

  const _Observation({
    required this.icon,
    required this.color,
    required this.text,
  });
}
