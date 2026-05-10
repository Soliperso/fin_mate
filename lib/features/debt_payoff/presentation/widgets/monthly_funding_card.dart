import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/debt_entity.dart';

class MonthlyFundingCard extends ConsumerWidget {
  final List<DebtEntity> debts;

  const MonthlyFundingCard({super.key, required this.debts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyFormat2Provider);
    final total = debts.fold<double>(0, (s, d) => s + d.minimumPayment);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              AppSizes.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    CupertinoIcons.creditcard,
                    color: AppColors.primaryTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'monthlyFunding.title'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'monthlyFunding.subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? AppColors.separatorDark.withValues(alpha: 0.3)
                : AppColors.separator.withValues(alpha: 0.25),
          ),

          // Per-debt rows
          ...debts.map((debt) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm - 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        debt.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${currency.format(debt.minimumPayment)}/mo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              )),

          // Total footer
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSizes.md,
              0,
              AppSizes.md,
              AppSizes.md,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'monthlyFunding.totalPerMonth'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                ),
                Text(
                  currency.format(total),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
