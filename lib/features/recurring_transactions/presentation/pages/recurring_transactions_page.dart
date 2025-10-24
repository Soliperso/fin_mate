import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../providers/recurring_transactions_providers.dart';
import '../widgets/recurring_transaction_list_item.dart';
import '../widgets/add_recurring_transaction_bottom_sheet.dart';

class RecurringTransactionsPage extends ConsumerStatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  ConsumerState<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState
    extends ConsumerState<RecurringTransactionsPage> {
  String _filterType = 'all'; // all, active, inactive
  final List<Map<String, dynamic>> _accounts = [];
  final List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // TODO: Load accounts and categories from repository
    // For now, using empty lists
  }

  void _showAddForm(RecurringTransactionEntity? transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddRecurringTransactionBottomSheet(
        transaction: transaction,
        accounts: _accounts,
        categories: _categories,
      ),
    );
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
            icon: const Icon(Icons.add),
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: EmptyStateCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Recurring Transactions',
                            message: 'Create recurring transactions to track your bills and income',
                            backgroundColor: AppColors.primaryTeal,
                          ),
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
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => _deleteTransaction(transaction.id),
                              child: GestureDetector(
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Column(
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
              icon: Icons.error_outline,
              title: 'Failed to Load',
              message: 'Unable to load recurring transactions. Please check your connection and try again.',
              backgroundColor: AppColors.error,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring Transaction'),
      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryTeal,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          child: Text(label),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: selected ? AppColors.tealDark : AppColors.primaryTeal.withValues(alpha: 0.1),
        side: BorderSide(
          color: selected ? AppColors.tealDark : AppColors.borderLight,
          width: selected ? 0 : 1,
        ),
        showCheckmark: false,
      ),
    );
  }
}
