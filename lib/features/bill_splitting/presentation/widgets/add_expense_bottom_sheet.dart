import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../providers/bill_splitting_providers.dart';

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseBottomSheet({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends ConsumerState<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  SplitType _splitType = SplitType.equal;
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

  Future<void> _createExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final expense = await ref.read(expenseOperationsProvider.notifier).createExpense(
            groupId: widget.groupId,
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            date: _selectedDate,
            category: _selectedCategory,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            splitType: _splitType,
          );

      if (expense != null && mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(groupExpensesProvider(widget.groupId));
        ref.invalidate(groupBalancesProvider(widget.groupId));

        Navigator.of(context).pop(true);
        SuccessSnackbar.show(context, message: 'Expense added successfully');
      } else if (mounted) {
        final errorState = ref.read(expenseOperationsProvider);
        ErrorSnackbar.show(
          context,
          message: 'Failed to add expense: ${errorState.hasError ? errorState.error : "Unknown error"}',
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
                    'Add Expense',
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
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
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
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: isLoading ? null : (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                hint: const Text('Select a category'),
              ),
              const SizedBox(height: AppSizes.md),

              // Split Type
              DropdownButtonFormField<SplitType>(
                initialValue: _splitType,
                decoration: const InputDecoration(
                  labelText: 'Split Type',
                  prefixIcon: Icon(Icons.pie_chart),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SplitType.equal,
                    child: Text('Equal Split'),
                  ),
                  DropdownMenuItem(
                    value: SplitType.custom,
                    child: Text('Custom Split'),
                  ),
                  DropdownMenuItem(
                    value: SplitType.percentage,
                    child: Text('Percentage Split'),
                  ),
                ],
                onChanged: isLoading ? null : (value) {
                  setState(() {
                    _splitType = value!;
                  });
                },
              ),
              if (_splitType != SplitType.equal) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          'Custom splits will be available after creating the expense',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              const SizedBox(height: AppSizes.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Cancel',
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: CustomButton(
                      label: 'Add Expense',
                      onPressed: isLoading ? null : _createExpense,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
