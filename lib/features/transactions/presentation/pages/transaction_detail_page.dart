import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/utils/category_icon_utils.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_providers.dart';

final _transactionDetailProvider =
    FutureProvider.family<TransactionEntity?, String>((ref, id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionById(id);
});

class TransactionDetailPage extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_transactionDetailProvider(transactionId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.exclamationmark_circle,
                    size: 48, color: AppColors.error.withValues(alpha: 0.5)),
                const SizedBox(height: AppSizes.md),
                Text('transactionDetail.failedToLoad'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.error)),
                const SizedBox(height: AppSizes.sm),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(_transactionDetailProvider(transactionId)),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
        data: (transaction) {
          if (transaction == null) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_text,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSizes.md),
                    Text('transactionDetail.notFound'.tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('transactionDetail.goBack'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildDetail(context, ref, transaction);
        },
      ),
    );
  }

  Widget _buildDetail(
      BuildContext context, WidgetRef ref, TransactionEntity transaction) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final cardColor = Theme.of(context).cardTheme.color;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? AppColors.success
        : isTransfer
            ? AppColors.slateBlue
            : AppColors.error;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero ──────────────────────────────────────────────────────────────
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight * 0.44),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  amountColor.withValues(alpha: 0.22),
                  amountColor.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 64,
                    left: AppSizes.lg,
                    right: AppSizes.lg,
                    bottom: AppSizes.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: amountColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          transaction.categoryName != null
                              ? getCategoryIcon(transaction.categoryName,
                                  type: transaction.type.name)
                              : _typeIcon(transaction.type),
                          size: 32,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      // Amount
                      Text(
                        currencyFormat
                            .format(transaction.amount.abs() * convFactor),
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2.5,
                              height: 1.0,
                              fontSize: 54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (ref.watch(usdEquivalentProvider(
                              transaction.amount.abs())) !=
                          null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ref.watch(usdEquivalentProvider(
                              transaction.amount.abs()))!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (transaction.description != null &&
                          transaction.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          transaction.description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                                letterSpacing: -0.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        dateFormat.format(transaction.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  ),
                ),
                // Back button
                Positioned(
                  top: topPadding + 12,
                  left: 16,
                  child: CircularIconButton(
                    icon: CupertinoIcons.chevron_left,
                    onTap: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Details + spacer (fills remaining screen above buttons) ───────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.md),
                _sectionLabel(context, 'DETAILS'),
                const SizedBox(height: AppSizes.xs),
                _panel(
                  cardColor: cardColor,
                  children: [
                    if (transaction.accountName != null)
                      _panelRow(
                        context,
                        leading: _rowIcon(
                            CupertinoIcons.creditcard_fill,
                            AppColors.brandTeal),
                        label: isTransfer
                            ? 'transactionDetail.from'.tr()
                            : 'transactionDetail.account'.tr(),
                        value: transaction.accountName!,
                      ),
                    if (isTransfer && transaction.toAccountName != null)
                      _panelRow(
                        context,
                        leading: _rowIcon(
                            CupertinoIcons.creditcard_fill,
                            AppColors.brandTeal),
                        label: 'transactionDetail.to'.tr(),
                        value: transaction.toAccountName!,
                      ),
                    _panelRow(
                      context,
                      leading: _rowIcon(CupertinoIcons.tag_fill, amountColor),
                      label: 'transactionDetail.type'.tr(),
                      trailing:
                          _typeBadge(context, transaction.type, amountColor),
                      isLast: transaction.categoryName == null &&
                          !transaction.isRecurring,
                    ),
                    if (transaction.categoryName != null)
                      _panelRow(
                        context,
                        leading: _rowIcon(
                          getCategoryIcon(transaction.categoryName,
                              type: transaction.type.name),
                          amountColor,
                        ),
                        label: 'transactionDetail.category'.tr(),
                        trailing:
                            _categoryChip(context, transaction, amountColor),
                        isLast: !transaction.isRecurring,
                      ),
                    if (transaction.isRecurring)
                      _panelRow(
                        context,
                        leading: _rowIcon(
                            CupertinoIcons.arrow_2_circlepath,
                            AppColors.brandTeal),
                        label: 'transactionDetail.recurring'.tr(),
                        value: transaction.recurringInterval ?? 'Yes',
                        isLast: true,
                      ),
                  ],
                ),
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _sectionLabel(context, 'NOTES'),
                  const SizedBox(height: AppSizes.xs),
                  _panel(
                    cardColor: cardColor,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Text(
                          transaction.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),

        // ── Actions (always pinned to bottom) ─────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.xs, AppSizes.lg, AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context
                          .push('/transactions/add?id=${transaction.id}');
                      if (context.mounted) {
                        ref.invalidate(
                            _transactionDetailProvider(transactionId));
                      }
                    },
                    icon: const Icon(CupertinoIcons.pencil, size: 18),
                    label: Text('common.edit'.tr()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size.fromHeight(AppSizes.buttonHeightMd),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, ref, transaction),
                    icon: const Icon(CupertinoIcons.trash, size: 18),
                    label: Text('common.delete'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize:
                          const Size.fromHeight(AppSizes.buttonHeightMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  IconData _typeIcon(TransactionType type) => switch (type) {
        TransactionType.income => CupertinoIcons.arrow_down_circle_fill,
        TransactionType.expense => CupertinoIcons.arrow_up_circle_fill,
        TransactionType.transfer =>
          CupertinoIcons.arrow_right_arrow_left_circle_fill,
      };

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _rowIcon(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }

  Widget _panel({required Color? cardColor, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _panelRow(
    BuildContext context, {
    Widget? leading,
    required String label,
    String? value,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              if (trailing != null)
                trailing
              else if (value != null)
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 58,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }

  Widget _typeBadge(BuildContext context, TransactionType type, Color color) {
    final label = switch (type) {
      TransactionType.income => 'transactionDetail.income'.tr(),
      TransactionType.expense => 'transactionDetail.expense'.tr(),
      TransactionType.transfer => 'transactionDetail.transfer'.tr(),
    };
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _categoryChip(
      BuildContext context, TransactionEntity transaction, Color amountColor) {
    return Text(
      transaction.categoryName!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      TransactionEntity transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('transactionDetail.deleteTitle'.tr()),
        content: Text('transactionDetail.deleteMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(transactionListProvider.notifier)
          .deleteTransaction(transaction.id);
      if (context.mounted) context.pop();
    }
  }
}
