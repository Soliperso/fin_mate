import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh transactions when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  notifier.setSearchQuery(value);
                },
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  notifier.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: state.hasActiveFilters ? AppColors.emeraldGreen : null,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(context, 'All', state.selectedFilter, notifier),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip(context, 'Income', state.selectedFilter, notifier),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip(context, 'Expense', state.selectedFilter, notifier),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip(context, 'Transfer', state.selectedFilter, notifier),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: AppColors.borderLight.withValues(alpha: 0.3),
          ),

          // Transactions list
          Expanded(
            child: _buildTransactionsList(state, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/transactions/add');
          // Refresh transactions after returning from add page
          if (mounted) {
            ref.read(transactionListProvider.notifier).refresh();
          }
        },
        backgroundColor: AppColors.emeraldGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filter,
    String selectedFilter,
    TransactionListNotifier notifier,
  ) {
    final isSelected = filter == selectedFilter;
    return FilterChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (selected) {
        notifier.setFilter(filter);
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
      checkmarkColor: AppColors.emeraldGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.emeraldGreen : Colors.transparent,
      ),
    );
  }

  Widget _buildTransactionsList(
    TransactionListState state,
    TransactionListNotifier notifier,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Failed to load transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () => notifier.loadTransactions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              state.transactions.isEmpty
                  ? 'No transactions yet'
                  : 'No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (state.hasActiveFilters || state.searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () {
                  notifier.clearFilters();
                  notifier.setSearchQuery('');
                  _searchController.clear();
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: state.filteredTransactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, index) {
          final transaction = state.filteredTransactions[index];
          return _buildTransactionCard(context, transaction, notifier);
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? AppColors.success.withValues(alpha: 0.2)
              : isTransfer
                  ? AppColors.slateBlue.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
          child: Icon(
            _getTransactionIcon(transaction),
            color: isIncome
                ? AppColors.success
                : isTransfer
                    ? AppColors.slateBlue
                    : AppColors.error,
          ),
        ),
        title: Text(
          transaction.description ?? 'Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (transaction.categoryName != null)
              Text(
                transaction.categoryName!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(transaction.date),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (transaction.accountName != null)
              Text(
                transaction.accountName!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : isTransfer ? '' : '-'}${currencyFormat.format(transaction.amount.abs())}',
          style: TextStyle(
            color: isIncome
                ? AppColors.success
                : isTransfer
                    ? AppColors.slateBlue
                    : AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _showTransactionDetails(context, transaction, notifier),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionEntity transaction) {
    // Use category-based icons if available
    if (transaction.categoryName != null) {
      final category = transaction.categoryName!.toLowerCase();
      if (category.contains('food') || category.contains('dining')) {
        return Icons.restaurant;
      } else if (category.contains('transport') || category.contains('gas')) {
        return Icons.directions_car;
      } else if (category.contains('shopping')) {
        return Icons.shopping_bag;
      } else if (category.contains('entertainment')) {
        return Icons.movie;
      } else if (category.contains('utilities') || category.contains('bill')) {
        return Icons.bolt;
      } else if (category.contains('health')) {
        return Icons.local_hospital;
      } else if (category.contains('salary') || category.contains('income')) {
        return Icons.attach_money;
      }
    }

    // Default icons based on type
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Amount
            Text(
              currencyFormat.format(transaction.amount.abs()),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: transaction.type == TransactionType.income
                        ? AppColors.success
                        : transaction.type == TransactionType.transfer
                            ? AppColors.slateBlue
                            : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              transaction.type.toString().split('.').last.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Details
            _buildDetailRow('Description', transaction.description ?? 'N/A'),
            if (transaction.categoryName != null)
              _buildDetailRow('Category', transaction.categoryName!),
            if (transaction.accountName != null)
              _buildDetailRow('Account', transaction.accountName!),
            if (transaction.toAccountName != null)
              _buildDetailRow('To Account', transaction.toAccountName!),
            _buildDetailRow('Date', dateFormat.format(transaction.date)),
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _buildDetailRow('Notes', transaction.notes!),

            const SizedBox(height: AppSizes.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await context.push('/transactions/add?id=${transaction.id}');
                      // Refresh after editing
                      if (context.mounted) {
                        notifier.refresh();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emeraldGreen,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, transaction, notifier);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.deleteTransaction(transaction.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Transaction deleted successfully'
                          : 'Failed to delete transaction',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final state = ref.read(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);
    final categoriesAsync = ref.read(categoriesProvider(null));

    // Local state for the modal
    String? selectedCategory = state.selectedCategory;
    DateTimeRange? dateRange = state.dateRange;
    double? minAmount = state.minAmount;
    double? maxAmount = state.maxAmount;

    _minAmountController.text = minAmount?.toString() ?? '';
    _maxAmountController.text = maxAmount?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedCategory = null;
                              dateRange = null;
                              minAmount = null;
                              maxAmount = null;
                              _minAmountController.clear();
                              _maxAmountController.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Category Filter
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    categoriesAsync.when(
                      data: (categories) {
                        return Wrap(
                          spacing: AppSizes.sm,
                          children: categories.map((category) {
                            final isSelected = selectedCategory == category.name;
                            return FilterChip(
                              label: Text(category.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  selectedCategory = selected ? category.name : null;
                                });
                              },
                              backgroundColor: Colors.transparent,
                              selectedColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.emeraldGreen,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppColors.emeraldGreen : AppColors.borderLight,
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, stack) => const Text('Failed to load categories'),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: dateRange,
                        );
                        if (picked != null) {
                          setModalState(() {
                            dateRange = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        dateRange == null
                            ? 'Select Date Range'
                            : '${DateFormat('MMM d').format(dateRange!.start)} - ${DateFormat('MMM d, y').format(dateRange!.end)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dateRange != null ? AppColors.emeraldGreen : null,
                        side: BorderSide(
                          color: dateRange != null ? AppColors.emeraldGreen : AppColors.borderLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Amount Range Filter
                    Text(
                      'Amount Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Min Amount',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setModalState(() {
                                minAmount = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setModalState(() {
                                maxAmount = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        notifier.setCategory(selectedCategory);
                        notifier.setDateRange(dateRange);
                        notifier.setAmountRange(minAmount, maxAmount);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
