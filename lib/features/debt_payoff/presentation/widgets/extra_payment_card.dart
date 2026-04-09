import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class ExtraPaymentCard extends ConsumerWidget {
  final double totalMinimum;

  const ExtraPaymentCard({super.key, this.totalMinimum = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = ref.watch(extraPaymentProvider);
    final baseResult = ref.watch(payoffResultProvider);
    final simResult = ref.watch(simulatedPayoffProvider);

    final currencyFormat = ref.watch(currencyFormat0Provider);

    int? monthsSaved;
    double? interestSaved;
    if (extra > 0 && baseResult != null && simResult != null) {
      monthsSaved = baseResult.totalMonths - simResult.totalMonths;
      interestSaved = baseResult.totalInterestPaid - simResult.totalInterestPaid;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    CupertinoIcons.bolt,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'extraPayment.title'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (totalMinimum > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'extraPayment.requiredMinimum'.tr(namedArgs: {'amount': currencyFormat.format(totalMinimum)}),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Slider
            Row(
              children: [
                Text(
                  '\$0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.success,
                      inactiveTrackColor:
                          AppColors.success.withValues(alpha: 0.2),
                      thumbColor: AppColors.success,
                      overlayColor: AppColors.success.withValues(alpha: 0.12),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: extra,
                      min: 0,
                      max: 2000,
                      divisions: 80,
                      onChanged: (v) =>
                          ref.read(extraPaymentProvider.notifier).state = v,
                    ),
                  ),
                ),
                Text(
                  '\$2K',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),

            // Current value label
            Center(
              child: Text(
                extra == 0
                    ? 'extraPayment.moveSlider'.tr()
                    : 'extraPayment.extraPerMonth'.tr(namedArgs: {'amount': currencyFormat.format(extra)}),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: extra == 0
                          ? AppColors.textSecondary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Impact summary
            if (monthsSaved != null && interestSaved != null && extra > 0) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Column(
                  children: [
                    _ImpactRow(
                      icon: CupertinoIcons.calendar,
                      text: monthsSaved > 0
                          ? 'extraPayment.payOffSooner'.tr(namedArgs: {'months': '$monthsSaved'})
                          : 'extraPayment.sameTimeline'.tr(),
                    ),
                    if (interestSaved > 0) ...[
                      const SizedBox(height: 4),
                      _ImpactRow(
                        icon: CupertinoIcons.money_dollar,
                        text: 'extraPayment.saveInInterest'.tr(namedArgs: {'amount': currencyFormat.format(interestSaved)}),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ImpactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
