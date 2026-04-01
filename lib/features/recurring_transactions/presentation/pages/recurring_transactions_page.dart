import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/instant_fab_animator.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../providers/recurring_transactions_providers.dart';
import '../widgets/recurring_transaction_list_item.dart';

class RecurringTransactionsPage extends ConsumerStatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  ConsumerState<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState
    extends ConsumerState<RecurringTransactionsPage> {
  String _filterType = 'all'; // all, active, inactive

  void _showAddForm(RecurringTransactionEntity? transaction) {
    context.push('/recurring-transactions/add', extra: transaction);
  }

  void _deleteTransaction(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction?'),
        content: const Text('This recurring transaction will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recurringTransactionsOperationsProvider.notifier)
                  .deleteRecurringTransaction(id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleActive(RecurringTransactionEntity transaction) {
    ref
        .read(recurringTransactionsOperationsProvider.notifier)
        .toggleActiveStatus(transaction.id, !transaction.isActive);
  }

  Future<void> _markAsPaid(RecurringTransactionEntity transaction) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Create a transaction for today's payment
      final type = TransactionType.values.firstWhere(
        (t) => t.name == transaction.type,
        orElse: () => TransactionType.expense,
      );
      final now = DateTime.now();
      final newTransaction = TransactionEntity(
        id: '',
        userId: userId,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        type: type,
        amount: transaction.amount,
        description: transaction.description,
        date: now,
        isRecurring: true,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(transactionRepositoryProvider).createTransaction(newTransaction);

      // Advance nextOccurrence to the next cycle
      final next = _advanceOccurrence(transaction.nextOccurrence, transaction.frequency);
      await ref
          .read(recurringTransactionsOperationsProvider.notifier)
          .updateRecurringTransaction(
            id: transaction.id,
            nextOccurrence: next,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${transaction.description ?? 'Payment'} logged — next due ${_formatDate(next)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log payment: $e')),
        );
      }
    }
  }

  DateTime _advanceOccurrence(DateTime from, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  List<RecurringTransactionEntity> _filterTransactions(
    List<RecurringTransactionEntity> transactions,
  ) {
    switch (_filterType) {
      case 'active':
        return transactions.where((t) => t.isActive).toList();
      case 'inactive':
        return transactions.where((t) => !t.isActive).toList();
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Recurring Transactions'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.add,
              onTap: () => _showAddForm(null),
            ),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (transactions) {
          final filtered = _filterTransactions(transactions);

          return Column(
            children: [
              // Filter tabs
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterType == 'all',
                      onTap: () => setState(() => _filterType = 'all'),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _FilterChip(
                      label: 'Active',
                      selected: _filterType == 'active',
                      onTap: () => setState(() => _filterType = 'active'),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _FilterChip(
                      label: 'Inactive',
                      selected: _filterType == 'inactive',
                      onTap: () => setState(() => _filterType = 'inactive'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // List or empty state
              Expanded(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmptyStateCard(
                              icon: CupertinoIcons.doc_text,
                              title: _filterType == 'all'
                                  ? 'No Recurring Transactions'
                                  : 'No ${_filterType[0].toUpperCase()}${_filterType.substring(1)} Transactions',
                              message: _filterType == 'all'
                                  ? 'Create recurring transactions to track your bills and income'
                                  : 'There are no $_filterType recurring transactions right now',
                              backgroundColor: AppColors.primaryTeal,
                            ),
                            if (_filterType == 'all') ...[
                              const SizedBox(height: AppSizes.md),
                              SizedBox(
                                width: double.infinity,
                                height: AppSizes.buttonHeightMd,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddForm(null),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                    ),
                                  ),
                                  icon: const Icon(CupertinoIcons.add, size: 20),
                                  label: const Text(
                                    'Add Recurring Transaction',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(recurringTransactionsProvider.future),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppSizes.lg),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final transaction = filtered[index];
                            return Dismissible(
                              key: Key(transaction.id),
                              background: Container(
                                color: AppColors.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: AppSizes.lg,
                                ),
                                child: const Icon(
                                  CupertinoIcons.trash,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => _deleteTransaction(transaction.id),
                              child: GestureDetector(
                                onLongPress: () {
                                  GlassBottomSheet.show(
                                    context: context,
                                    child: _TransactionActionSheet(
                                      transaction: transaction,
                                      onEdit: () {
                                        Navigator.pop(context);
                                        _showAddForm(transaction);
                                      },
                                      onToggleActive: () {
                                        Navigator.pop(context);
                                        _toggleActive(transaction);
                                      },
                                      onDelete: () {
                                        Navigator.pop(context);
                                        _deleteTransaction(transaction.id);
                                      },
                                    ),
                                  );
                                },
                                child: RecurringTransactionListItem(
                                  transaction: transaction,
                                  onTap: () => _showAddForm(transaction),
                                  onDelete: () => _deleteTransaction(transaction.id),
                                  onToggleActive: (_) => _toggleActive(transaction),
                                  onMarkPaid: transaction.type == 'expense' && transaction.isActive
                                      ? () => _markAsPaid(transaction)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          children: List.generate(
            5,
            (index) => const SkeletonCard(
              height: 100,
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: EmptyStateCard(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Failed to Load',
              message: 'Unable to load recurring transactions. Please check your connection and try again.',
              backgroundColor: AppColors.error,
            ),
          ),
        ),
      ),
      floatingActionButtonAnimator: const InstantFabAnimator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: recurringAsync.valueOrNull?.isNotEmpty == true
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightMd,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddForm(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.add, size: 20),
                  label: const Text(
                    'Add Recurring Transaction',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.brandTeal.withValues(alpha: 0.2),
      showCheckmark: false,
      checkmarkColor: Colors.transparent,
      labelStyle: TextStyle(
        color: selected ? AppColors.brandTeal : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.brandTeal : Colors.transparent,
      ),
    );
  }
}

class _TransactionActionSheet extends StatelessWidget {
  final RecurringTransactionEntity transaction;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TransactionActionSheet({
    required this.transaction,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';
    final typeColor = isIncome
        ? AppColors.systemGreen
        : isExpense
            ? AppColors.systemRed
            : AppColors.primaryTeal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Transaction summary header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? CupertinoIcons.arrow_down_circle_fill
                      : isExpense
                          ? CupertinoIcons.arrow_up_circle_fill
                          : CupertinoIcons.arrow_left_right_circle_fill,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? 'Recurring ${transaction.type}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.frequency.displayName}  ·  ${transaction.isActive ? 'Active' : 'Inactive'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : isExpense ? '-' : ''}\$${transaction.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isIncome
                          ? AppColors.success
                          : isExpense
                              ? AppColors.error
                              : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        Divider(
          height: 1,
          color: Theme.of(context).dividerColor,
        ),

        // Edit
        _ActionRow(
          icon: CupertinoIcons.pencil,
          label: 'Edit',
          onTap: onEdit,
        ),

        Divider(
          height: 1,
          indent: AppSizes.md + 44 + AppSizes.sm,
          color: Theme.of(context).dividerColor,
        ),

        // Activate / Deactivate
        _ActionRow(
          icon: transaction.isActive
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.play_circle,
          label: transaction.isActive ? 'Deactivate' : 'Activate',
          onTap: onToggleActive,
        ),

        Divider(
          height: 1,
          color: Theme.of(context).dividerColor,
        ),
        const SizedBox(height: AppSizes.xs),

        // Delete — destructive, visually separated
        _ActionRow(
          icon: CupertinoIcons.trash,
          label: 'Delete',
          color: AppColors.error,
          onTap: onDelete,
        ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (color ?? AppColors.textSecondary).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: effectiveColor),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: effectiveColor,
                  ),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
