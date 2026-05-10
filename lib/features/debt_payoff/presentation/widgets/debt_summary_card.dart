import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';

class DebtSummaryCard extends ConsumerWidget {
  final double totalBalance;
  final double totalMinPayment;
  final int debtCount;
  final double? monthlyIncome;

  const DebtSummaryCard({
    super.key,
    required this.totalBalance,
    required this.totalMinPayment,
    required this.debtCount,
    this.monthlyIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final dti = (monthlyIncome != null && monthlyIncome! > 0)
        ? totalMinPayment / monthlyIncome! * 100
        : null;

    Color dtiColor(double ratio) {
      if (ratio < 36) return AppColors.success;
      if (ratio < 50) return AppColors.warning;
      return AppColors.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'debtSummary.totalDebt'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              currencyFormat.format(totalBalance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    label: 'debtSummary.accounts'.tr(),
                    value: '$debtCount',
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    label: 'debtSummary.minMonthly'.tr(),
                    value: currencyFormat.format(totalMinPayment),
                  ),
                ),
                if (dti != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'debtSummary.dtiRatio'.tr(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: dtiColor(dti).withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            '${dti.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: dtiColor(dti),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
