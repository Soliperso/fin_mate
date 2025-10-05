import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
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
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Transactions list
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add transaction functionality
          _showAddTransactionDialog();
        },
        backgroundColor: AppColors.emeraldGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Mock transactions data - replace with actual data later
    final mockTransactions = [
      {
        'title': 'Salary',
        'category': 'Income',
        'amount': 5000.00,
        'date': 'Today, 10:30 AM',
        'type': 'income',
        'icon': Icons.attach_money,
      },
      {
        'title': 'Grocery Shopping',
        'category': 'Food & Dining',
        'amount': -85.50,
        'date': 'Yesterday, 3:45 PM',
        'type': 'expense',
        'icon': Icons.shopping_cart,
      },
      {
        'title': 'Electric Bill',
        'category': 'Utilities',
        'amount': -120.00,
        'date': 'Dec 3, 2024',
        'type': 'expense',
        'icon': Icons.bolt,
      },
      {
        'title': 'Freelance Project',
        'category': 'Income',
        'amount': 1200.00,
        'date': 'Dec 2, 2024',
        'type': 'income',
        'icon': Icons.work,
      },
      {
        'title': 'Coffee Shop',
        'category': 'Food & Dining',
        'amount': -12.50,
        'date': 'Dec 2, 2024',
        'type': 'expense',
        'icon': Icons.coffee,
      },
      {
        'title': 'Transfer to Savings',
        'category': 'Transfer',
        'amount': -500.00,
        'date': 'Dec 1, 2024',
        'type': 'transfer',
        'icon': Icons.swap_horiz,
      },
    ];

    // Filter transactions based on selected filter
    final filteredTransactions = _selectedFilter == 'All'
        ? mockTransactions
        : mockTransactions.where((t) {
            if (_selectedFilter == 'Income') return t['type'] == 'income';
            if (_selectedFilter == 'Expense') return t['type'] == 'expense';
            if (_selectedFilter == 'Transfer') return t['type'] == 'transfer';
            return true;
          }).toList();

    if (filteredTransactions.isEmpty) {
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
              'No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: filteredTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final amount = transaction['amount'] as double;
        final isIncome = amount > 0;
        final isTransfer = transaction['type'] == 'transfer';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.sm),
            side: BorderSide(color: AppColors.borderLight),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            leading: CircleAvatar(
              backgroundColor: isIncome
                  ? AppColors.success.withValues(alpha: 0.2)
                  : isTransfer
                      ? AppColors.royalPurple.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
              child: Icon(
                transaction['icon'] as IconData,
                color: isIncome
                    ? AppColors.success
                    : isTransfer
                        ? AppColors.royalPurple
                        : AppColors.error,
              ),
            ),
            title: Text(
              transaction['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  transaction['category'] as String,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['date'] as String,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${amount > 0 ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome
                    ? AppColors.success
                    : isTransfer
                        ? AppColors.royalPurple
                        : AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // TODO: Show transaction details
            },
          ),
        );
      },
    );
  }

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.md)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Transaction',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Transaction functionality coming soon!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
