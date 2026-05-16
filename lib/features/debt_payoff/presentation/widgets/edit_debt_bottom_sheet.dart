import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/debt_entity.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class EditDebtBottomSheet extends ConsumerStatefulWidget {
  final DebtEntity debt;

  const EditDebtBottomSheet({super.key, required this.debt});

  @override
  ConsumerState<EditDebtBottomSheet> createState() =>
      _EditDebtBottomSheetState();
}

class _EditDebtBottomSheetState extends ConsumerState<EditDebtBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _originalBalanceController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _minimumPaymentController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;

  late String _selectedDebtType;
  bool _isSubmitting = false;

  static const _debtTypes = [
    ('credit_card', 'Credit Card'),
    ('personal_loan', 'Personal Loan'),
    ('student_loan', 'Student Loan'),
    ('auto_loan', 'Auto Loan'),
    ('mortgage', 'Mortgage'),
    ('medical', 'Medical'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.debt.name);
    _balanceController =
        TextEditingController(text: widget.debt.balance.toStringAsFixed(2));
    _originalBalanceController = TextEditingController(
        text: widget.debt.originalBalance?.toStringAsFixed(2) ?? '');
    _interestRateController = TextEditingController(
        text: widget.debt.interestRate.toStringAsFixed(2));
    _minimumPaymentController = TextEditingController(
        text: widget.debt.minimumPayment.toStringAsFixed(2));
    _dueDayController =
        TextEditingController(text: widget.debt.dueDay?.toString() ?? '');
    _notesController = TextEditingController(text: widget.debt.notes ?? '');
    _selectedDebtType = widget.debt.debtType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _originalBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final rawOriginal = _originalBalanceController.text.trim();
    final fields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'debt_type': _selectedDebtType,
      'balance': double.parse(_balanceController.text),
      if (rawOriginal.isNotEmpty && double.tryParse(rawOriginal) != null)
        'original_balance': double.parse(rawOriginal),
      'interest_rate': double.parse(_interestRateController.text),
      'minimum_payment': double.parse(_minimumPaymentController.text),
      'due_day': _dueDayController.text.isEmpty
          ? null
          : int.tryParse(_dueDayController.text),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final success = await ref
        .read(debtNotifierProvider.notifier)
        .updateDebt(widget.debt.id, fields);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      Navigator.pop(context, true);
    } else {
      showErrorDialog(context, 'Failed to update debt. Please try again.');
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    Text(
                      'editDebt.title'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    CircularIconButton(
                      icon: CupertinoIcons.xmark,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'editDebt.debtNameLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'common.required'.tr()
                      : null,
                ),
                const SizedBox(height: AppSizes.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDebtType,
                  decoration: InputDecoration(
                    labelText: 'editDebt.debtType'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _debtTypes
                      .map((t) =>
                          DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDebtType = v!),
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'editDebt.balance'.tr(),
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'common.required'.tr();
                    if (double.tryParse(v) == null)
                      return 'editDebt.invalidNumber'.tr();
                    if (double.parse(v) < 0)
                      return 'editDebt.mustBeZeroOrMore'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Credit Limit / Original Balance
                TextFormField(
                  controller: _originalBalanceController,
                  decoration: InputDecoration(
                    labelText: _selectedDebtType == 'credit_card'
                        ? 'editDebt.creditLimit'.tr()
                        : 'editDebt.originalBalance'.tr(),
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                    border: const OutlineInputBorder(),
                    helperText: 'addDebt.originalBalanceHelper'.tr(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (double.tryParse(v) == null)
                      return 'editDebt.invalidNumber'.tr();
                    if (double.parse(v) < 0)
                      return 'editDebt.mustBeZeroOrMore'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: InputDecoration(
                          labelText: 'editDebt.interestRate'.tr(),
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'common.required'.tr();
                          if (double.tryParse(v) == null)
                            return 'editDebt.invalidNumber'.tr();
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumPaymentController,
                        decoration: InputDecoration(
                          labelText: 'editDebt.minPayment'.tr(),
                          prefixText: '${ref.watch(currencySymbolProvider)} ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'common.required'.tr();
                          if (double.tryParse(v) == null)
                            return 'editDebt.invalidNumber'.tr();
                          if (double.parse(v) <= 0)
                            return 'editDebt.mustBeGreaterThanZero'.tr();
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _dueDayController,
                  decoration: InputDecoration(
                    labelText: 'editDebt.dueDay'.tr(),
                    hintText: 'editDebt.dueDayHint'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final day = int.tryParse(v);
                    if (day == null || day < 1 || day > 31)
                      return 'editDebt.mustBe1to31'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'editDebt.notes'.tr(),
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
                          backgroundColor: AppColors.brandTeal,
                          foregroundColor: AppColors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const LoadingIndicator(color: Colors.white)
                            : Text('editDebt.save'.tr()),
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
