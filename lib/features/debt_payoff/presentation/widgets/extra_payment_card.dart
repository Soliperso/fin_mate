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
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(extraPaymentProvider);
    _controller = TextEditingController(
      text: initial > 0 ? initial.toInt().toString() : '',
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final parsed = double.tryParse(value) ?? 0;
    final clamped = parsed.clamp(0, 2000).toDouble();
    ref.read(extraPaymentProvider.notifier).setValue(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final extra = ref.watch(extraPaymentProvider);
    final baseResult = ref.watch(payoffResultProvider);
    final simResult = ref.watch(simulatedPayoffProvider);
    final currencyFormat = ref.watch(currencyFormat0Provider);

    // Sync slider → text field when not actively typing
    ref.listen<double>(extraPaymentProvider, (_, next) {
      if (!_focusNode.hasFocus) {
        final newText = next > 0 ? next.toInt().toString() : '';
        if (_controller.text != newText) _controller.text = newText;
      }
    });

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
            // Header
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

            // Value label — above the slider
            Center(
              child: Text(
                extra == 0
                    ? 'extraPayment.moveSlider'.tr()
                    : 'extraPayment.extraPerMonth'.tr(
                        namedArgs: {'amount': currencyFormat.format(extra)}),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: extra == 0
                          ? AppColors.textSecondary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Manual text input
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                prefixText: '\$ ',
                suffixText: '/mo',
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs + 2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: const BorderSide(color: AppColors.success),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
              ),
              onChanged: _onTextChanged,
              onSubmitted: (_) => _focusNode.unfocus(),
            ),
            const SizedBox(height: AppSizes.sm),

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
                          ref.read(extraPaymentProvider.notifier).setValue(v),
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

            // Impact summary
            if (monthsSaved != null &&
                interestSaved != null &&
                extra > 0 &&
                simResult != null) ...[
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ImpactRow(
                        icon: CupertinoIcons.exclamationmark_triangle,
                        iconColor: AppColors.warning,
                        textColor: AppColors.warning,
                        text: 'extraPayment.capWarning'.tr(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
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
                        text: 'extraPayment.withExtraPayoff'.tr(
                            namedArgs: {'months': '${simResult.totalMonths}'}),
                      ),
                      const SizedBox(height: 4),
                      _ImpactRow(
                        icon: CupertinoIcons.money_dollar,
                        text: 'extraPayment.withExtraInterest'.tr(namedArgs: {
                          'amount':
                              currencyFormat.format(simResult.totalInterestPaid)
                        }),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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
                            ? 'extraPayment.payOffSooner'
                                .tr(namedArgs: {'months': '$monthsSaved'})
                            : 'extraPayment.sameTimeline'.tr(),
                      ),
                      if (interestSaved > 0) ...[
                        const SizedBox(height: 4),
                        _ImpactRow(
                          icon: CupertinoIcons.money_dollar,
                          text: 'extraPayment.saveInInterest'.tr(namedArgs: {
                            'amount': currencyFormat.format(interestSaved)
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
  final Color? iconColor;
  final Color? textColor;

  const _ImpactRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.success;
    return Row(
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor ?? AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
