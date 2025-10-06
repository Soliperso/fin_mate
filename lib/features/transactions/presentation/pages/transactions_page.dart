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
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Advanced filter options
  String? _selectedCategory;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  setState(() {
                    _searchQuery = value;
                  });
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
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters() ? AppColors.emeraldGreen : null,
            ),
            onPressed: _showFilterBottomSheet,
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
                      color: isSelected ? AppColors.emeraldGreen : Colors.transparent,
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(
            height: 1,
            color: AppColors.borderLight.withValues(alpha: 0.3),
          ),

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

    // Filter transactions based on selected filter, search query, and advanced filters
    var filteredTransactions = mockTransactions.where((t) {
      // Filter by type (All, Income, Expense, Transfer)
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Income' && t['type'] != 'income') return false;
        if (_selectedFilter == 'Expense' && t['type'] != 'expense') return false;
        if (_selectedFilter == 'Transfer' && t['type'] != 'transfer') return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final title = (t['title'] as String).toLowerCase();
        final category = (t['category'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !category.contains(query)) {
          return false;
        }
      }

      // Filter by category
      if (_selectedCategory != null && t['category'] != _selectedCategory) {
        return false;
      }

      // Filter by amount range
      final amount = (t['amount'] as double).abs();
      if (_minAmount != null && amount < _minAmount!) return false;
      if (_maxAmount != null && amount > _maxAmount!) return false;

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

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _dateRange != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  void _showFilterBottomSheet() {
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
                            _selectedCategory = null;
                            _dateRange = null;
                            _minAmount = null;
                            _maxAmount = null;
                          });
                          setState(() {});
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
                  Wrap(
                    spacing: AppSizes.sm,
                    children: [
                      'Income',
                      'Food & Dining',
                      'Utilities',
                      'Transfer',
                      'Shopping',
                      'Entertainment',
                    ].map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? category : null;
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
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setModalState(() {
                          _dateRange = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dateRange == null
                          ? 'Select Date Range'
                          : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dateRange != null ? AppColors.emeraldGreen : null,
                      side: BorderSide(
                        color: _dateRange != null ? AppColors.emeraldGreen : AppColors.borderLight,
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
                          decoration: const InputDecoration(
                            labelText: 'Min Amount',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setModalState(() {
                              _minAmount = double.tryParse(value);
                            });
                          },
                          controller: TextEditingController(
                            text: _minAmount?.toString() ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Max Amount',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setModalState(() {
                              _maxAmount = double.tryParse(value);
                            });
                          },
                          controller: TextEditingController(
                            text: _maxAmount?.toString() ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Apply Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Update the main page
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
          );
        },
      ),
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
