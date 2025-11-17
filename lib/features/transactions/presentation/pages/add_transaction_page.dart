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
import '../../../budgets/presentation/providers/budget_providers.dart';

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
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

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

  // Categories are now loaded from database in the build method via Consumer widget

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
              FutureBuilder(
                future: ref.watch(categoriesProvider(_selectedType).future),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading categories: ${snapshot.error}');
                  }

                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return const Text('No categories available');
                  }

                  // Set initial category if not set
                  if (_selectedCategory == null && categories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedCategory = categories.first.name;
                      });
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory ?? categories.first.name,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.name,
                        child: Text('${category.icon} ${category.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  );
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
          _selectedCategory = null; // Reset category when type changes, will be set by FutureBuilder
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

        // Find category ID by name - should always find a match since categories are loaded from DB
        final category = categoriesAsync.firstWhere(
          (c) => c.name == _selectedCategory,
          orElse: () {
            _logger.w('Category "$_selectedCategory" not found in database! Using first available category.');
            return categoriesAsync.first;
          },
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
        ref.invalidate(budgetNotifierProvider); // Refresh budget spending calculations

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

          _logger.d('Showing success snackbar...');
          // Show success snackbar
          SuccessSnackbar.show(
            context,
            message: _isEditing
                ? 'Transaction updated successfully'
                : '${_selectedType == 'expense' ? 'Expense' : 'Income'} added successfully',
          );

          _logger.d('Popping page...');
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
