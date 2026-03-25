import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
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
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final debt = await ref.read(debtNotifierProvider.notifier).createDebt(
          name: _nameController.text.trim(),
          debtType: _selectedDebtType,
          balance: double.parse(_balanceController.text),
          interestRate: double.parse(_interestRateController.text),
          minimumPayment: double.parse(_minimumPaymentController.text),
          dueDay: _dueDayController.text.isNotEmpty
              ? int.tryParse(_dueDayController.text)
              : null,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
                      'Add Debt',
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

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Debt Name',
                    hintText: 'e.g., Chase Sapphire, Car Loan',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                ),
                const SizedBox(height: AppSizes.md),

                // Debt Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedDebtType,
                  decoration: const InputDecoration(
                    labelText: 'Debt Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _debtTypes
                      .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDebtType = v!),
                ),
                const SizedBox(height: AppSizes.md),

                // Balance
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance (\$)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    // Interest Rate
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    // Minimum Payment
                    Expanded(
                      child: TextFormField(
                        controller: _minimumPaymentController,
                        decoration: const InputDecoration(
                          labelText: 'Min. Payment (\$)',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                // Due Day (optional)
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

                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
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
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Add Debt'),
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
