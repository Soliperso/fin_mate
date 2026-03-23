import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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
        title: const Text('Recurring Transactions'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showAddForm(null),
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (transactions) {
          final filtered = _filterTransactions(transactions);

          return Column(
            children: [
              // Auto-generation coming soon banner
              Container(
                margin: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.systemBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info_circle,
                        color: AppColors.systemBlue, size: 16),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        'Automatic scheduling is coming soon. You\'ll be reminded when transactions are due.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.systemBlue,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
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
                              title: 'No Recurring Transactions',
                              message: 'Create recurring transactions to track your bills and income',
                              backgroundColor: AppColors.primaryTeal,
                            ),
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: const Text('Edit'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showAddForm(transaction);
                                          },
                                        ),
                                        ListTile(
                                          title: Text(
                                            transaction.isActive ? 'Deactivate' : 'Activate',
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _toggleActive(transaction);
                                          },
                                        ),
                                        ListTile(
                                          title: const Text(
                                            'Delete',
                                            style: TextStyle(color: AppColors.error),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteTransaction(transaction.id);
                                          },
                                        ),
                                      ],
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
