import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class ExtraPaymentCard extends ConsumerStatefulWidget {
  final double totalMinimum;

  const ExtraPaymentCard({super.key, this.totalMinimum = 0});

  @override
  ConsumerState<ExtraPaymentCard> createState() => _ExtraPaymentCardState();
}

class _ExtraPaymentCardState extends ConsumerState<ExtraPaymentCard> {
  void _showEditDialog(BuildContext context, double currentValue) {
    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toInt().toString() : '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        title: Text('extraPayment.title'.tr()),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            prefixText: '\$ ',
            suffixText: '/mo',
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              borderSide: const BorderSide(color: AppColors.success),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final parsed =
                  (double.tryParse(controller.text) ?? 0).clamp(0, 2000).toDouble();
              ref.read(extraPaymentProvider.notifier).setValue(parsed);
              Navigator.pop(dialogContext);
            },
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final extra = ref.watch(extraPaymentProvider);
    final baseResult = ref.watch(payoffResultProvider);
    final simResult = ref.watch(simulatedPayoffProvider);
    final currencyFormat = ref.watch(currencyFormat0Provider);

    int? monthsSaved;
    double? interestSaved;
    bool baseHitCap = false;
    if (extra > 0 && baseResult != null && simResult != null) {
      monthsSaved = baseResult.totalMonths - simResult.totalMonths;
      interestSaved =
          baseResult.totalInterestPaid - simResult.totalInterestPaid;
      baseHitCap = baseResult.hitMaxMonths;
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
            // ── Header ───────────────────────────────────────────────────────
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
                      if (widget.totalMinimum > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'extraPayment.requiredMinimum'.tr(namedArgs: {
                            'amount': currencyFormat.format(widget.totalMinimum)
                          }),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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

            // ── Tappable value badge ──────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => _showEditDialog(context, extra),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: extra > 0
                        ? AppColors.success.withValues(alpha: 0.10)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: extra > 0
                          ? AppColors.success.withValues(alpha: 0.35)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        extra > 0
                            ? '+${currencyFormat.format(extra)}/mo'
                            : 'extraPayment.moveSlider'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: extra > 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.pencil,
                        size: 13,
                        color: extra > 0
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Slider ───────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '\$0',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 22,
                      ),
                    ),
                    child: Slider(
                      value: extra,
                      min: 0,
                      max: 2000,
                      divisions: 80,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(extraPaymentProvider.notifier).setValue(v);
                      },
                    ),
                  ),
                ),
                Text(
                  '\$2K',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),

            // ── Impact panel ─────────────────────────────────────────────────
            if (extra > 0 && baseResult != null && simResult != null) ...[
              const SizedBox(height: AppSizes.md),
              if (baseHitCap) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'extraPayment.capWarning'.tr(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
              _ComparisonPanel(
                baseResult: baseResult,
                simResult: simResult,
                monthsSaved: monthsSaved,
                interestSaved: interestSaved,
                currencyFormat: currencyFormat,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Comparison panel ─────────────────────────────────────────────────────────

class _ComparisonPanel extends StatelessWidget {
  final dynamic baseResult;
  final dynamic simResult;
  final int? monthsSaved;
  final double? interestSaved;
  final NumberFormat currencyFormat;

  const _ComparisonPanel({
    required this.baseResult,
    required this.simResult,
    required this.monthsSaved,
    required this.interestSaved,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMM yyyy');
    final baseDate = monthFmt.format(baseResult.debtFreeDate);
    final simDate = monthFmt.format(simResult.debtFreeDate);
    final baseInterest = currencyFormat.format(baseResult.totalInterestPaid);
    final simInterest = currencyFormat.format(simResult.totalInterestPaid);

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Column headers
          Row(
            children: [
              Expanded(
                child: Text(
                  'extraPayment.currentPlan'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  'extraPayment.withExtraLabel'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Divider(
            height: 1,
            color: AppColors.success.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSizes.xs + 2),

          // Debt-free date row
          _ComparisonRow(
            icon: CupertinoIcons.calendar,
            baseValue: baseDate,
            simValue: simDate,
            savingsLabel: monthsSaved != null && monthsSaved! > 0
                ? 'extraPayment.moneySooner'
                    .tr(namedArgs: {'months': '$monthsSaved'})
                : null,
            context: context,
          ),
          const SizedBox(height: AppSizes.xs + 2),

          // Interest row
          _ComparisonRow(
            icon: CupertinoIcons.money_dollar_circle,
            baseValue: baseInterest,
            simValue: simInterest,
            savingsLabel: interestSaved != null && interestSaved! > 0
                ? 'extraPayment.interestSaved'
                    .tr(namedArgs: {'amount': currencyFormat.format(interestSaved!)})
                : null,
            context: context,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final IconData icon;
  final String baseValue;
  final String simValue;
  final String? savingsLabel;
  final BuildContext context;

  const _ComparisonRow({
    required this.icon,
    required this.baseValue,
    required this.simValue,
    required this.context,
    this.savingsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Base column
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  baseValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
        // Simulated column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      simValue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (savingsLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  '↓ $savingsLabel',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
