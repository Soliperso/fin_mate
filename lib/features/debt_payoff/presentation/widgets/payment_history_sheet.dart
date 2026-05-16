import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../providers/debt_providers.dart';

class PaymentHistorySheet extends ConsumerWidget {
  final DebtEntity debt;

  const PaymentHistorySheet({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final dateFormat = DateFormat(AppDateFormats.mediumDate, context.locale.languageCode);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.xs,
              AppSizes.sm,
              AppSizes.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'paymentHistory.title'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        debt.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CircularIconButton(
                  icon: CupertinoIcons.xmark,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ───────────────────────────────────────────────────
          Flexible(
            child: paymentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonCard(),
                    SizedBox(height: AppSizes.sm),
                    SkeletonCard(),
                    SizedBox(height: AppSizes.sm),
                    SkeletonCard(),
                  ],
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Center(
                  child: Text(
                    'paymentHistory.failedToLoad'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                    child: EmptyStateCard(
                      icon: CupertinoIcons.creditcard,
                      title: 'paymentHistory.noPayments'.tr(),
                      message: 'paymentHistory.noPaymentsMessage'.tr(),
                      backgroundColor: AppColors.brandTeal,
                    ),
                  );
                }

                final totalPaid =
                    payments.fold<double>(0, (s, p) => s + p.amount);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.md,
                    AppSizes.lg,
                  ),
                  shrinkWrap: true,
                  children: [
                    // Summary banner
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.money_dollar,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              payments.length == 1
                                  ? 'paymentHistory.paymentsLogged'.tr(
                                      namedArgs: {
                                          'count': '${payments.length}'
                                        })
                                  : 'paymentHistory.paymentsLoggedPlural'.tr(
                                      namedArgs: {
                                          'count': '${payments.length}'
                                        }),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.success),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'paymentHistory.totalPaid'.tr(namedArgs: {
                              'amount': currencyFormat.format(totalPaid)
                            }),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // Payment items
                    ...payments.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      final isLast = idx == payments.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm - 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.checkmark,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateFormat.format(p.paymentDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (p.notes != null &&
                                          p.notes!.isNotEmpty)
                                        Text(
                                          p.notes!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text(
                                  currencyFormat.format(p.amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                _UndoPaymentButton(
                                  payment: p,
                                  debt: debt,
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 44),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UndoPaymentButton extends ConsumerWidget {
  final DebtPaymentEntity payment;
  final DebtEntity debt;

  const _UndoPaymentButton({
    required this.payment,
    required this.debt,
  });

  Future<void> _showConfirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('paymentHistory.undoPayment'.tr()),
        content: Text(
          'paymentHistory.undoConfirmation'.tr(
            namedArgs: {
              'amount':
                  NumberFormat.currency(symbol: '\$').format(payment.amount)
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('paymentHistory.undoButton'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(debtNotifierProvider.notifier).deletePayment(
          paymentId: payment.id,
          debtId: payment.debtId,
          amount: payment.amount,
        );

    if (!context.mounted) return;

    if (success) {
      // Invalidate payments provider to refresh the list
      ref.invalidate(debtPaymentsProvider(debt.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('paymentHistory.undoSuccess'.tr()),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('paymentHistory.undoFailed'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showConfirmDelete(context, ref),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.trash,
          color: AppColors.error,
          size: 16,
        ),
      ),
    );
  }
}
