import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/debt_entity.dart';
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
    _interestRateController = TextEditingController(
        text: widget.debt.interestRate.toStringAsFixed(2));
    _minimumPaymentController = TextEditingController(
        text: widget.debt.minimumPayment.toStringAsFixed(2));
    _dueDayController = TextEditingController(
        text: widget.debt.dueDay?.toString() ?? '');
    _notesController = TextEditingController(text: widget.debt.notes ?? '');
    _selectedDebtType = widget.debt.debtType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final fields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'debt_type': _selectedDebtType,
      'balance': double.parse(_balanceController.text),
      'interest_rate': double.parse(_interestRateController.text),
      'minimum_payment': double.parse(_minimumPaymentController.text),
      'due_day': _dueDayController.text.isEmpty
          ? null
          : int.tryParse(_dueDayController.text),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final success =
        await ref.read(debtNotifierProvider.notifier).updateDebt(widget.debt.id, fields);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Debt',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Debt Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSizes.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDebtType,
                  decoration: const InputDecoration(
                    labelText: 'Debt Type',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Current Balance (\$)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) < 0) return 'Must be 0 or more';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumPaymentController,
                        decoration: const InputDecoration(
                          labelText: 'Min. Payment (\$)',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          if (double.parse(v) <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _dueDayController,
                  decoration: const InputDecoration(
                    labelText: 'Due Day (optional)',
                    hintText: '1–31',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final day = int.tryParse(v);
                    if (day == null || day < 1 || day > 31) return 'Must be 1–31';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.lg),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
