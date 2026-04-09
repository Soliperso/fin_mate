import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/dashboard_providers.dart';
import 'cash_flow_chart.dart' show MonthlyFlowData;

class SavingsRateCard extends ConsumerWidget {
  final double income;
  final double expenses;

  const SavingsRateCard({
    super.key,
    required this.income,
    required this.expenses,
  });

  double get _rate =>
      income > 0 ? ((income - expenses) / income * 100).clamp(-999.0, 100.0) : 0.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flowAsync = ref.watch(monthlyFlowDataProvider);

    if (income <= 0 && expenses <= 0) return const SizedBox.shrink();

    final rate = _rate;

    Color rateColor;
    String rateLabel;
    if (income <= 0) {
      rateColor = AppColors.systemGray;
      rateLabel = 'savingsRate.noIncome'.tr();
    } else if (rate >= 20) {
      rateColor = AppColors.systemGreen;
      rateLabel = 'savingsRate.onTrack'.tr();
    } else if (rate >= 0) {
      rateColor = AppColors.systemOrange;
      rateLabel = 'savingsRate.couldImprove'.tr();
    } else {
      rateColor = AppColors.systemRed;
      rateLabel = 'savingsRate.overspending'.tr();
    }

    return GestureDetector(
      onTap: () => context.push('/transactions'),
      child: Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          // Icon
          Container(
            width: AppSizes.iconContainer,
            height: AppSizes.iconContainer,
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              CupertinoIcons.arrow_down_circle,
              color: rateColor,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'savingsRate.label'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryLabel,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  income <= 0
                      ? rateLabel
                      : '${rate.toStringAsFixed(1)}% — $rateLabel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: rateColor,
                      ),
                ),
              ],
            ),
          ),
          // Month-over-month trend badge
          flowAsync.maybeWhen(
            data: (flow) {
              if (flow.length < 2) return const SizedBox.shrink();
              return _TrendBadge(flowData: flow);
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: AppColors.systemGray3,
          ),
        ],
      ),
    ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final List<MonthlyFlowData> flowData;

  const _TrendBadge({required this.flowData});

  double _rate(MonthlyFlowData d) =>
      d.income > 0 ? (d.income - d.expenses) / d.income * 100 : 0.0;

  @override
  Widget build(BuildContext context) {
    final sorted = [...flowData]..sort((a, b) => a.month.compareTo(b.month));
    final current = _rate(sorted.last);
    final previous = _rate(sorted[sorted.length - 2]);
    final delta = current - previous;

    final isUp = delta >= 0;
    final color = isUp ? AppColors.systemGreen : AppColors.systemRed;

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp
                ? CupertinoIcons.arrow_up_right
                : CupertinoIcons.arrow_down_right,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${delta.abs().toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: AppSizes.xs),
        ],
      ),
    );
  }
}
