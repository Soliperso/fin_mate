import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debt_providers.dart';

class PaymentHistorySheet extends ConsumerWidget {
  final DebtEntity debt;

  const PaymentHistorySheet({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.systemGray4,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.xs, AppSizes.lg, AppSizes.md,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment History',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          debt.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: paymentsAsync.when(
                  loading: () => ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSizes.md),
                    children: const [
                      SkeletonCard(),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(),
                    ],
                  ),
                  error: (_, _) => Center(
                    child: Text(
                      'Failed to load payments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return EmptyState(
                        icon: CupertinoIcons.creditcard,
                        title: 'No Payments Yet',
                        message:
                            'Log your first payment to track your progress.',
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.sm,
                      ),
                      itemCount: payments.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 40),
                      itemBuilder: (context, idx) {
                        final p = payments[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
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
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
