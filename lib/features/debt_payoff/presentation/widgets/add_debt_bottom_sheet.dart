import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class AddDebtBottomSheet extends ConsumerStatefulWidget {
  const AddDebtBottomSheet({super.key});

  @override
  ConsumerState<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends ConsumerState<AddDebtBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _originalBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedDebtType = 'credit_card';
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
    final debt = await ref.read(debtNotifierProvider.notifier).createDebt(
          name: _nameController.text.trim(),
          debtType: _selectedDebtType,
          balance: double.parse(_balanceController.text),
          interestRate: double.parse(_interestRateController.text),
          minimumPayment: double.parse(_minimumPaymentController.text),
          originalBalance:
              rawOriginal.isNotEmpty ? double.tryParse(rawOriginal) : null,
          dueDay: _dueDayController.text.isNotEmpty
              ? int.tryParse(_dueDayController.text)
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (debt != null) {
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      Navigator.pop(context, true);
    } else {
      showErrorDialog(context, 'Failed to add debt. Please try again.');
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
                      'addDebt.title'.tr(),
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

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'addDebt.debtNameLabel'.tr(),
                    hintText: 'addDebt.debtNameHint'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'addDebt.nameRequired'.tr()
                      : null,
                ),
                const SizedBox(height: AppSizes.md),

                // Debt Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedDebtType,
                  decoration: InputDecoration(
                    labelText: 'addDebt.debtType'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _debtTypes
                      .map((t) =>
                          DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedDebtType = v);
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Balance
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: 'addDebt.balance'.tr(),
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'common.required'.tr();
                    if (double.tryParse(v) == null)
                      return 'addDebt.invalidNumber'.tr();
                    if (double.parse(v) < 0)
                      return 'addDebt.mustBeZeroOrMore'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Credit Limit / Original Balance (optional)
                TextFormField(
                  controller: _originalBalanceController,
                  decoration: InputDecoration(
                    labelText: _selectedDebtType == 'credit_card'
                        ? 'addDebt.creditLimit'.tr()
                        : 'addDebt.originalBalance'.tr(),
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                    border: const OutlineInputBorder(),
                    helperText: 'addDebt.originalBalanceHelper'.tr(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (double.tryParse(v) == null)
                      return 'addDebt.invalidNumber'.tr();
                    if (double.parse(v) < 0)
                      return 'addDebt.mustBeZeroOrMore'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                Row(
                  children: [
                    // Interest Rate
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: InputDecoration(
                          labelText: 'addDebt.interestRate'.tr(),
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'common.required'.tr();
                          if (double.tryParse(v) == null)
                            return 'addDebt.invalidNumber'.tr();
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    // Minimum Payment
                    Expanded(
                      child: TextFormField(
                        controller: _minimumPaymentController,
                        decoration: InputDecoration(
                          labelText: 'addDebt.minPayment'.tr(),
                          prefixText: '${ref.watch(currencySymbolProvider)} ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'common.required'.tr();
                          if (double.tryParse(v) == null)
                            return 'addDebt.invalidNumber'.tr();
                          if (double.parse(v) <= 0)
                            return 'addDebt.mustBeGreaterThanZero'.tr();
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Due Day (optional)
                TextFormField(
                  controller: _dueDayController,
                  decoration: InputDecoration(
                    labelText: 'addDebt.dueDay'.tr(),
                    hintText: 'addDebt.dueDayHint'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final day = int.tryParse(v);
                    if (day == null || day < 1 || day > 31)
                      return 'addDebt.mustBe1to31'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'addDebt.notes'.tr(),
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
                            : Text('addDebt.addButton'.tr()),
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
