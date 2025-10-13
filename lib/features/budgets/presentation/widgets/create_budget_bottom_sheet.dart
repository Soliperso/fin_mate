import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../transactions/domain/entities/category_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';

class CreateBudgetBottomSheet extends ConsumerStatefulWidget {
  final BudgetEntity? budget; // If provided, we're editing

  const CreateBudgetBottomSheet({
    super.key,
    this.budget,
  });

  @override
  ConsumerState<CreateBudgetBottomSheet> createState() => _CreateBudgetBottomSheetState();
}

class _CreateBudgetBottomSheetState extends ConsumerState<CreateBudgetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  CategoryEntity? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toString();
      _selectedPeriod = widget.budget!.period;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider('expense'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardBackgroundDark.withValues(alpha: 0.95)
                  : AppColors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
              border: Border.all(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.1)
                    : AppColors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Title
                  Text(
                    widget.budget == null ? 'Create Budget' : 'Edit Budget',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Category Selection
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  categoriesState.when(
                    data: (categories) => DropdownButtonFormField<CategoryEntity>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        hintText: 'Select a category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const Text('Failed to load categories'),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Amount
                  Text(
                    'Budget Amount',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Period
                  Text(
                    'Budget Period',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<BudgetPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: BudgetPeriod.weekly,
                        label: Text('Weekly'),
                      ),
                      ButtonSegment(
                        value: BudgetPeriod.monthly,
                        label: Text('Monthly'),
                      ),
                      ButtonSegment(
                        value: BudgetPeriod.yearly,
                        label: Text('Yearly'),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<BudgetPeriod> selection) {
                      setState(() {
                        _selectedPeriod = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Start Date
                  Text(
                    'Start Date',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // End Date (Optional)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'End Date (Optional)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (_endDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _endDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                            : 'Select end date',
                        style: TextStyle(
                          color: _endDate != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveBudget,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.budget == null ? 'Create' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      final budget = BudgetEntity(
        id: widget.budget?.id ?? '',
        userId: widget.budget?.userId ?? '', // This will be set by Supabase
        categoryId: _selectedCategory!.id,
        amount: amount,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        isActive: true,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
      );

      if (widget.budget == null) {
        await ref.read(budgetNotifierProvider.notifier).createBudget(budget);
      } else {
        await ref.read(budgetNotifierProvider.notifier).updateBudget(widget.budget!.id, budget);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.budget == null ? 'Budget created successfully' : 'Budget updated successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to save budget: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
