import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/debt_providers.dart';

class ExtraPaymentCard extends ConsumerWidget {
  const ExtraPaymentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = ref.watch(extraPaymentProvider);
    final baseResult = ref.watch(payoffResultProvider);
    final simResult = ref.watch(simulatedPayoffProvider);

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

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
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'What if you paid extra?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
                      max: 1000,
                      divisions: 40,
                      onChanged: (v) =>
                          ref.read(extraPaymentProvider.notifier).state = v,
                    ),
                  ),
                ),
                Text(
                  '\$1K',
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
                    ? 'Move slider to simulate'
                    : '+${currencyFormat.format(extra)}/month extra',
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
                      icon: Icons.calendar_today_outlined,
                      text: monthsSaved > 0
                          ? 'Pay off $monthsSaved months sooner'
                          : 'Same payoff timeline',
                    ),
                    if (interestSaved > 0) ...[
                      const SizedBox(height: 4),
                      _ImpactRow(
                        icon: Icons.savings_outlined,
                        text:
                            'Save ${currencyFormat.format(interestSaved)} in interest',
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
