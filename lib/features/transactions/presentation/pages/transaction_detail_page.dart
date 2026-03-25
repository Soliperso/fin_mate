import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Transaction Details'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.error.withValues(alpha: 0.5)),
              const SizedBox(height: AppSizes.md),
              Text('Failed to load transaction',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.error)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(_transactionDetailProvider(transactionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (transaction) {
          if (transaction == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_text,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSizes.md),
                  Text('Transaction not found',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
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
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? AppColors.success
        : isTransfer
            ? AppColors.slateBlue
            : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount
          Text(
            currencyFormat.format(transaction.amount.abs()),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            transaction.type.toString().split('.').last.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),

          // Details card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                _detailRow(context, 'Title',
                    transaction.description ?? 'N/A'),
                if (transaction.categoryName != null)
                  _detailRow(context, 'Category', transaction.categoryName!),
                if (transaction.accountName != null)
                  _detailRow(context, 'Account', transaction.accountName!),
                _detailRow(
                    context, 'Date', dateFormat.format(transaction.date)),
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty)
                  _detailRow(context, 'Notes', transaction.notes!),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Actions
          Row(
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
                  label: const Text('Edit'),
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
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TransactionEntity transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
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
