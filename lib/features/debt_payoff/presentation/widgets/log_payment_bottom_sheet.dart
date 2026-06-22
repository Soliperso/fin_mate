import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../savings_goals/presentation/widgets/goal_achievement_dialog.dart';
import '../../domain/entities/debt_entity.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class LogPaymentBottomSheet extends ConsumerStatefulWidget {
  final DebtEntity debt;

  const LogPaymentBottomSheet({super.key, required this.debt});

  @override
  ConsumerState<LogPaymentBottomSheet> createState() =>
      _LogPaymentBottomSheetState();
}

class _LogPaymentBottomSheetState extends ConsumerState<LogPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill the minimum payment, but never more than what's still owed.
    final suggested = widget.debt.minimumPayment > widget.debt.balance
        ? widget.debt.balance
        : widget.debt.minimumPayment;
    _amountController = TextEditingController(
      text: suggested.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat(AppDateFormats.mediumDate).format(date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Capture the root navigator synchronously (before the async gap) so the
    // paid-off celebration can be shown after the sheet closes.
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    final payment = await ref.read(debtNotifierProvider.notifier).logPayment(
          debtId: widget.debt.id,
          amount: double.parse(_amountController.text),
          paymentDate: _selectedDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (payment != null) {
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      ref.invalidate(debtPaymentsProvider(widget.debt.id));
      // Did this payment clear the debt? Capture before popping.
      final nowPaidOff =
          (widget.debt.balance - double.parse(_amountController.text)) <= 0.001;
      final debtName = widget.debt.name;
      Navigator.pop(context, nowPaidOff);
      // Show the celebration via the root navigator context (captured above)
      // so it survives the sheet closing — works from any entry point.
      if (nowPaidOff) {
        showDebtPaidOffCelebration(rootNavigator.context, debtName);
      }
    } else {
      showErrorDialog(context, 'Failed to log payment. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'logPayment.title'.tr(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          widget.debt.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    CircularIconButton(
                      icon: CupertinoIcons.xmark,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'logPayment.amountLabel'.tr(),
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'common.required'.tr();
                    final amount = double.tryParse(v);
                    if (amount == null) return 'logPayment.invalidNumber'.tr();
                    if (amount <= 0)
                      return 'logPayment.mustBeGreaterThanZero'.tr();
                    // Can't pay more than what's owed on this debt.
                    if (amount - widget.debt.balance > 0.001) {
                      return 'logPayment.exceedsBalance'.tr(namedArgs: {
                        'amount': ref
                            .read(currencyFormat2Provider)
                            .format(widget.debt.balance),
                      });
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'logPayment.paymentDate'.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(CupertinoIcons.calendar),
                    ),
                    child: Text(_formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'logPayment.notes'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.lg),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('common.cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const LoadingIndicator(color: Colors.white)
                            : Text('logPayment.logButton'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the celebratory fireworks dialog when a debt is fully paid off.
/// Reuses the exact same [GoalAchievementDialog] as a reached savings goal, so
/// both milestones get the identical celebration. Shared by every place that
/// can log a payment (overview, detail page, track calendar).
void showDebtPaidOffCelebration(BuildContext context, String debtName) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => GoalAchievementDialog(
      title: 'debt.paidOffTitle'.tr(),
      message: 'debt.paidOffMessage'.tr(namedArgs: {'name': debtName}),
      showNewGoalButton: false,
    ),
  );
}
