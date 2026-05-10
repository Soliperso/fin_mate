import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/savings_goal_providers.dart';

class CreateGoalBottomSheet extends ConsumerStatefulWidget {
  const CreateGoalBottomSheet({super.key});

  @override
  ConsumerState<CreateGoalBottomSheet> createState() =>
      _CreateGoalBottomSheetState();
}

class _CreateGoalBottomSheetState extends ConsumerState<CreateGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  DateTime? _selectedDeadline;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Emergency Fund',
    'Vacation',
    'Home Down Payment',
    'Car',
    'Education',
    'Retirement',
    'Wedding',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
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
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLg)),
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
                      'Create Savings Goal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Goal Name
                    Text(
                      'Goal Name',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter goal name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goal name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Description
                    Text(
                      'Description (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Optional description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Target Amount
                    Text(
                      'Target Amount',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter target amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Category
                    Text(
                      'Category (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        hintText: 'Select a category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Deadline
                    Text(
                      'Deadline (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDeadline = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(CupertinoIcons.calendar, size: 16),
                        ),
                        child: Text(
                          _selectedDeadline == null
                              ? 'Select deadline date'
                              : '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.brandTeal,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: _isLoading ? null : _createGoal,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text('Create'),
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

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final goal = await ref.read(goalOperationsProvider.notifier).createGoal(
            name: _nameController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            targetAmount: double.parse(_targetAmountController.text),
            deadline: _selectedDeadline,
            category: _selectedCategory,
          );

      if (mounted) {
        if (goal != null) {
          Navigator.of(context).pop(true);
          SuccessSnackbar.show(
            context,
            message: 'Savings goal "${goal.name}" created successfully',
          );
        } else {
          ErrorSnackbar.show(
            context,
            message: 'Failed to create goal. Please try again.',
          );
        }
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
