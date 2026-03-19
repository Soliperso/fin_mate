import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/receipt_data.dart';
import '../../data/services/receipt_categorizer_service.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../debt_payoff/domain/entities/debt_entity.dart';
import '../../../debt_payoff/presentation/providers/debt_providers.dart';
import '../../data/datasources/reminder_remote_datasource.dart';

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
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  AccountEntity? _selectedAccount;

  // Recurring
  bool _isRecurring = false;
  String _recurringInterval = 'monthly';

  // Reminder
  bool _reminderEnabled = false;
  int _reminderDaysBefore = 1;
  final _reminderMessageController = TextEditingController();

  // Attachment
  XFile? _attachmentFile;

  // Debt linking (shown when a debt-payment category is selected)
  DebtEntity? _linkedDebt;
  static const _debtPaymentCategories = {
    'Credit Card Payment',
    'Personal Loan Payment',
    'Student Loan Payment',
    'Auto Loan Payment',
    'Mortgage Payment',
    'Medical Debt Payment',
  };

  @override
  void initState() {
    super.initState();
    if (widget.transactionType != null) {
      _selectedType = widget.transactionType!;
    }
    if (widget.transactionId != null) {
      _loadTransactionData();
    }
  }

  Future<void> _loadTransactionData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final repository = ref.read(transactionRepositoryProvider);
      final allTransactions = await repository.getTransactions();
      final match = allTransactions.where((t) => t.id == widget.transactionId).toList();
      if (match.isEmpty) throw Exception('Transaction not found');
      final transaction = match.first;

      final type = transaction.type == TransactionType.income
          ? 'income'
          : transaction.type == TransactionType.transfer
              ? 'transfer'
              : 'expense';

      final categoryType = transaction.type == TransactionType.income ? 'income' : 'expense';

      final results = await Future.wait([
        ref.read(categoriesProvider(categoryType).future),
        ref.read(accountsProvider.future),
      ]);

      final categories = results[0] as List<dynamic>;
      final accounts = results[1] as List<dynamic>;

      final categoryMatches = categories.where((c) => (c as dynamic).id == transaction.categoryId);
      final category = categoryMatches.isNotEmpty ? categoryMatches.first : null;

      final accountMatches = accounts.where((a) => (a as dynamic).id == transaction.accountId);
      final account = accountMatches.isNotEmpty
          ? accountMatches.first
          : accounts.isNotEmpty
              ? accounts.first
              : null;

      if (mounted) {
        setState(() {
          _titleController.text = transaction.description ?? '';
          _amountController.text = transaction.amount.abs().toStringAsFixed(2);
          _notesController.text = transaction.notes ?? '';
          _selectedType = type;
          _selectedDate = transaction.date;
          if (category != null) _selectedCategory = (category as dynamic).name as String?;
          if (account != null) _selectedAccount = account as AccountEntity;
          _isRecurring = transaction.isRecurring;
          if (transaction.recurringInterval != null) {
            _recurringInterval = transaction.recurringInterval!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.transactionId != null;

  Color get _typeColor =>
      _selectedType == 'expense' ? AppColors.systemRed : AppColors.systemGreen;

  // ── Numpad logic ─────────────────────────────────────────────────────────

  void _numpadInput(String key) {
    setState(() {
      final current = _amountController.text;
      if (key == '⌫') {
        if (current.isNotEmpty) {
          _amountController.text = current.substring(0, current.length - 1);
        }
      } else if (key == '.') {
        if (!current.contains('.')) {
          _amountController.text = current.isEmpty ? '0.' : '$current.';
        }
      } else {
        // Digit
        if (current == '0') {
          _amountController.text = key;
        } else if (current.contains('.')) {
          final parts = current.split('.');
          if (parts[1].length < 2) {
            _amountController.text = '$current$key';
          }
        } else if (current.length < 9) {
          _amountController.text = '$current$key';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.systemGroupedBackgroundDark
          : AppColors.systemGroupedBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.systemGroupedBackgroundDark
            : AppColors.systemGroupedBackground,
        title: Text(_isEditing ? 'Edit Transaction' : 'New Transaction'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Type toggle + Amount + Numpad ──────────────────────────
              _buildAmountSection(isDark),
              const SizedBox(height: AppSizes.xl),

              // ── Details ────────────────────────────────────────────────
              _sectionLabel(context, 'Details'),
              const SizedBox(height: AppSizes.sm),
              _buildDetailsSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // ── Notes ──────────────────────────────────────────────────
              _sectionLabel(context, 'Notes'),
              const SizedBox(height: AppSizes.sm),
              _buildNotesSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // ── Reminder ───────────────────────────────────────────────
              _sectionLabel(context, 'Reminder'),
              const SizedBox(height: AppSizes.sm),
              _buildReminderSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // ── Receipt scan (premium) ──────────────────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final isPremium = ref.watch(isPremiumProvider);
                  return isPremium.when(
                    data: (premium) => premium
                        ? Column(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openScanReceipt,
                                icon: const Icon(CupertinoIcons.camera, size: 18),
                                label: const Text('Scan Receipt'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandTeal,
                                  side: const BorderSide(
                                      color: AppColors.brandTeal),
                                  minimumSize: const Size(double.infinity,
                                      AppSizes.buttonHeightMd),
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  );
                },
              ),

              // ── Save button ────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: Icon(
                  _isEditing ? CupertinoIcons.checkmark : CupertinoIcons.add,
                  size: 18,
                ),
                label: Text(
                  _isEditing
                      ? 'Update Transaction'
                      : (_selectedType == 'expense'
                          ? 'Add Expense'
                          : 'Add Income'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                  minimumSize:
                      const Size(double.infinity, AppSizes.buttonHeightMd),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amount section ────────────────────────────────────────────────────────

  Widget _buildAmountSection(bool isDark) {
    final displayText = _amountController.text;
    final parsedAmount = double.tryParse(displayText);
    final isInvalid = displayText.isNotEmpty &&
        (parsedAmount == null || parsedAmount <= 0);

    return Column(
      children: [
        // Type pill toggle
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.tertiarySystemBackgroundDark
                : AppColors.systemGray5,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _typeTab('expense', 'Expense', isDark),
              _typeTab('income', 'Income', isDark),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Amount display (read-only, updated by numpad)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: displayText.isEmpty
                      ? _typeColor.withValues(alpha: 0.25)
                      : _typeColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Text(
              displayText.isEmpty ? '0.00' : displayText,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: displayText.isEmpty
                    ? _typeColor.withValues(alpha: 0.25)
                    : _typeColor,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
        if (isInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Enter a valid amount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.systemRed,
                  ),
            ),
          ),
        const SizedBox(height: AppSizes.md),

        // Quick amount presets
        _buildQuickAmounts(),
        const SizedBox(height: AppSizes.md),

        // Numpad
        _buildNumpad(isDark),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    const amounts = [10.0, 25.0, 50.0, 100.0, 200.0];
    final current = double.tryParse(_amountController.text);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: amounts.map((amount) {
          final label = '\$${amount.toStringAsFixed(0)}';
          final isSelected = current == amount;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _amountController.text = amount.toStringAsFixed(0)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _typeColor.withValues(alpha: 0.12)
                      : AppColors.systemGray5,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: isSelected
                      ? Border.all(color: _typeColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? _typeColor : AppColors.secondaryLabel,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    final bgColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isBackspace = key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _numpadInput(key),
                      child: SizedBox(
                        height: 56,
                        child: Center(
                          child: isBackspace
                              ? const Icon(
                                  CupertinoIcons.delete_left,
                                  size: 22,
                                  color: AppColors.secondaryLabel,
                                )
                              : Text(
                                  key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeTab(String type, String label, bool isDark) {
    final isSelected = _selectedType == type;
    final selectedColor =
        type == 'expense' ? AppColors.systemRed : AppColors.systemGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = type;
          _selectedCategory = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull - 3),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedColor : AppColors.secondaryLabel,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Details section ───────────────────────────────────────────────────────

  Widget _buildDetailsSection(
      BuildContext context, bool isDark, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title / Description
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 4),
            child: Row(
              children: [
                _rowIcon(CupertinoIcons.pencil, accentColor: _typeColor, isDark: isDark),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    decoration: InputDecoration(
                      hintText: _selectedType == 'expense'
                          ? 'Grocery shopping, Gas…'
                          : 'Salary, Freelance…',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.tertiaryLabel,
                              ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(
                          left: AppSizes.sm, top: 14, bottom: 14),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),

          _divider(isDark),

          // Category — inline scrollable chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Row(
                    children: [
                      _rowIcon(CupertinoIcons.tag, accentColor: _typeColor, isDark: isDark),
                      const SizedBox(width: AppSizes.md),
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != null) ...[
                        Text(
                          _selectedCategory!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryLabel,
                              ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                FutureBuilder(
                  future: ref.watch(categoriesProvider(_selectedType).future),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    if (_selectedCategory == null && categories.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() =>
                              _selectedCategory = categories.first.name);
                        }
                      });
                    }
                    return _buildCategoryChips(categories, isDark);
                  },
                ),
                // Debt picker — only for expense + debt-payment categories
                if (_selectedType == 'expense' &&
                    _debtPaymentCategories.contains(_selectedCategory))
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSizes.sm,
                        left: AppSizes.md,
                        right: AppSizes.md),
                    child: ref.watch(debtsProvider).when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (debts) {
                            if (debts.isEmpty) return const SizedBox.shrink();
                            return DropdownButtonFormField<DebtEntity>(
                              initialValue: _linkedDebt,
                              decoration: InputDecoration(
                                labelText: 'Link to Debt (optional)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.link_rounded),
                                isDense: true,
                                suffixIcon: _linkedDebt != null
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(
                                            () => _linkedDebt = null),
                                      )
                                    : null,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...debts.map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d.name),
                                    )),
                              ],
                              onChanged: (d) =>
                                  setState(() => _linkedDebt = d),
                            );
                          },
                        ),
                  ),
              ],
            ),
          ),

          _divider(isDark),

          // Date — quick shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _rowIcon(CupertinoIcons.calendar, accentColor: _typeColor, isDark: isDark),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      'Date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _dateTrailingSummary(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                _buildDateShortcuts(context, isDark),
              ],
            ),
          ),

          // Account — only when multiple accounts exist
          Consumer(
            builder: (context, ref, _) {
              return ref.watch(accountsProvider).when(
                data: (accounts) {
                  if (accounts.length <= 1) return const SizedBox.shrink();
                  final selectedAccount =
                      _selectedAccount ?? accounts.first;

                  return Column(
                    children: [
                      _divider(isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md, vertical: 4),
                        child: Row(
                          children: [
                            _rowIcon(CupertinoIcons.creditcard, accentColor: _typeColor, isDark: isDark),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AccountEntity>(
                                  value: accounts.contains(selectedAccount)
                                      ? selectedAccount
                                      : accounts.first,
                                  isExpanded: true,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                  icon: const Icon(
                                      CupertinoIcons.chevron_up_chevron_down,
                                      size: 14,
                                      color: AppColors.systemGray3),
                                  items: accounts.map((account) {
                                    return DropdownMenuItem<AccountEntity>(
                                      value: account,
                                      child: Text(account.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedAccount = value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              );
            },
          ),

          _divider(isDark),
          _buildRecurringRow(context, isDark),

          _divider(isDark),
          _buildAttachmentRow(context, isDark),
        ],
      ),
    );
  }


  // ── Recurring row ─────────────────────────────────────────────────────────

  Widget _buildRecurringRow(BuildContext context, bool isDark) {
    const intervals = ['daily', 'weekly', 'monthly', 'yearly'];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rowIcon(CupertinoIcons.repeat, accentColor: _typeColor, isDark: isDark),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  'Repeat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: CupertinoSwitch(
                  value: _isRecurring,
                  activeTrackColor: AppColors.primaryTeal,
                  onChanged: (val) => setState(() => _isRecurring = val),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isRecurring
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm),
              child: Row(
                children: intervals.map((interval) {
                  final isSelected = _recurringInterval == interval;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _recurringInterval = interval),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryTeal.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppColors.tertiarySystemBackgroundDark
                                  : AppColors.systemGray5),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primaryTeal, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          '${interval[0].toUpperCase()}${interval.substring(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryTeal
                                : AppColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment row ────────────────────────────────────────────────────────

  Widget _buildAttachmentRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: Row(
        children: [
          _rowIcon(CupertinoIcons.paperclip, accentColor: _typeColor, isDark: isDark),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: _attachmentFile != null
                ? Wrap(
                    children: [
                      Chip(
                        label: Text(
                          _attachmentFile!.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        deleteIcon:
                            const Icon(CupertinoIcons.xmark, size: 12),
                        onDeleted: () =>
                            setState(() => _attachmentFile = null),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        labelPadding: const EdgeInsets.only(left: 4),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _pickAttachment,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md, horizontal: AppSizes.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color: _typeColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        color: _typeColor.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.paperclip,
                              size: AppSizes.iconMd,
                              color: _typeColor),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Attach Receipt',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _typeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            'Photo or file',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.secondaryLabel),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final result =
          await context.push<ReceiptData>('/transactions/scan-receipt');
      if (result != null && mounted) {
        setState(() {
          _titleController.text = result.merchant;
          _amountController.text = result.amount.toStringAsFixed(2);
          _selectedDate = result.date;
          final suggestedCategory = ReceiptCategorizerService.suggestCategory(
            result.merchant,
            result.items,
          );
          _selectedCategory =
              suggestedCategory.substring(0, 1).toUpperCase() +
                  suggestedCategory.substring(1);
          _selectedType = 'expense';
        });
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, 'Failed to scan receipt: $e');
    }
  }

  Widget _buildCategoryChips(List<dynamic> categories, bool isDark) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        child: Text(
          'Loading…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.tertiaryLabel,
              ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.name == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _typeColor.withValues(alpha: 0.12)
                      : (isDark
                          ? AppColors.tertiarySystemBackgroundDark
                          : AppColors.systemGray5),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: isSelected
                      ? Border.all(color: _typeColor, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category.name, category.icon),
                      size: 14,
                      color:
                          isSelected ? _typeColor : AppColors.secondaryLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? _typeColor
                            : AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateShortcuts(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    final selDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final isToday = selDate == todayDate;
    final isYesterday = selDate == yesterdayDate;
    final isCustom = !isToday && !isYesterday;

    Future<void> openPicker() async {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date != null) setState(() => _selectedDate = date);
    }

    return Row(
      children: [
        _datePill(
          label: 'Today',
          isSelected: isToday,
          isDark: isDark,
          onTap: () => setState(() => _selectedDate = todayDate),
        ),
        const SizedBox(width: AppSizes.sm),
        _datePill(
          label: 'Yesterday',
          isSelected: isYesterday,
          isDark: isDark,
          onTap: () => setState(() => _selectedDate = yesterdayDate),
        ),
        const SizedBox(width: AppSizes.sm),
        _datePill(
          label: _formatDateFull(_selectedDate),
          isSelected: isCustom,
          isDark: isDark,
          icon: CupertinoIcons.calendar,
          onTap: openPicker,
        ),
      ],
    );
  }

  Widget _datePill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? _typeColor.withValues(alpha: 0.12)
              : (isDark
                  ? AppColors.tertiarySystemBackgroundDark
                  : AppColors.systemGray5),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: isSelected ? Border.all(color: _typeColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: isSelected ? _typeColor : AppColors.secondaryLabel),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _typeColor : AppColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes section ─────────────────────────────────────────────────────────

  Widget _buildNotesSection(
      BuildContext context, bool isDark, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _rowIcon(CupertinoIcons.text_alignleft, accentColor: _typeColor, isDark: isDark),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 2,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.tertiaryLabel,
                          ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                      left: AppSizes.sm, top: 14, bottom: 14),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reminder section ──────────────────────────────────────────────────────

  Widget _buildReminderSection(
      BuildContext context, bool isDark, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 0),
            title: const Text('Set Reminder'),
            subtitle: Text(
              'Get notified before this transaction\'s date',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            value: _reminderEnabled,
            activeThumbColor: _typeColor,
            onChanged: (val) => setState(() => _reminderEnabled = val),
          ),
          if (_reminderEnabled) ...[
            Divider(
              height: 0,
              thickness: 0.5,
              color: isDark ? AppColors.separatorDark : AppColors.separator,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, 0),
              child: Row(
                children: [
                  _rowIcon(CupertinoIcons.bell, accentColor: _typeColor, isDark: isDark),
                  const SizedBox(width: AppSizes.md),
                  const Text('Remind me'),
                  const SizedBox(width: AppSizes.sm),
                  SizedBox(
                    width: 56,
                    child: TextFormField(
                      initialValue: _reminderDaysBefore.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed > 0 && parsed <= 30) {
                          setState(() => _reminderDaysBefore = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Text('day(s) before'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _rowIcon(CupertinoIcons.text_bubble,
                        accentColor: _typeColor, isDark: isDark),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: TextFormField(
                      controller: _reminderMessageController,
                      maxLines: 2,
                      minLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Custom reminder message (optional)',
                        hintStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.tertiaryLabel,
                                ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(
                            left: AppSizes.sm, top: 14, bottom: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _rowIcon(IconData icon, {required Color accentColor, bool isDark = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? accentColor.withValues(alpha: 0.75) : accentColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      color: isDark ? AppColors.separatorDark : AppColors.separator,
    );
  }

  String _dateTrailingSummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (sel == today) return 'Today';
    if (sel == yesterday) return 'Yesterday';
    return _formatDateFull(_selectedDate);
  }

  String _formatDateFull(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Future<void> _openScanReceipt() async {
    try {
      final result =
          await context.push<ReceiptData>('/transactions/scan-receipt');

      if (result != null) {
        setState(() {
          _titleController.text = result.merchant;
          _amountController.text = result.amount.toStringAsFixed(2);
          _selectedDate = result.date;

          final suggestedCategory = ReceiptCategorizerService.suggestCategory(
            result.merchant,
            result.items,
          );
          _selectedCategory = suggestedCategory.substring(0, 1).toUpperCase() +
              suggestedCategory.substring(1);
          _selectedType = 'expense';
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to scan receipt: $e');
      }
    }
  }

  Future<void> _handleSubmit() async {
    // Validate amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {}); // shows inline error
      await showErrorDialog(context, 'Please enter a valid amount greater than 0.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingDialogContext = dialogContext;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final repository = ref.read(transactionRepositoryProvider);
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) throw Exception('User not authenticated');

      var accountsList = await ref.read(accountsProvider.future);

      if (accountsList.isEmpty) {
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
        accountsList = [defaultAccount];
        ref.invalidate(accountsProvider);
      }

      final categoriesAsync = await ref.read(
          categoriesProvider(
                  _selectedType == 'expense' ? 'expense' : 'income')
              .future);

      final category = categoriesAsync.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => categoriesAsync.first,
      );

      final type = _selectedType == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      final notesText = _notesController.text.trim();

      final transaction = TransactionEntity(
        id: '',
        userId: currentUserId,
        type: type,
        amount: amount.abs(),
        description: _titleController.text.trim(),
        notes: notesText.isEmpty ? null : notesText,
        date: _selectedDate,
        accountId: _selectedAccount?.id ?? accountsList.first.id,
        categoryId: category.id,
        isRecurring: _isRecurring,
        recurringInterval: _isRecurring ? _recurringInterval : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final analytics = ref.read(analyticsServiceProvider);
      String savedTransactionId;
      if (_isEditing) {
        await repository.updateTransaction(widget.transactionId!, transaction);
        savedTransactionId = widget.transactionId!;
        unawaited(analytics.trackTransactionUpdated(
            transactionId: widget.transactionId!));
      } else {
        final created = await repository.createTransaction(transaction);
        savedTransactionId = created.id;
        unawaited(analytics.trackTransactionCreated(
          transactionId: created.id,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory,
        ));
        // If a debt was linked, update its balance
        if (_linkedDebt != null) {
          await ref
              .read(debtNotifierProvider.notifier)
              .recordPaymentFromTransaction(
                debtId: _linkedDebt!.id,
                amount: amount.abs(),
                paymentDate: _selectedDate,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              );
          ref.invalidate(debtsProvider);
          ref.invalidate(debtSummaryProvider);
        }
      }

      // Upload attachment if one was picked
      if (_attachmentFile != null) {
        try {
          final file = File(_attachmentFile!.path);
          final bytes = await file.readAsBytes();
          final fileName = _attachmentFile!.name;
          final mimeType = _attachmentFile!.mimeType ?? 'image/jpeg';
          final storagePath =
              'receipts/$currentUserId/$savedTransactionId/$fileName';

          await supabase.storage.from('receipts').uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(contentType: mimeType),
              );

          await supabase.from('documents').insert({
            'user_id': currentUserId,
            'transaction_id': savedTransactionId,
            'file_name': fileName,
            'file_type': 'receipt',
            'file_size': bytes.length,
            'mime_type': mimeType,
            'storage_path': storagePath,
          });
        } catch (_) {
          // Attachment upload failure is non-fatal — transaction was saved
        }
      }

      // Save reminder if enabled (non-fatal if it fails)
      if (_reminderEnabled) {
        try {
          await ReminderRemoteDatasource().createReminder(
            transactionId: savedTransactionId,
            transactionDate: _selectedDate,
            daysBefore: _reminderDaysBefore,
            message: _reminderMessageController.text.trim().isEmpty
                ? null
                : _reminderMessageController.text.trim(),
          );
        } catch (_) {
          // Reminder creation is non-fatal
        }
      }

      ref.invalidate(dashboardNotifierProvider);
      ref.invalidate(transactionListProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(monthlyFlowDataProvider);
      ref.invalidate(netWorthSnapshotsProvider);
      ref.invalidate(budgetNotifierProvider);

      if (mounted) {
        final ctx = loadingDialogContext;
        if (ctx != null && ctx.mounted) Navigator.pop(ctx);
        if (mounted) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        final ctx = loadingDialogContext;
        if (ctx != null && ctx.mounted) Navigator.pop(ctx);
        await showErrorDialog(
          context,
          'Failed to ${_isEditing ? 'update' : 'save'} transaction. Please try again.',
        );
      }
    }
  }

  IconData _getCategoryIcon(String categoryName, String? emojiIcon) {
    switch (categoryName.toLowerCase()) {
      // Income
      case 'salary':
        return CupertinoIcons.briefcase;
      case 'freelance':
        return CupertinoIcons.desktopcomputer;
      case 'investment':
        return CupertinoIcons.chart_bar_alt_fill;
      case 'gift':
        return CupertinoIcons.gift;
      case 'other income':
        return CupertinoIcons.money_dollar_circle;

      // Expense
      case 'food & dining':
        return CupertinoIcons.cart;
      case 'transportation':
        return CupertinoIcons.car_detailed;
      case 'shopping':
        return CupertinoIcons.bag;
      case 'entertainment':
        return CupertinoIcons.film;
      case 'bills & utilities':
        return CupertinoIcons.bolt;
      case 'healthcare':
        return CupertinoIcons.heart;
      case 'education':
        return CupertinoIcons.book;
      case 'housing':
        return CupertinoIcons.house;
      case 'personal care':
        return CupertinoIcons.person_crop_circle;
      case 'other expense':
        return CupertinoIcons.creditcard;

      default:
        return CupertinoIcons.tag;
    }
  }
}
