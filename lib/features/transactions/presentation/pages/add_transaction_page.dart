import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../providers/transaction_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final String? transactionType; // 'expense' or 'income'
  final String? transactionId; // For editing existing transaction

  const AddTransactionPage({
    this.transactionType,
    this.transactionId,
    super.key,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  TransactionEntity? _existingTransaction;

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionType != null) {
      _selectedType = widget.transactionType!;
    }

    // Load transaction data if editing
    if (widget.transactionId != null) {
      _loadTransactionData();
    }
  }

  Future<void> _loadTransactionData() async {
    setState(() => _isLoading = true);

    try {
      final transactions = ref.read(transactionListProvider).transactions;
      final transaction = transactions.firstWhere(
        (t) => t.id == widget.transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      setState(() {
        _existingTransaction = transaction;
        _amountController.text = transaction.amount.abs().toString();
        _descriptionController.text = transaction.description ?? '';
        _selectedType = transaction.type == TransactionType.income ? 'income' : 'expense';
        _selectedDate = transaction.date;

        // Load category name from the transaction
        final categoryProvider = ref.read(categoriesProvider(_selectedType).future);
        categoryProvider.then((categories) {
          final category = categories.firstWhere(
            (c) => c.id == transaction.categoryId,
            orElse: () => categories.first,
          );
          setState(() {
            _selectedCategory = category.name;
          });
        });
      });
    } catch (e) {
      print('[AddTransaction] Error loading transaction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return _selectedType == 'expense' ? _expenseCategories : _incomeCategories;
  }

  bool get _isEditing => widget.transactionId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(_isEditing
            ? 'Edit Transaction'
            : (_selectedType == 'expense' ? 'Add Expense' : 'Add Income')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton('expense', 'Expense', AppColors.error),
                    ),
                    Expanded(
                      child: _buildTypeButton('income', 'Income', AppColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                    ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.sm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Category Selection
              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.sm),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.sm),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),

              // Submit Button
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                child: Text(
                  _isEditing
                      ? 'Update Transaction'
                      : (_selectedType == 'expense' ? 'Add Expense' : 'Add Income'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = type == 'expense' ? _expenseCategories.first : _incomeCategories.first;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      print('[AddTransaction] Starting transaction submit...');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        print('[AddTransaction] Getting repository...');
        final repository = ref.read(transactionRepositoryProvider);

        // Get current user ID from Supabase
        final currentUserId = supabase.auth.currentUser?.id;
        print('[AddTransaction] Current user ID: $currentUserId');

        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        // Get accounts and categories
        print('[AddTransaction] Loading accounts...');
        var accountsList = await ref.read(accountsProvider.future);
        print('[AddTransaction] Found ${accountsList.length} accounts');

        // If no accounts exist, create a default one
        if (accountsList.isEmpty) {
          print('[AddTransaction] No accounts found, creating default Cash account...');
          final defaultAccount = await repository.createAccount(
            AccountEntity(
              id: '',
              userId: currentUserId,
              name: 'Cash',
              type: AccountType.cash,
              balance: 0,
              currency: 'USD',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          print('[AddTransaction] Default account created: ${defaultAccount.id}');
          accountsList = [defaultAccount];

          // Invalidate the accounts provider to refresh the cache
          ref.invalidate(accountsProvider);
        }

        print('[AddTransaction] Loading categories...');
        final categoriesAsync = await ref.read(categoriesProvider(
          _selectedType == 'expense' ? 'expense' : 'income',
        ).future);
        print('[AddTransaction] Found ${categoriesAsync.length} categories');

        // Find category ID by name
        final category = categoriesAsync.firstWhere(
          (c) => c.name == _selectedCategory,
          orElse: () => categoriesAsync.first,
        );
        print('[AddTransaction] Using category: ${category.name} (${category.id})');

        // Create transaction entity
        final amount = double.parse(_amountController.text);
        final type = _selectedType == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        print('[AddTransaction] Creating transaction: type=$type, amount=$amount, account=${accountsList.first.id}');
        final transaction = TransactionEntity(
          id: '', // Will be generated by database
          userId: currentUserId, // Use actual authenticated user ID
          type: type,
          amount: amount.abs(), // Database expects positive amounts only, type field distinguishes income/expense
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          accountId: accountsList.first.id,
          categoryId: category.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('[AddTransaction] Saving transaction to database...');
        if (_isEditing) {
          // Update existing transaction
          await repository.updateTransaction(widget.transactionId!, transaction);
          print('[AddTransaction] Transaction updated successfully!');
        } else {
          // Create new transaction
          await repository.createTransaction(transaction);
          print('[AddTransaction] Transaction created successfully!');
        }

        if (mounted) {
          print('[AddTransaction] Closing dialog and showing success message...');
          Navigator.pop(context); // Remove loading

          // Invalidate transaction providers to refresh the list
          ref.invalidate(transactionListProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Transaction updated successfully!'
                    : '${_selectedType == 'expense' ? 'Expense' : 'Income'} added successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } catch (e, stackTrace) {
        print('[AddTransaction] ERROR: $e');
        print('[AddTransaction] Stack trace: $stackTrace');

        if (mounted) {
          Navigator.pop(context); // Remove loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save transaction: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
