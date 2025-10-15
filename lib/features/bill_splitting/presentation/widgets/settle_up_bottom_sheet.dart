import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../domain/entities/group_balance_entity.dart';
import '../providers/bill_splitting_providers.dart';

class SettleUpBottomSheet extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupBalance> balances;
  final String currentUserId;

  const SettleUpBottomSheet({
    super.key,
    required this.groupId,
    required this.balances,
    required this.currentUserId,
  });

  @override
  ConsumerState<SettleUpBottomSheet> createState() => _SettleUpBottomSheetState();
}

class _SettleUpBottomSheetState extends ConsumerState<SettleUpBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedUserId;
  bool _isPayingUser = true; // true = I'm paying someone, false = someone is paying me

  @override
  void initState() {
    super.initState();
    _suggestSettlement();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _suggestSettlement() {
    // Find current user's balance
    final currentUserBalance = widget.balances.firstWhere(
      (b) => b.userId == widget.currentUserId,
      orElse: () => widget.balances.first,
    );

    if (currentUserBalance.balance < 0) {
      // User owes money - find someone they owe
      _isPayingUser = true;
      final creditors = widget.balances
          .where((b) => b.userId != widget.currentUserId && b.balance > 0)
          .toList();
      if (creditors.isNotEmpty) {
        _selectedUserId = creditors.first.userId;
        _amountController.text = currentUserBalance.balance.abs().toStringAsFixed(2);
      }
    } else if (currentUserBalance.balance > 0) {
      // User is owed money - find someone who owes them
      _isPayingUser = false;
      final debtors = widget.balances
          .where((b) => b.userId != widget.currentUserId && b.balance < 0)
          .toList();
      if (debtors.isNotEmpty) {
        _selectedUserId = debtors.first.userId;
        _amountController.text = debtors.first.balance.abs().toStringAsFixed(2);
      }
    }
  }

  List<GroupBalance> _getAvailableUsers() {
    if (_isPayingUser) {
      // Show users who are owed money (positive balance)
      return widget.balances
          .where((b) => b.userId != widget.currentUserId && b.balance > 0)
          .toList();
    } else {
      // Show users who owe money (negative balance)
      return widget.balances
          .where((b) => b.userId != widget.currentUserId && b.balance < 0)
          .toList();
    }
  }

  Future<void> _recordSettlement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    try {
      final settlement = await ref.read(settlementOperationsProvider.notifier).createSettlement(
            groupId: widget.groupId,
            toUserId: _isPayingUser ? _selectedUserId! : widget.currentUserId,
            amount: double.parse(_amountController.text.trim()),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (settlement != null && mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(groupBalancesProvider(widget.groupId));
        ref.invalidate(groupSettlementsProvider(widget.groupId));

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement recorded successfully')),
        );
      } else if (mounted) {
        final errorState = ref.read(settlementOperationsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record settlement: ${errorState.hasError ? errorState.error : "Unknown error"}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = ref.watch(settlementOperationsProvider);
    final isLoading = operationsState.isLoading;
    final availableUsers = _getAvailableUsers();

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
                    'Settle Up',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Payment Direction Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isLoading) {
                            setState(() {
                              _isPayingUser = true;
                              _selectedUserId = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          decoration: BoxDecoration(
                            color: _isPayingUser ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            'I paid',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: _isPayingUser ? FontWeight.bold : FontWeight.normal,
                              color: _isPayingUser ? AppColors.slateBlue : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isLoading) {
                            setState(() {
                              _isPayingUser = false;
                              _selectedUserId = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          decoration: BoxDecoration(
                            color: !_isPayingUser ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Text(
                            'I received',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: !_isPayingUser ? FontWeight.bold : FontWeight.normal,
                              color: !_isPayingUser ? AppColors.slateBlue : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Balance Summary
              _buildBalanceSummary(context),
              const SizedBox(height: AppSizes.lg),

              // User Selection
              if (availableUsers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textSecondary),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          _isPayingUser
                              ? 'No one in this group is owed money'
                              : 'No one in this group owes money',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(_isPayingUser), // Rebuild when payment direction changes
                  decoration: InputDecoration(
                    labelText: _isPayingUser ? 'Paid to' : 'Received from',
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: availableUsers.map((balance) {
                    return DropdownMenuItem(
                      value: balance.userId,
                      child: Text(balance.fullName ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedUserId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a user';
                    }
                    return null;
                  },
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

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add payment method or reference',
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
                      label: 'Record',
                      onPressed: isLoading || availableUsers.isEmpty ? null : _recordSettlement,
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

  Widget _buildBalanceSummary(BuildContext context) {
    final currentUserBalance = widget.balances.firstWhere(
      (b) => b.userId == widget.currentUserId,
      orElse: () => widget.balances.first,
    );

    final balance = currentUserBalance.balance;
    final isOwed = balance > 0;

    if (balance == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re all settled up!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You don\'t owe anyone and no one owes you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: (isOwed ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: (isOwed ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOwed ? Icons.arrow_downward : Icons.arrow_upward,
            color: isOwed ? AppColors.success : AppColors.error,
            size: 32,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwed ? 'You are owed' : 'You owe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${balance.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOwed ? AppColors.success : AppColors.error,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwed
                      ? 'Record when someone pays you'
                      : 'Record a payment to settle your balance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
