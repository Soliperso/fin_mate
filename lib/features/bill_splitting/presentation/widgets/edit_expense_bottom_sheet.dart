import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../providers/bill_splitting_providers.dart';

class EditExpenseBottomSheet extends ConsumerStatefulWidget {
  final GroupExpense expense;
  final String groupId;

  const EditExpenseBottomSheet({
    super.key,
    required this.expense,
    required this.groupId,
  });

  @override
  ConsumerState<EditExpenseBottomSheet> createState() => _EditExpenseBottomSheetState();
}

class _EditExpenseBottomSheetState extends ConsumerState<EditExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late SplitType _splitType;
  String? _selectedCategory;

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Utilities',
    'Rent',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expense.description);
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _selectedDate = widget.expense.date;
    _splitType = widget.expense.splitType;
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await ref.read(expenseOperationsProvider.notifier).updateExpense(
            expenseId: widget.expense.id,
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            date: _selectedDate,
            category: _selectedCategory,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (success && mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(groupExpensesProvider(widget.groupId));
        ref.invalidate(groupBalancesProvider(widget.groupId));

        Navigator.of(context).pop(true);
        SuccessSnackbar.show(context, message: 'Expense updated successfully');
      } else if (mounted) {
        final errorState = ref.read(expenseOperationsProvider);
        ErrorSnackbar.show(
          context,
          message: 'Failed to update expense: ${errorState.hasError ? errorState.error : "Unknown error"}',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = ref.watch(expenseOperationsProvider);
    final isLoading = operationsState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Dinner at restaurant',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSizes.md),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSizes.md),

              // Date
              InkWell(
                onTap: isLoading ? null : _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
              ),
              const SizedBox(height: AppSizes.md),

              // Split Type (Read-only)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Split Type',
                  prefixIcon: Icon(Icons.pie_chart),
                  helperText: 'Split type cannot be changed after creation',
                ),
                child: Text(
                  _splitType.value.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSizes.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _updateExpense,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Expense'),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
