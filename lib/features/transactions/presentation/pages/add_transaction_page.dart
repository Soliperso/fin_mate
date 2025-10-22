import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

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
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Groceries',
    'Restaurants',
    'Transportation',
    'Gas',
    'Car Maintenance',
    'Public Transit',
    'Ride Share',
    'Housing',
    'Rent',
    'Mortgage',
    'Home Maintenance',
    'Utilities',
    'Electricity',
    'Water',
    'Internet',
    'Phone',
    'Car Payment',
    'Insurance',
    'Car Insurance',
    'Health Insurance',
    'Home Insurance',
    'Shopping',
    'Clothing',
    'Personal Care',
    'Electronics',
    'Entertainment',
    'Streaming Services',
    'Movies & Events',
    'Hobbies',
    'Healthcare',
    'Medical Expenses',
    'Medications',
    'Fitness',
    'Education',
    'Tuition',
    'Books & Courses',
    'Childcare',
    'Pets',
    'Pet Food',
    'Vet Expenses',
    'Travel',
    'Vacation',
    'Flights',
    'Hotels',
    'Subscriptions',
    'Gifts & Donations',
    'Debt Payments',
    'Loan Payments',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Hourly Wage',
    'Bonus',
    'Freelance',
    'Contract Work',
    'Side Gig',
    'Side Hustle',
    'Investment',
    'Stock Dividends',
    'Interest Income',
    'Rental Income',
    'Capital Gains',
    'Business Income',
    'Self-Employment',
    'Passive Income',
    'Refund',
    'Tax Refund',
    'Gift',
    'Inheritance',
    'Reimbursement',
    'Scholarship',
    'Government Benefits',
    'Unemployment',
    'Disability',
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
    try {
      final transactions = ref.read(transactionListProvider).transactions;
      final transaction = transactions.firstWhere(
        (t) => t.id == widget.transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      setState(() {
        _titleController.text = transaction.description ?? '';
        _amountController.text = transaction.amount.abs().toString();
        _descriptionController.text = transaction.notes ?? '';
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
      _logger.e('Error loading transaction', error: e);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

              // Title Input
              TextFormField(
                controller: _titleController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: _selectedType == 'expense'
                      ? 'e.g., Grocery shopping, Gas'
                      : 'e.g., Salary, Freelance work',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

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
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
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
              const SizedBox(height: AppSizes.md),

              // Category Selection
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
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
              const SizedBox(height: AppSizes.md),

              // Notes Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add additional details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
              ),
              const SizedBox(height: AppSizes.md),

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
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    elevation: 2,
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
      _logger.d('Starting transaction submit...');

      // Show loading indicator
      late BuildContext loadingDialogContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        _logger.d('Getting repository...');
        final repository = ref.read(transactionRepositoryProvider);

        // Get current user ID from Supabase
        final currentUserId = supabase.auth.currentUser?.id;
        _logger.d('Current user ID: $currentUserId');

        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        // Get accounts and categories
        _logger.d('Loading accounts...');
        var accountsList = await ref.read(accountsProvider.future);
        _logger.d('Found ${accountsList.length} accounts');

        // If no accounts exist, create a default one
        if (accountsList.isEmpty) {
          _logger.d('No accounts found, creating default Cash account...');
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
          _logger.d('Default account created: ${defaultAccount.id}');
          accountsList = [defaultAccount];

          // Invalidate the accounts provider to refresh the cache
          ref.invalidate(accountsProvider);
        }

        _logger.d('Loading categories...');
        final categoriesAsync = await ref.read(categoriesProvider(
          _selectedType == 'expense' ? 'expense' : 'income',
        ).future);
        _logger.d('Found ${categoriesAsync.length} categories');

        // Find category ID by name
        final category = categoriesAsync.firstWhere(
          (c) => c.name == _selectedCategory,
          orElse: () => categoriesAsync.first,
        );
        _logger.d('Using category: ${category.name} (${category.id})');

        // Create transaction entity
        final amount = double.parse(_amountController.text);
        final type = _selectedType == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        _logger.d('Creating transaction: type=$type, amount=$amount, account=${accountsList.first.id}');
        final transaction = TransactionEntity(
          id: '', // Will be generated by database
          userId: currentUserId, // Use actual authenticated user ID
          type: type,
          amount: amount.abs(), // Database expects positive amounts only, type field distinguishes income/expense
          description: _titleController.text.trim(),
          notes: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          date: _selectedDate,
          accountId: accountsList.first.id,
          categoryId: category.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _logger.d('Saving transaction to database...');
        if (_isEditing) {
          // Update existing transaction
          await repository.updateTransaction(widget.transactionId!, transaction);
          _logger.d('Transaction updated successfully!');
        } else {
          // Create new transaction
          await repository.createTransaction(transaction);
          _logger.d('Transaction created successfully!');
        }

        // Invalidate dashboard and related providers to refresh cached data
        _logger.d('Invalidating providers to refresh dashboard...');
        ref.invalidate(dashboardNotifierProvider);
        ref.invalidate(transactionListProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(monthlyFlowDataProvider);
        ref.invalidate(netWorthSnapshotsProvider);

        if (mounted) {
          _logger.d('Closing loading dialog...');
          // Use the loading dialog context to pop the loading dialog - do this in a safe context
          unawaited(
            Future.microtask(() {
              if (loadingDialogContext.mounted) {
                Navigator.pop(loadingDialogContext);
              }
            }),
          );

          // Small delay to ensure loading dialog is closed
          await Future.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          _logger.d('Showing success dialog...');
          // Show success animation dialog
          await SuccessDialog.show(
            context,
            title: _isEditing ? 'Transaction Updated!' : 'Transaction Added!',
            message: _isEditing
                ? 'Your transaction has been updated successfully.'
                : '${_selectedType == 'expense' ? 'Expense' : 'Income'} has been added successfully!',
            autoDismissDuration: const Duration(milliseconds: 1500),
          );

          if (!mounted) return;

          _logger.d('Success dialog closed, popping page...');
          // Pop the transaction page
          context.pop(true); // Return true to indicate success
        }
      } catch (e, stackTrace) {
        _logger.e('Failed to save transaction', error: e, stackTrace: stackTrace);

        if (mounted) {
          // Use the loading dialog context to pop the loading dialog - do this in a safe context
          unawaited(
            Future.microtask(() {
              if (loadingDialogContext.mounted) {
                Navigator.pop(loadingDialogContext);
              }
            }),
          );
          ErrorSnackbar.show(
            context,
            message: 'Failed to ${_isEditing ? 'update' : 'save'} transaction. Please try again.',
          );
        }
      }
    }
  }
}
