import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../providers/bill_splitting_providers.dart';
import 'edit_expense_bottom_sheet.dart';
import 'edit_splits_bottom_sheet.dart';

class ExpenseDetailBottomSheet extends ConsumerWidget {
  final GroupExpense expense;
  final String groupId;
  final String currentUserId;
  final List<GroupMember>? members;

  const ExpenseDetailBottomSheet({
    super.key,
    required this.expense,
    required this.groupId,
    required this.currentUserId,
    this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final isCurrentUser = expense.paidBy == currentUserId;
    final canEdit = isCurrentUser; // Only the person who paid can edit

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
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
                  Icons.receipt_long,
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
                      'Expense Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),

          // Amount
          _buildDetailRow(
            context,
            icon: Icons.attach_money,
            label: 'Amount',
            value: currencyFormat.format(expense.amount),
            valueColor: AppColors.primaryTeal,
            valueBold: true,
          ),
          const Divider(height: AppSizes.lg),

          // Paid By
          _buildDetailRow(
            context,
            icon: Icons.person,
            label: 'Paid by',
            value: isCurrentUser ? 'You' : 'Member',
          ),
          const Divider(height: AppSizes.lg),

          // Date
          _buildDetailRow(
            context,
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(expense.date),
          ),
          const Divider(height: AppSizes.lg),

          // Split Type
          _buildDetailRow(
            context,
            icon: Icons.pie_chart,
            label: 'Split Type',
            value: expense.splitType.value.toUpperCase(),
          ),

          // Category
          if (expense.category != null) ...[
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              icon: Icons.category,
              label: 'Category',
              value: expense.category!,
            ),
          ],

          // Notes
          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              icon: Icons.note,
              label: 'Notes',
              value: expense.notes!,
            ),
          ],

          const SizedBox(height: AppSizes.xl),

          // Split Configuration Section (for custom/percentage splits)
          if ((expense.splitType == SplitType.custom || expense.splitType == SplitType.percentage) &&
              members != null &&
              members!.isNotEmpty) ...[
            _buildSplitConfigurationSection(context, ref),
            const SizedBox(height: AppSizes.xl),
          ],

          // Action Buttons
          if (canEdit) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditExpenseSheet(context, ref),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, ref),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
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
                      'Only the person who paid can edit or delete this expense',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }

  Widget _buildSplitConfigurationSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Configuration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primaryTeal),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Configure how this ${expense.splitType.value} expense is split',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryTeal,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: members != null && members!.isNotEmpty
                      ? () => _showEditSplitsSheet(context)
                      : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Configure Splits'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueColor,
                      fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditExpenseSheet(BuildContext context, WidgetRef ref) {
    Navigator.pop(context); // Close detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditExpenseBottomSheet(
        expense: expense,
        groupId: groupId,
      ),
    ).then((updated) {
      if (updated == true) {
        // Data will refresh automatically via provider invalidation
      }
    });
  }

  void _showEditSplitsSheet(BuildContext context) {
    if (members == null || members!.isEmpty) return;

    Navigator.pop(context); // Close detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditSplitsBottomSheet(
        expenseId: expense.id,
        expenseAmount: expense.amount,
        expenseDescription: expense.description,
        splitType: expense.splitType,
        groupId: groupId,
        groupMembers: members!,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This will affect all group balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close bottom sheet

              final notifier = ref.read(expenseOperationsProvider.notifier);
              final success = await notifier.deleteExpense(expense.id);

              if (success && context.mounted) {
                ref.invalidate(groupExpensesProvider(groupId));
                ref.invalidate(groupBalancesProvider(groupId));
                SuccessSnackbar.show(context, message: 'Expense deleted successfully');
              } else if (context.mounted) {
                ErrorSnackbar.show(context, message: 'Failed to delete expense');
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
