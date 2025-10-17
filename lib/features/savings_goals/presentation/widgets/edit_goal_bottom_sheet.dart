import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/savings_goal_providers.dart';

class EditGoalBottomSheet extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const EditGoalBottomSheet({
    super.key,
    required this.goal,
  });

  @override
  ConsumerState<EditGoalBottomSheet> createState() => _EditGoalBottomSheetState();
}

class _EditGoalBottomSheetState extends ConsumerState<EditGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetAmountController;

  DateTime? _selectedDeadline;
  String? _selectedCategory;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _descriptionController = TextEditingController(text: widget.goal.description ?? '');
    _targetAmountController = TextEditingController(
      text: widget.goal.targetAmount.toStringAsFixed(2),
    );
    _selectedDeadline = widget.goal.deadline;
    _selectedCategory = widget.goal.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref.read(goalOperationsProvider.notifier).updateGoal(
          goalId: widget.goal.id,
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          targetAmount: double.parse(_targetAmountController.text),
          deadline: _selectedDeadline,
          category: _selectedCategory,
        );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        Navigator.pop(context, true); // Close bottom sheet with success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update goal')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Savings Goal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Goal Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  prefixIcon: Icon(Icons.flag),
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.md),

              // Target Amount
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount greater than 0';
                  }
                  if (amount < widget.goal.currentAmount) {
                    return 'Target cannot be less than current amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  prefixIcon: Icon(Icons.category),
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
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDeadline = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Deadline (Optional)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                    suffixIcon: _selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedDeadline = null;
                              });
                            },
                          )
                        : null,
                  ),
                  child: Text(
                    _selectedDeadline == null
                        ? 'Select deadline date'
                        : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                    style: TextStyle(
                      color: _selectedDeadline == null
                          ? AppColors.textSecondary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Current Progress Info
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Current progress: \$${widget.goal.currentAmount.toStringAsFixed(2)} (${widget.goal.progress.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _updateGoal,
                  child: const Text('Update Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
