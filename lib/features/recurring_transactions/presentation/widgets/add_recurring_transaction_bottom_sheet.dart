import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../providers/recurring_transactions_providers.dart';

class AddRecurringTransactionBottomSheet extends ConsumerStatefulWidget {
  final RecurringTransactionEntity? transaction;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;

  const AddRecurringTransactionBottomSheet({
    super.key,
    this.transaction,
    required this.accounts,
    required this.categories,
  });

  @override
  ConsumerState<AddRecurringTransactionBottomSheet> createState() =>
      _AddRecurringTransactionBottomSheetState();
}

class _AddRecurringTransactionBottomSheetState
    extends ConsumerState<AddRecurringTransactionBottomSheet> {
  late String _type;
  late String? _accountId;
  late String? _categoryId;
  late double _amount;
  late String? _description;
  late RecurringFrequency _frequency;
  late DateTime _startDate;
  late DateTime? _endDate;
  late DateTime _nextOccurrence;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _accountId = widget.transaction!.accountId;
      _categoryId = widget.transaction!.categoryId;
      _amount = widget.transaction!.amount;
      _description = widget.transaction!.description;
      _frequency = widget.transaction!.frequency;
      _startDate = widget.transaction!.startDate;
      _endDate = widget.transaction!.endDate;
      _nextOccurrence = widget.transaction!.nextOccurrence;
      _amountController.text = _amount.toString();
      _descriptionController.text = _description ?? '';
    } else {
      _type = 'expense';
      _accountId = widget.accounts.isNotEmpty ? widget.accounts[0]['id'] : null;
      _categoryId = widget.categories.isNotEmpty ? widget.categories[0]['id'] : null;
      _amount = 0;
      _description = '';
      _frequency = RecurringFrequency.monthly;
      _startDate = DateTime.now();
      _endDate = null;
      _nextOccurrence = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? DateTime.now()) : _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isEndDate) {
          _endDate = picked;
        } else {
          _startDate = picked;
          _nextOccurrence = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_accountId == null || _amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final notifier = ref.read(recurringTransactionsOperationsProvider.notifier);

    if (widget.transaction != null) {
      // Edit mode
      await notifier.updateRecurringTransaction(
        id: widget.transaction!.id,
        accountId: _accountId,
        categoryId: _categoryId,
        type: _type,
        amount: _amount,
        description: _description?.isEmpty ?? true ? null : _description,
        frequency: _frequency.name,
        startDate: _startDate,
        endDate: _endDate,
        nextOccurrence: _nextOccurrence,
      );
    } else {
      // Create mode
      await notifier.createRecurringTransaction(
        accountId: _accountId!,
        categoryId: _categoryId,
        type: _type,
        amount: _amount,
        description: _description?.isEmpty ?? true ? null : _description,
        frequency: _frequency.name,
        startDate: _startDate,
        endDate: _endDate,
        nextOccurrence: _nextOccurrence,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Recurring Transaction' : 'Add Recurring Transaction',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Type selector
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == 'expense',
                    onSelected: (selected) {
                      if (selected) setState(() => _type = 'expense');
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == 'income',
                    onSelected: (selected) {
                      if (selected) setState(() => _type = 'income');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Amount
            Text('Amount', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _amount = double.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: AppSizes.lg),

            // Description
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'e.g., Monthly rent, Gym subscription',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onChanged: (value) {
                setState(() => _description = value);
              },
            ),
            const SizedBox(height: AppSizes.lg),

            // Account
            Text('Account', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              items: widget.accounts
                  .map((account) => DropdownMenuItem(
                        value: account['id'] as String,
                        child: Text(account['name'] as String),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _accountId = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Category
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No category'),
                ),
                ...widget.categories
                    .map((category) => DropdownMenuItem(
                          value: category['id'] as String,
                          child: Text(category['name'] as String),
                        )),
              ],
              onChanged: (value) {
                setState(() => _categoryId = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Frequency
            Text('Frequency', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            DropdownButtonFormField<RecurringFrequency>(
              initialValue: _frequency,
              items: RecurringFrequency.values
                  .map((freq) => DropdownMenuItem(
                        value: freq,
                        child: Text(freq.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _frequency = value ?? RecurringFrequency.monthly);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Start Date
            Text('Start Date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(_startDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Next Occurrence
            Text('Next Occurrence', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(_nextOccurrence)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // End Date (optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('End Date (Optional)', style: Theme.of(context).textTheme.titleSmall),
                if (_endDate != null)
                  TextButton(
                    onPressed: () => setState(() => _endDate = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endDate != null
                          ? DateFormat('MMM d, yyyy').format(_endDate!)
                          : 'No end date',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                child: Text(
                  isEditing ? 'Update Recurring Transaction' : 'Add Recurring Transaction',
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
