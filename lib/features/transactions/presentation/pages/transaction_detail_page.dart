import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
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
    final dateFormat = DateFormat('M/d/yy, h:mm a');
    final cardColor = Theme.of(context).cardTheme.color;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? AppColors.success
        : isTransfer
            ? AppColors.slateBlue
            : AppColors.error;
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero section ────────────────────────────────────────────────────
          Stack(
            children: [
              // Amount + title + date (centered)
              Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 72,
                  left: AppSizes.lg,
                  right: AppSizes.lg,
                  bottom: AppSizes.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      currencyFormat.format(transaction.amount.abs()),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Text(
                        transaction.description!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
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

              // Floating back button (top-left)
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

          // ── Details panel ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: _panel(
              cardColor: cardColor,
              children: [
                if (transaction.accountName != null)
                  _panelRow(
                    context,
                    label: transaction.type == TransactionType.transfer
                        ? 'transactionDetail.from'.tr()
                        : 'transactionDetail.account'.tr(),
                    value: transaction.accountName!,
                  ),
                if (transaction.type == TransactionType.transfer &&
                    transaction.toAccountName != null)
                  _panelRow(
                    context,
                    label: 'transactionDetail.to'.tr(),
                    value: transaction.toAccountName!,
                  ),
                _panelRow(
                  context,
                  label: 'transactionDetail.type'.tr(),
                  trailing: _typeBadge(context, transaction.type, amountColor),
                ),
                if (transaction.isRecurring)
                  _panelRow(
                    context,
                    label: 'transactionDetail.recurring'.tr(),
                    value: transaction.recurringInterval ?? 'Yes',
                    isLast: true,
                  ),
              ],
            ),
          ),

          // ── Notes panel ──────────────────────────────────────────────────────
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'transactionDetail.notes'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
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
              ),
            ),
          ],

          // ── Category row ─────────────────────────────────────────────────────
          if (transaction.categoryName != null) ...[
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: _panel(
                cardColor: cardColor,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          'transactionDetail.category'.tr(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(transaction),
                                size: 14,
                                color: amountColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                transaction.categoryName!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: amountColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.xl),

          // ── Actions ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context
                          .push('/transactions/add?id=${transaction.id}');
                      if (context.mounted) {
                        ref.invalidate(
                            _transactionDetailProvider(transactionId));
                      }
                    },
                    icon: const Icon(CupertinoIcons.pencil),
                    label: Text('common.edit'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref, transaction),
                    icon: const Icon(CupertinoIcons.trash),
                    label: Text('common.delete'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.xl),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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
    required String label,
    String? value,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
            indent: 16,
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
            color: color,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  IconData _getCategoryIcon(TransactionEntity transaction) {
    final cat = transaction.categoryName?.toLowerCase() ?? '';
    if (transaction.type == TransactionType.income) {
      if (cat.contains('salary')) return CupertinoIcons.briefcase;
      if (cat.contains('freelance')) return CupertinoIcons.desktopcomputer;
      if (cat.contains('investment')) return CupertinoIcons.graph_circle;
      if (cat.contains('gift')) return CupertinoIcons.gift;
      return CupertinoIcons.money_dollar_circle;
    }
    if (transaction.type == TransactionType.transfer) {
      return CupertinoIcons.arrow_right_arrow_left;
    }
    if (cat.contains('food') || cat.contains('dining')) {
      return CupertinoIcons.cart;
    }
    if (cat.contains('transport') || cat.contains('gas')) {
      return CupertinoIcons.car;
    }
    if (cat.contains('shopping')) return CupertinoIcons.bag;
    if (cat.contains('entertainment')) return CupertinoIcons.film;
    if (cat.contains('utilities') || cat.contains('bill')) {
      return CupertinoIcons.doc_text;
    }
    if (cat.contains('health')) return CupertinoIcons.heart;
    if (cat.contains('education')) return CupertinoIcons.book;
    if (cat.contains('housing')) return CupertinoIcons.house;
    return CupertinoIcons.creditcard;
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
