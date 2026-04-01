import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionListItem extends ConsumerWidget {
  final RecurringTransactionEntity transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Function(bool)? onToggleActive;
  final VoidCallback? onMarkPaid;

  const RecurringTransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
    this.onToggleActive,
    this.onMarkPaid,
  });

  Color _typeColor() {
    if (transaction.type == 'income') return AppColors.systemGreen;
    if (transaction.type == 'expense') return AppColors.systemRed;
    return AppColors.primaryTeal;
  }

  Color _dueColor() {
    if (transaction.isOverdue || transaction.daysUntilDue <= 0) {
      return AppColors.systemRed;
    } else if (transaction.daysUntilDue <= 7) {
      return AppColors.systemOrange;
    } else {
      return AppColors.systemGreen;
    }
  }

  String _dueLabel() {
    if (transaction.isOverdue) return 'Overdue';
    final days = transaction.daysUntilDue;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  IconData _typeIcon() {
    if (transaction.type == 'income') return CupertinoIcons.arrow_down_circle_fill;
    if (transaction.type == 'expense') return CupertinoIcons.arrow_up_circle_fill;
    return CupertinoIcons.arrow_left_right_circle_fill;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';
    final typeColor = _typeColor();
    final dueColor = _dueColor();
    final isActive = transaction.isActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark
                ? AppColors.separatorDark.withValues(alpha: 0.4)
                : AppColors.borderLight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  color: isActive
                      ? typeColor.withValues(alpha: 0.8)
                      : AppColors.textSecondary.withValues(alpha: 0.25),
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm + 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon circle
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(
                              alpha: isActive ? 0.12 : 0.06,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _typeIcon(),
                            color: isActive
                                ? typeColor
                                : typeColor.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        // Description + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transaction.description ??
                                    'Recurring ${transaction.type}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? null
                                          : AppColors.textSecondary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.repeat,
                                    size: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    transaction.frequency.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Text(
                                      '·',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.calendar,
                                    size: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM d').format(
                                      transaction.nextOccurrence,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: [
                                  _PillBadge(
                                    label: _dueLabel(),
                                    color: dueColor,
                                  ),
                                  if (transaction.categoryName != null)
                                    _PillBadge(
                                      label: transaction.categoryName!,
                                      color: AppColors.textSecondary,
                                      muted: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        // Trailing: amount + status + pay
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : isExpense ? '-' : ''}${currencyFormat.format(transaction.amount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: isActive
                                        ? (isIncome
                                            ? AppColors.success
                                            : isExpense
                                                ? AppColors.error
                                                : AppColors.textPrimary)
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            if (onMarkPaid != null && isExpense && isActive) ...[
                              const SizedBox(height: 7),
                              GestureDetector(
                                onTap: onMarkPaid,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull,
                                    ),
                                    border: Border.all(
                                      color: AppColors.success
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pay now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // 3-dot menu indicator
                        Padding(
                          padding: const EdgeInsets.only(left: AppSizes.sm),
                          child: Icon(
                            CupertinoIcons.ellipsis_vertical,
                            size: 16,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool muted;

  const _PillBadge({
    required this.label,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? 0.07 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.textSecondary : color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
