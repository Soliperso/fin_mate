import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoIcons,
        CupertinoSwitch,
        CupertinoPicker,
        CupertinoPickerDefaultSelectionOverlay,
        CupertinoButton;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
// import '../../domain/entities/receipt_data.dart'; // [V1.1: Attachment]
// import '../../data/services/receipt_categorizer_service.dart'; // [V1.1: Attachment]
import '../../../../core/services/review_service.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../debt_payoff/domain/entities/debt_entity.dart';
import '../../../debt_payoff/presentation/providers/debt_providers.dart';
import '../../../savings_goals/domain/entities/savings_goal_entity.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';
import '../../data/datasources/reminder_remote_datasource.dart';
// import '../../../../core/providers/subscription_provider.dart'; // [V1.1: Attachment]
// import '../../../../shared/widgets/premium_feature_dialog.dart'; // [V1.1: Attachment]

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

  // Category wheel
  late FixedExtentScrollController _categoryScrollController;
  List<dynamic> _loadedCategories = [];

  // Date strip
  late ScrollController _dateStripController;

  // Recurring
  bool _isRecurring = false;
  String _recurringInterval = 'monthly';

  // Reminder
  bool _reminderEnabled = false;
  int _reminderDaysBefore = 1;
  final _reminderMessageController = TextEditingController();

  // Attachment
  XFile? _attachmentFile;

  // Debt linking (shown for any expense — optionally reduces a tracked debt balance)
  DebtEntity? _linkedDebt;

  // Goal linking (optional — auto-creates a contribution for the saved amount)
  SavingsGoal? _linkedGoal;

  // Maps debt-payment category names → debt type strings in the debts table
  static const _categoryDebtTypeMap = {
    'Auto Loan Payment': 'auto_loan',
    'Credit Card Payment': 'credit_card',
    'Personal Loan Payment': 'personal_loan',
    'Student Loan Payment': 'student_loan',
    'Mortgage Payment': 'mortgage',
    'Medical Debt Payment': 'medical',
  };

  /// Auto-selects the matching debt when a debt-payment category is tapped.
  /// Only pre-fills when exactly one debt of that type exists; otherwise the
  /// user picks manually from the dropdown.
  void _autoLinkDebt(String categoryName) {
    final debtType = _categoryDebtTypeMap[categoryName];
    if (debtType == null) return;
    final debts = ref.read(debtsProvider).valueOrNull ?? [];
    final matching = debts.where((d) => d.debtType == debtType).toList();
    if (matching.length == 1) {
      _linkedDebt = matching.first;
    }
  }

  void _syncCategoryWheel(List<dynamic> categories) {
    final idx = categories.indexWhere((c) => c.name == _selectedCategory);
    if (idx != -1 && _categoryScrollController.hasClients) {
      _categoryScrollController.jumpToItem(idx);
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryScrollController = FixedExtentScrollController(initialItem: 0);
    _dateStripController = ScrollController();
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
      final match =
          allTransactions.where((t) => t.id == widget.transactionId).toList();
      if (match.isEmpty) throw Exception('Transaction not found');
      final transaction = match.first;

      final type = transaction.type == TransactionType.income
          ? 'income'
          : transaction.type == TransactionType.transfer
              ? 'transfer'
              : 'expense';

      final categoryType =
          transaction.type == TransactionType.income ? 'income' : 'expense';

      final results = await Future.wait([
        ref.read(categoriesProvider(categoryType).future),
        ref.read(accountsProvider.future),
      ]);

      final categories = results[0] as List<dynamic>;
      final accounts = results[1] as List<dynamic>;

      final categoryMatches =
          categories.where((c) => (c as dynamic).id == transaction.categoryId);
      final category =
          categoryMatches.isNotEmpty ? categoryMatches.first : null;

      final accountMatches =
          accounts.where((a) => (a as dynamic).id == transaction.accountId);
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
          if (category != null)
            _selectedCategory = (category as dynamic).name as String?;
          if (account != null) _selectedAccount = account as AccountEntity;
          _isRecurring = transaction.isRecurring;
          if (transaction.recurringInterval != null) {
            _recurringInterval = transaction.recurringInterval!;
          }
          _loadedCategories = categories;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncCategoryWheel(categories);
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
    _categoryScrollController.dispose();
    _dateStripController.dispose();
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
        title: Text(_isEditing
            ? 'addTransaction.editTitle'.tr()
            : 'addTransaction.newTitle'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.xmark,
            onTap: () => context.pop(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding, AppSizes.sm,
              AppSizes.pagePadding, AppSizes.md),
          child: ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: Icon(
              _isEditing ? CupertinoIcons.checkmark : CupertinoIcons.add,
              size: 18,
            ),
            label: Text(
              _isEditing
                  ? 'addTransaction.updateButton'.tr()
                  : (_selectedType == 'expense'
                      ? 'addTransaction.addExpense'.tr()
                      : 'addTransaction.addIncome'.tr()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, AppSizes.buttonHeightMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
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
              _sectionLabel(context, 'addTransaction.details'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildDetailsSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // ── Notes ──────────────────────────────────────────────────
              _sectionLabel(context, 'addTransaction.notes'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildNotesSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // ── Reminder ───────────────────────────────────────────────
              _sectionLabel(context, 'addTransaction.reminder'.tr()),
              const SizedBox(height: AppSizes.sm),
              _buildReminderSection(context, isDark, cardColor),
              const SizedBox(height: AppSizes.lg),

              // [V1.1: Receipt Scan - AI feature, hidden until next release]
              // Column(
              //   children: [
              //     GestureDetector(
              //       onTap: _openScanReceipt,
              //       ...
              //     ),
              //     const SizedBox(height: AppSizes.md),
              //   ],
              // ),

              const SizedBox(height: AppSizes.lg),
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
    final isInvalid =
        displayText.isNotEmpty && (parsedAmount == null || parsedAmount <= 0);

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
              _typeTab('expense', 'addTransaction.expenseType'.tr(), isDark),
              _typeTab('income', 'addTransaction.incomeType'.tr(), isDark),
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
              'addTransaction.amountInvalid'.tr(),
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
              onTap: () => setState(
                  () => _amountController.text = amount.toStringAsFixed(0)),
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
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          if (_categoryScrollController.hasClients) {
            _categoryScrollController.jumpToItem(0);
          }
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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? selectedColor : AppColors.secondaryLabel,
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
                _rowIcon(CupertinoIcons.pencil,
                    accentColor: _typeColor, isDark: isDark),
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
                          ? 'addTransaction.titleHintExpense'.tr()
                          : 'addTransaction.titleHintIncome'.tr(),
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
                        return 'addTransaction.titleRequired'.tr();
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showCategoryPicker(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: Row(
                      children: [
                        _rowIcon(CupertinoIcons.tag,
                            accentColor: _typeColor, isDark: isDark),
                        const SizedBox(width: AppSizes.md),
                        Text(
                          'addTransaction.categoryLabel'.tr(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const Spacer(),
                        if (_selectedCategory != null)
                          Text(
                            _selectedCategory!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryLabel,
                                    ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 14, color: AppColors.systemGray3),
                      ],
                    ),
                  ),
                ),
                FutureBuilder(
                  future: ref.watch(categoriesProvider(_selectedType).future),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    if (categories.isNotEmpty) {
                      if (_selectedCategory == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() =>
                                _selectedCategory = categories.first.name);
                          }
                        });
                      }
                      if (_loadedCategories != categories) {
                        _loadedCategories = categories;
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Debt picker — inline row, visible for any expense
                if (_selectedType == 'expense')
                  ref.watch(debtsProvider).when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (debts) {
                          if (debts.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: [
                              _divider(isDark),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md, vertical: 4),
                                child: Row(
                                  children: [
                                    _rowIcon(CupertinoIcons.link,
                                        accentColor: _typeColor,
                                        isDark: isDark),
                                    const SizedBox(width: AppSizes.md),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<DebtEntity>(
                                          value: _linkedDebt,
                                          hint: Text(
                                            'addTransaction.linkDebt'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: AppColors
                                                        .tertiaryLabel),
                                          ),
                                          isExpanded: true,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500),
                                          icon: const Icon(
                                              CupertinoIcons
                                                  .chevron_up_chevron_down,
                                              size: 14,
                                              color: AppColors.systemGray3),
                                          items: [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text('common.none'.tr(),
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .tertiaryLabel)),
                                            ),
                                            ...debts.map((d) =>
                                                DropdownMenuItem(
                                                    value: d,
                                                    child: Text(d.name))),
                                          ],
                                          onChanged: (d) =>
                                              setState(() => _linkedDebt = d),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ],
            ),
          ),

          _divider(isDark),

          // Save toward goal — only for new transactions with active goals
          if (!_isEditing)
            Consumer(
              builder: (context, ref, _) {
                return ref.watch(savingsGoalsProvider).when(
                      data: (goals) {
                        final active =
                            goals.where((g) => !g.isCompleted).toList();
                        if (active.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md, vertical: 4),
                              child: Row(
                                children: [
                                  _rowIcon(CupertinoIcons.flag,
                                      accentColor: _typeColor, isDark: isDark),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<SavingsGoal?>(
                                        value: _linkedGoal,
                                        hint: Text(
                                          'Save toward goal (Optional)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color:
                                                      AppColors.tertiaryLabel),
                                        ),
                                        isExpanded: true,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500),
                                        icon: const Icon(
                                            CupertinoIcons
                                                .chevron_up_chevron_down,
                                            size: 14,
                                            color: AppColors.systemGray3),
                                        items: [
                                          DropdownMenuItem(
                                            value: null,
                                            child: Text('common.none'.tr(),
                                                style: TextStyle(
                                                    color: AppColors
                                                        .tertiaryLabel)),
                                          ),
                                          ...active.map((g) => DropdownMenuItem(
                                              value: g, child: Text(g.name))),
                                        ],
                                        onChanged: (g) {
                                          setState(() {
                                            _linkedGoal = g;
                                            if (g != null) {
                                              _selectedType = 'expense';
                                              _selectedCategory = 'Savings';
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (mounted) {
                                                  _syncCategoryWheel(
                                                      _loadedCategories);
                                                }
                                              });
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _divider(isDark),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
              },
            ),

          // Date — quick shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _rowIcon(CupertinoIcons.calendar,
                        accentColor: _typeColor, isDark: isDark),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      'addTransaction.dateLabel'.tr(),
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
                _buildDateStrip(isDark),
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
                                _rowIcon(CupertinoIcons.creditcard,
                                    accentColor: _typeColor, isDark: isDark),
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
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500),
                                      icon: const Icon(
                                          CupertinoIcons
                                              .chevron_up_chevron_down,
                                          size: 14,
                                          color: AppColors.systemGray3),
                                      items: accounts.map((account) {
                                        return DropdownMenuItem<AccountEntity>(
                                          value: account,
                                          child: Text(account.name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(
                                            () => _selectedAccount = value);
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
                    error: (e, _) => ErrorRetryWidget(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(accountsProvider),
                    ),
                  );
            },
          ),

          _divider(isDark),
          _buildRecurringRow(context, isDark),

          // [V1.1: Attachment — hidden until file upload is stable]
          // _divider(isDark),
          // _buildAttachmentRow(context, isDark),
        ],
      ),
    );
  }

  // ── Recurring row ─────────────────────────────────────────────────────────

  Widget _buildRecurringRow(BuildContext context, bool isDark) {
    const intervals = ['daily', 'weekly', 'biweekly', 'monthly', 'yearly'];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rowIcon(CupertinoIcons.repeat,
                  accentColor: _typeColor, isDark: isDark),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  'addTransaction.repeatLabel'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Transform.scale(
                scale: 0.65,
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
                children: intervals.asMap().entries.map((e) {
                  final i = e.key;
                  final interval = e.value;
                  final isSelected = _recurringInterval == interval;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i < intervals.length - 1 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _recurringInterval = interval),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
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
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
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
  // [V1.1: Attachment — hidden until file upload is stable]
  //
  // Widget _buildAttachmentRow(BuildContext context, bool isDark) { ... }
  // Future<void> _pickAttachment() async { ... }

  void _showCategoryPicker() {
    final categories = _loadedCategories;
    if (categories.isEmpty) return;

    final initialIndex =
        categories.indexWhere((c) => c.name == _selectedCategory);
    final controller = FixedExtentScrollController(
      initialItem: initialIndex.clamp(0, categories.length - 1),
    );
    String tempCategory =
        _selectedCategory ?? (categories.first.name as String);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground;
        final toolbarColor = isDark
            ? AppColors.tertiarySystemBackgroundDark
            : AppColors.secondarySystemBackground;
        final dividerColor = Theme.of(context).dividerColor;
        final labelColor = isDark ? AppColors.labelDark : AppColors.label;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
          child: Container(
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.systemGray4,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                // Toolbar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: toolbarColor,
                    border: Border(
                      bottom: BorderSide(color: dividerColor, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'common.cancel'.tr(),
                          style: Theme.of(ctx).textTheme.titleMedium!.copyWith(
                                color: AppColors.systemGray,
                              ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'addTransaction.categoryLabel'.tr(),
                            style:
                                Theme.of(ctx).textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: labelColor,
                                      letterSpacing: -0.3,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedType[0].toUpperCase()}${_selectedType.substring(1)}',
                            style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                                  color: _typeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _autoLinkDebt(tempCategory);
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'common.done'.tr(),
                          style: Theme.of(ctx).textTheme.titleMedium!.copyWith(
                                color: _typeColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Picker
                SizedBox(
                  height: 216,
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 48,
                    backgroundColor: bgColor,
                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                      background: _typeColor.withValues(alpha: 0.15),
                      capStartEdge: false,
                      capEndEdge: false,
                    ),
                    onSelectedItemChanged: (index) {
                      tempCategory = categories[index].name as String;
                    },
                    children: categories.map((cat) {
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(cat.name, cat.icon),
                              size: 18,
                              color: AppColors.secondaryLabel,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat.name,
                              style:
                                  Theme.of(ctx).textTheme.titleMedium!.copyWith(
                                        color: labelColor,
                                        letterSpacing: -0.2,
                                      ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateStrip(bool isDark) {
    final today = DateTime.now();
    const pastDays = 13;
    final days = List.generate(pastDays + 1, (i) {
      return DateTime(today.year, today.month, today.day - (pastDays - i));
    });

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dateStripController.hasClients) return;
      final selNorm =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final idx = days.indexWhere((d) => d == selNorm);
      if (idx != -1) {
        const itemWidth = 52.0;
        final offset = (idx * itemWidth) -
            (MediaQuery.of(context).size.width / 2) +
            (itemWidth / 2);
        _dateStripController.jumpTo(offset.clamp(
          _dateStripController.position.minScrollExtent,
          _dateStripController.position.maxScrollExtent,
        ));
      }
    });

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _dateStripController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: Row(
              children: days.map((day) {
                final selNorm = DateTime(
                    _selectedDate.year, _selectedDate.month, _selectedDate.day);
                final isSelected = day == selNorm;
                final isToday =
                    day == DateTime(today.year, today.month, today.day);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _typeColor
                          : (isDark
                              ? AppColors.tertiarySystemBackgroundDark
                              : AppColors.systemGray5),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayNames[day.weekday - 1],
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : AppColors.tertiaryLabel,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : (isToday ? _typeColor : null),
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.calendar,
              size: 20, color: AppColors.secondaryLabel),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
      ],
    );
  }

  // ── Notes section ─────────────────────────────────────────────────────────

  Widget _buildNotesSection(
      BuildContext context, bool isDark, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _rowIcon(CupertinoIcons.text_alignleft,
                  accentColor: _typeColor, isDark: isDark),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 2,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'addTransaction.noteHint'.tr(),
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('addTransaction.reminder'.tr()),
                      const SizedBox(height: 4),
                      Text(
                        'Get notified before this transaction\'s date',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall!
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: CupertinoSwitch(
                    value: _reminderEnabled,
                    activeTrackColor: _typeColor,
                    onChanged: (val) => setState(() => _reminderEnabled = val),
                  ),
                ),
              ],
            ),
          ),
          if (_reminderEnabled) ...[
            Divider(
              height: 0,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, 0),
              child: Row(
                children: [
                  _rowIcon(CupertinoIcons.bell,
                      accentColor: _typeColor, isDark: isDark),
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
                        hintText: 'addTransaction.reminderHint'.tr(),
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

  Widget _rowIcon(IconData icon,
      {required Color accentColor, bool isDark = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Icon(icon, size: 16, color: accentColor),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  String _dateTrailingSummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sel =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (sel == today) return 'Today';
    if (sel == yesterday) return 'Yesterday';
    return _formatDateFull(_selectedDate);
  }

  String _formatDateFull(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  // [V1.1: Receipt Scan - removed from UI until AI features are released]
  // Future<void> _openScanReceipt() async { ... }

  Future<void> _handleSubmit() async {
    // Validate amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {}); // shows inline error
      await showErrorDialog(
          context, 'Please enter a valid amount greater than 0.');
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
          categoriesProvider(_selectedType == 'expense' ? 'expense' : 'income')
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
        // If a savings goal was linked, auto-create a contribution
        if (_linkedGoal != null) {
          await ref.read(goalOperationsProvider.notifier).addContribution(
                goalId: _linkedGoal!.id,
                amount: amount.abs(),
                notes: notesText.isEmpty ? null : notesText,
                transactionId: savedTransactionId,
              );
          ref.invalidate(savingsGoalsProvider);
          ref.invalidate(goalsSummaryProvider);
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
      ref.invalidate(categoryBreakdownProvider);

      if (mounted) {
        final ctx = loadingDialogContext;
        if (ctx != null && ctx.mounted) Navigator.pop(ctx);
        if (!_isEditing) {
          await ReviewService.instance.maybePromptAfterTransaction();
        }
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
      case 'savings':
        return CupertinoIcons.arrow_up_circle_fill;
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
