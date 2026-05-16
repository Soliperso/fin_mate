import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../providers/recurring_transactions_providers.dart';

class AddRecurringTransactionPage extends ConsumerStatefulWidget {
  final RecurringTransactionEntity? transaction;

  const AddRecurringTransactionPage({super.key, this.transaction});

  @override
  ConsumerState<AddRecurringTransactionPage> createState() =>
      _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState
    extends ConsumerState<AddRecurringTransactionPage> {
  late String _type;
  String? _accountId;
  String? _categoryId;
  late double _amount;
  late String? _description;
  late RecurringFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  late DateTime _nextOccurrence;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.transaction!;
      _type = t.type;
      _accountId = t.accountId;
      _categoryId = t.categoryId;
      _amount = t.amount;
      _description = t.description;
      _frequency = t.frequency;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _nextOccurrence = t.nextOccurrence;
      _amountController.text = t.amount.toStringAsFixed(2);
      _descriptionController.text = t.description ?? '';
    } else {
      _type = 'expense';
      _accountId = null;
      _categoryId = null;
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
          if (!isEditing) _nextOccurrence = picked;
        }
      });
    }
  }

  Future<void> _selectNextOccurrence(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextOccurrence,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextOccurrence = picked);
  }

  Future<void> _submit() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    try {
      final notifier =
          ref.read(recurringTransactionsOperationsProvider.notifier);

      if (isEditing) {
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

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Widget _typeTab(String type, String label, bool isDark) {
    final isSelected = _type == type;
    final selectedColor =
        type == 'expense' ? AppColors.systemRed : AppColors.systemGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _categoryId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull - 3),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedColor : AppColors.secondaryLabel,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _datePickerField(BuildContext context, bool isDark, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.tertiarySystemBackgroundDark
            : AppColors.systemGray6,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat(AppDateFormats.mediumDate).format(date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Icon(CupertinoIcons.calendar, color: AppColors.brandTeal, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider(_type));

    accountsAsync.whenData((accounts) {
      if (!isEditing && _accountId == null && accounts.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _accountId = accounts.first.id);
        });
      }
    });

    final sectionBg =
        isDark ? AppColors.tertiarySystemBackgroundDark : AppColors.systemGray6;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          isEditing
              ? 'Edit Recurring Transaction'
              : 'Add Recurring Transaction',
        ),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding,
          vertical: AppSizes.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.tertiarySystemBackgroundDark
                    : AppColors.systemGray5,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _typeTab('expense', 'Expense', isDark),
                  _typeTab('income', 'Income', isDark),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Amount section
            _sectionLabel(
                context, CupertinoIcons.money_dollar_circle, 'Amount'),
            const SizedBox(height: AppSizes.xs),
            Container(
              decoration: BoxDecoration(
                color: sectionBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    ref.watch(currencySymbolProvider),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      onChanged: (value) =>
                          setState(() => _amount = double.tryParse(value) ?? 0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Details section
            _sectionLabel(context, CupertinoIcons.doc_text, 'Details'),
            const SizedBox(height: AppSizes.xs),
            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Description (e.g. Monthly rent, Gym subscription)',
                filled: true,
                fillColor: sectionBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm + 2,
                ),
              ),
              onChanged: (value) => setState(() => _description = value),
            ),
            const SizedBox(height: AppSizes.xs),
            // Account + Category side by side
            Row(
              children: [
                Expanded(
                  child: accountsAsync.when(
                    data: (accounts) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _accountId,
                      items: accounts
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _accountId = value),
                      validator: (value) =>
                          value == null ? 'Please select an account' : null,
                      decoration: InputDecoration(
                        hintText: 'Account *',
                        filled: true,
                        fillColor: sectionBg,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm + 2,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _categoryId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No category'),
                        ),
                        ...categories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                      decoration: InputDecoration(
                        hintText: 'Category',
                        filled: true,
                        fillColor: sectionBg,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm + 2,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Frequency section
            _sectionLabel(context, CupertinoIcons.repeat, 'Frequency'),
            const SizedBox(height: AppSizes.xs),
            Row(
              children: RecurringFrequency.values.map((freq) {
                final selected = _frequency == freq;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = freq),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brandTeal : sectionBg,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color: selected
                              ? AppColors.brandTeal
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          freq.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.lg),

            // Dates section — start + next occurrence side by side
            _sectionLabel(context, CupertinoIcons.calendar, 'Schedule'),
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: _datePickerField(context, isDark, _startDate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Due',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectNextOccurrence(context),
                        child: _datePickerField(
                          context,
                          isDark,
                          _nextOccurrence,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // End Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'End Date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (_endDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _endDate = null),
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endDate != null
                          ? DateFormat(AppDateFormats.mediumDate).format(_endDate!)
                          : 'No end date (ongoing)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: _endDate != null
                                ? null
                                : AppColors.textSecondary,
                          ),
                    ),
                    Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.brandTeal,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Submit
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightMd,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandTeal,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                icon: const Icon(CupertinoIcons.checkmark_alt, size: 20),
                label: Text(
                  isEditing ? 'Update' : 'Save',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
