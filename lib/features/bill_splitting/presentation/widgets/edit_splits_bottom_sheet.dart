import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../providers/bill_splitting_providers.dart';

class EditSplitsBottomSheet extends ConsumerStatefulWidget {
  final String expenseId;
  final double expenseAmount;
  final String expenseDescription;
  final SplitType splitType;
  final String groupId;
  final List<GroupMember> groupMembers;

  const EditSplitsBottomSheet({
    super.key,
    required this.expenseId,
    required this.expenseAmount,
    required this.expenseDescription,
    required this.splitType,
    required this.groupId,
    required this.groupMembers,
  });

  @override
  ConsumerState<EditSplitsBottomSheet> createState() => _EditSplitsBottomSheetState();
}

class _EditSplitsBottomSheetState extends ConsumerState<EditSplitsBottomSheet> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _values = {};
    for (final member in widget.groupMembers) {
      _controllers[member.id] = TextEditingController();
      _values[member.id] = 0.0;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    return _values.values.fold(0, (sum, val) => sum + val);
  }

  double get _totalPercentage {
    return _values.values.fold(0, (sum, val) => sum + val);
  }

  bool get _isValid {
    if (widget.splitType == SplitType.percentage) {
      return (_totalPercentage - 100).abs() < 0.01; // Allow for floating point errors
    } else {
      return (_totalAmount - widget.expenseAmount).abs() < 0.01;
    }
  }

  void _updateValue(String memberId, double value) {
    setState(() {
      _values[memberId] = value;
    });
  }

  Future<void> _saveSplits() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.splitType == SplitType.percentage
                ? 'Percentages must add up to 100%'
                : 'Amounts must add up to \$${widget.expenseAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final splits = <String, double>{};
      for (final member in widget.groupMembers) {
        splits[member.userId] = _values[member.id]!;
      }

      final success = await ref.read(expenseOperationsProvider.notifier).createCustomSplits(
            expenseId: widget.expenseId,
            splits: splits,
          );

      if (success && mounted) {
        ref.invalidate(expenseSplitsProvider(widget.expenseId));
        ref.invalidate(groupExpensesProvider(widget.groupId));
        ref.invalidate(groupBalancesProvider(widget.groupId));
        Navigator.pop(context, true);
        SuccessSnackbar.show(context, message: 'Splits configured successfully');
      } else if (mounted) {
        ErrorSnackbar.show(context, message: 'Failed to configure splits');
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
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: AppColors.primaryTeal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure Splits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        widget.expenseDescription,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Expense Amount Display
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Expense',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    currencyFormat.format(widget.expenseAmount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Split Type Indicator
            Text(
              '${widget.splitType.value.toUpperCase()} SPLITS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Split Input Fields
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.groupMembers.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                final member = widget.groupMembers[index];
                final isCustom = widget.splitType == SplitType.custom;
                final label = isCustom ? 'Amount' : 'Percentage';
                final hint = isCustom ? '0.00' : '0.0%';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              TextFormField(
                                controller: _controllers[member.id],
                                decoration: InputDecoration(
                                  labelText: label,
                                  hintText: hint,
                                  isDense: true,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                onChanged: (val) {
                                  final numVal = double.tryParse(val) ?? 0.0;
                                  _updateValue(member.id, numVal);
                                },
                                enabled: !isLoading,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.lg),

            // Total Row
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: _isValid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: _isValid ? AppColors.success : AppColors.error,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isValid ? Icons.check_circle : Icons.error,
                        color: _isValid ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        widget.splitType == SplitType.percentage ? 'Total' : 'Total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.splitType == SplitType.percentage)
                        Text(
                          '${_totalPercentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isValid ? AppColors.success : AppColors.error,
                              ),
                        )
                      else
                        Text(
                          currencyFormat.format(_totalAmount),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isValid ? AppColors.success : AppColors.error,
                              ),
                        ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        widget.splitType == SplitType.percentage
                            ? 'Must be 100%'
                            : 'Must be ${currencyFormat.format(widget.expenseAmount)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: FilledButton(
                    onPressed: !isLoading && _isValid ? _saveSplits : null,
                    child: operationsState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Splits'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
