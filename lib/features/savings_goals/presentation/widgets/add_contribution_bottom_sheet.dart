import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/savings_goal_providers.dart';

class AddContributionBottomSheet extends ConsumerStatefulWidget {
  final String goalId;

  const AddContributionBottomSheet({
    super.key,
    required this.goalId,
  });

  @override
  ConsumerState<AddContributionBottomSheet> createState() =>
      _AddContributionBottomSheetState();
}

class _AddContributionBottomSheetState
    extends ConsumerState<AddContributionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  TransactionEntity? _linkedTransaction;

  @override
  void dispose() {
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

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(goalOperationsProvider.notifier);
      final amount = double.parse(_amountController.text);
      final contribution = await notifier.addContribution(
        goalId: widget.goalId,
        amount: amount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        transactionId: _linkedTransaction?.id,
      );

      if (contribution != null && mounted) {
        Navigator.pop(context,
            amount); // pass back the amount so caller can detect achievement
      } else if (mounted) {
        ErrorSnackbar.show(context, message: 'Failed to add contribution');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      'Add Contribution',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  CircularIconButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                autofocus: true,
              ),
              const SizedBox(height: AppSizes.md),

              // Date Field
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(CupertinoIcons.calendar, size: 16),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add a note about this contribution',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSizes.md),

              // Link to Transaction (optional)
              _TransactionPicker(
                selected: _linkedTransaction,
                onSelected: (tx) => setState(() {
                  _linkedTransaction = tx;
                  if (tx != null) {
                    _amountController.text = tx.amount.toStringAsFixed(2);
                  }
                }),
              ),
              const SizedBox(height: AppSizes.xl),

              // Submit Button
              SizedBox(
                height: AppSizes.buttonHeightMd,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: _isLoading ? null : _submitContribution,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Add Contribution'),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionPicker extends ConsumerWidget {
  final TransactionEntity? selected;
  final ValueChanged<TransactionEntity?> onSelected;

  const _TransactionPicker({required this.selected, required this.onSelected});

  String _label(TransactionEntity tx) {
    final parts = <String>[];
    if (tx.categoryName != null) parts.add(tx.categoryName!);
    if (tx.description != null && tx.description!.isNotEmpty) {
      parts.add(tx.description!);
    }
    final name = parts.isNotEmpty ? parts.join(' · ') : tx.type.displayName;
    final date = DateFormat('MMM d').format(tx.date);
    return '\$${tx.amount.toStringAsFixed(2)} — $name — $date';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentTransactionsProvider);

    return txAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<TransactionEntity?>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Link to Transaction (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(CupertinoIcons.link, size: 16),
          ),
          items: [
            const DropdownMenuItem<TransactionEntity?>(
              value: null,
              child: Text('None'),
            ),
            ...transactions.map(
              (tx) => DropdownMenuItem<TransactionEntity?>(
                value: tx,
                child: Text(
                  _label(tx),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onSelected,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
