import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/services/payoff_calculator.dart' show DebtStrategy, PayoffResult;
import '../providers/debt_providers.dart';

class StrategyComparisonSheet extends ConsumerWidget {
  const StrategyComparisonSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avalancheResult = ref.watch(avalancheResultProvider);
    final snowballResult = ref.watch(snowballResultProvider);
    final selected = ref.watch(selectedStrategyProvider);

    if (avalancheResult == null || snowballResult == null) {
      return const SizedBox.shrink();
    }

    final interestDiff =
        snowballResult.totalInterestPaid - avalancheResult.totalInterestPaid;
    final monthDiff = snowballResult.totalMonths - avalancheResult.totalMonths;
    final currencyFormat = ref.watch(currencyFormat0Provider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.sm,
          AppSizes.md,
          AppSizes.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'strategyComparison.title'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                CircularIconButton(
                  icon: CupertinoIcons.xmark,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.md),

            // Strategy cards
            _StrategyCard(
              strategy: DebtStrategy.avalanche,
              result: avalancheResult,
              isSelected: selected == DebtStrategy.avalanche,
              onSelect: () {
                ref.read(selectedStrategyProvider.notifier).state =
                    DebtStrategy.avalanche;
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSizes.sm),
            _StrategyCard(
              strategy: DebtStrategy.snowball,
              result: snowballResult,
              isSelected: selected == DebtStrategy.snowball,
              onSelect: () {
                ref.read(selectedStrategyProvider.notifier).state =
                    DebtStrategy.snowball;
                Navigator.pop(context);
              },
            ),

            // Insights card
            const SizedBox(height: AppSizes.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(
                          CupertinoIcons.lightbulb,
                          size: 14,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        'strategyComparison.insights'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.sm),

                  // Interest savings row
                  _InsightRow(
                    icon: CupertinoIcons.money_dollar,
                    iconColor: AppColors.warning,
                    label: 'strategyComparison.interestSavings'.tr(),
                    value: interestDiff > 0
                        ? 'strategyComparison.avalancheSaves'.tr(namedArgs: {'amount': currencyFormat.format(interestDiff)})
                        : interestDiff < 0
                            ? 'strategyComparison.snowballSaves'.tr(namedArgs: {'amount': currencyFormat.format(interestDiff.abs())})
                            : 'strategyComparison.sameTotalInterest'.tr(),
                    valueBadgeColor: interestDiff.abs() > 0
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Timeline row
                  _InsightRow(
                    icon: CupertinoIcons.calendar,
                    iconColor: AppColors.info,
                    label: 'strategyComparison.payoffTimeline'.tr(),
                    value: monthDiff == 0
                        ? 'strategyComparison.bothFinish'.tr()
                        : monthDiff > 0
                            ? 'strategyComparison.avalancheFinishes'.tr(namedArgs: {'months': '$monthDiff'})
                            : 'strategyComparison.snowballFinishes'.tr(namedArgs: {'months': '${monthDiff.abs()}'}),
                    valueBadgeColor: monthDiff.abs() > 0
                        ? AppColors.info
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Recommendation row
                  _InsightRow(
                    icon: CupertinoIcons.star,
                    iconColor: AppColors.success,
                    label: 'strategyComparison.bestForYou'.tr(),
                    value: interestDiff >= 0
                        ? 'strategyComparison.avalancheBest'.tr()
                        : 'strategyComparison.snowballBest'.tr(),
                    valueBadgeColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyCard extends ConsumerWidget {
  final DebtStrategy strategy;
  final PayoffResult result;
  final bool isSelected;
  final VoidCallback onSelect;

  const _StrategyCard({
    required this.strategy,
    required this.result,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvalanche = strategy == DebtStrategy.avalanche;
    final currencyFormat = ref.watch(currencyFormat0Provider);
    final dateFormat = DateFormat('MMM yyyy', context.locale.languageCode);

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: isSelected
          ? Border.all(color: AppColors.primaryTeal, width: 2)
          : const Border(),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isAvalanche ? CupertinoIcons.flame : CupertinoIcons.snow,
                size: AppSizes.iconSm,
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                isAvalanche ? 'strategyComparison.avalanche'.tr() : 'strategyComparison.snowball'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryTeal
                          : null,
                    ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'strategyComparison.active'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // Description
          Text(
            isAvalanche
                ? 'strategyComparison.avalancheDesc'.tr()
                : 'strategyComparison.snowballDesc'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.md),

          // 2×2 metric grid
          Row(
            children: [
              _MetricTile(
                label: 'strategyComparison.debtFree'.tr(),
                value: dateFormat.format(result.debtFreeDate),
              ),
              _MetricTile(
                label: 'strategyComparison.months'.tr(),
                value: '${result.totalMonths}',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              _MetricTile(
                label: 'strategyComparison.totalInterest'.tr(),
                value: currencyFormat.format(result.totalInterestPaid),
                valueColor: AppColors.error,
              ),
              _MetricTile(
                label: 'strategyComparison.totalPaid'.tr(),
                value: currencyFormat.format(result.totalPaid),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Action button
          SizedBox(
            width: double.infinity,
            child: isSelected
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.primaryTeal.withValues(alpha: 0.4)),
                      foregroundColor: AppColors.primaryTeal,
                      disabledForegroundColor:
                          AppColors.primaryTeal.withValues(alpha: 0.5),
                    ),
                    child: Text('strategyComparison.currentlyActive'.tr()),
                  )
                : FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('strategyComparison.useStrategy'.tr()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueBadgeColor;

  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: valueBadgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: valueBadgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
