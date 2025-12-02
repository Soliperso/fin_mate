import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/receipt_data.dart';
import '../../data/services/receipt_categorizer_service.dart';
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
  final _notesController = TextEditingController();

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

    // Handle receipt data from ScanReceiptPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteResult();
    });
  }

  Future<void> _handleRouteResult() async {
    // Check if there's a pop result (from ScanReceiptPage)
    final router = GoRouter.of(context);
    if (router.routeInformationProvider.value.uri.toString().contains('scan-receipt')) {
      // Receipt scan was initiated, wait for result
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
        _notesController.text = transaction.notes ?? '';
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
    _notesController.dispose();
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
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Amount Input Card - Prominent
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                    vertical: AppSizes.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                            ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: (_selectedType == 'expense' ? AppColors.error : AppColors.success).withValues(alpha: 0.3),
                              ),
                          prefixText: '\$ ',
                          prefixStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedType == 'expense' ? AppColors.error : AppColors.success,
                              ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Please enter a valid number';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Enter the ${_selectedType == 'expense' ? 'expense' : 'income'} amount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Title Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: TextFormField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: _selectedType == 'expense'
                          ? 'e.g., Grocery shopping, Gas'
                          : 'e.g., Salary, Freelance work',
                      prefixIcon: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Category Selection
              Card(
                child: FutureBuilder(
                  future: ref.watch(categoriesProvider(_selectedType).future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Text('Error loading categories: ${snapshot.error}'),
                      );
                    }

                    final categories = snapshot.data ?? [];
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Text('No categories available'),
                      );
                    }

                    // Set initial category if not set
                    if (_selectedCategory == null && categories.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedCategory = categories.first.name;
                        });
                      });
                    }

                    final selectedCat = categories.firstWhere(
                      (c) => c.name == _selectedCategory,
                      orElse: () => categories.first,
                    );

                    return InkWell(
                      onTap: () => _showCategoryPicker(context, categories),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Icon(
                                _getCategoryIcon(selectedCat.name, selectedCat.icon),
                                color: AppColors.primaryTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Text(
                                    selectedCat.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Date Picker
              Card(
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                _formatDate(_selectedDate),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Notes Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add additional details...',
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        color: AppColors.primaryTeal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Scan Receipt Button (Premium Only)
              Consumer(
                builder: (context, ref, _) {
                  final isPremium = ref.watch(isPremiumProvider);
                  return isPremium.when(
                    data: (premium) => premium
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openScanReceipt,
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: const Text('Scan Receipt'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryTeal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.md,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  );
                },
              ),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedType == 'expense'
                        ? [AppColors.error, AppColors.error.withValues(alpha: 0.8)]
                        : [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedType == 'expense' ? AppColors.error : AppColors.success).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.add,
                    color: Colors.white,
                  ),
                  label: Text(
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
          borderRadius: BorderRadius.circular(AppSizes.xs),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(transactionDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      // Format as "Month Day, Year" (e.g., "November 25, 2025")
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  void _showCategoryPicker(BuildContext context, List<dynamic> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  'Select Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.name == _selectedCategory;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryTeal.withValues(alpha: 0.2)
                              : AppColors.lightGray,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(
                          _getCategoryIcon(category.name, category.icon),
                          color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.primaryTeal,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.name;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openScanReceipt() async {
    try {
      final result = await context.push<ReceiptData>('/transactions/scan-receipt');

      if (result != null) {
        // Auto-fill form with receipt data
        setState(() {
          _titleController.text = result.merchant;
          _amountController.text = result.amount.toStringAsFixed(2);
          _selectedDate = result.date;

          // Auto-categorize based on receipt data
          final suggestedCategory = ReceiptCategorizerService.suggestCategory(
            result.merchant,
            result.items,
          );
          _selectedCategory = suggestedCategory.substring(0, 1).toUpperCase() + suggestedCategory.substring(1);

          // Force expense type for receipts
          _selectedType = 'expense';
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Receipt data extracted successfully!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error scanning receipt', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan receipt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

        final notesText = _notesController.text.trim();
        _logger.d('Creating transaction: type=$type, amount=$amount, account=${accountsList.first.id}');
        _logger.d('Notes field value: "$notesText" (isEmpty: ${notesText.isEmpty})');

        final transaction = TransactionEntity(
          id: '', // Will be generated by database
          userId: currentUserId, // Use actual authenticated user ID
          type: type,
          amount: amount.abs(), // Database expects positive amounts only, type field distinguishes income/expense
          description: _titleController.text.trim(),
          notes: notesText.isEmpty ? null : notesText,
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

  /// Maps category name or emoji icon to Material icon
  IconData _getCategoryIcon(String categoryName, String? emojiIcon) {
    // Map based on category name
    switch (categoryName.toLowerCase()) {
      // Income categories
      case 'salary':
        return Icons.work_outline;
      case 'freelance':
        return Icons.laptop_mac;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'other income':
        return Icons.monetization_on_outlined;

      // Expense categories
      case 'food & dining':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills & utilities':
        return Icons.lightbulb_outline;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'housing':
        return Icons.home;
      case 'personal care':
        return Icons.spa;
      case 'other expense':
        return Icons.payments;

      default:
        return Icons.category;
    }
  }
}
