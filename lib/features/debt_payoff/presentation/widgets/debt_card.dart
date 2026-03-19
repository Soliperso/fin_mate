import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/debt_entity.dart';

class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback onLogPayment;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;
  final bool isFocusDebt;
  final String focusReason;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onLogPayment,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
    this.isFocusDebt = false,
    this.focusReason = '',
  });

  IconData _iconForType(String debtType) {
    switch (debtType) {
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'student_loan':
        return Icons.school_rounded;
      case 'auto_loan':
        return Icons.directions_car_rounded;
      case 'mortgage':
        return Icons.home_rounded;
      case 'medical':
        return Icons.local_hospital_rounded;
      case 'personal_loan':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final monthsLeft = debt.monthsToPayoffAtMinimum;

    // ── Progress ──────────────────────────────────────────────────────────
    double? progressValue;
    if (debt.originalBalance != null &&
        debt.originalBalance! > 0 &&
        debt.balance <= debt.originalBalance!) {
      progressValue =
          (debt.originalBalance! - debt.balance) / debt.originalBalance!;
    }
    final paidPercent = progressValue != null
        ? '${(progressValue * 100).toStringAsFixed(0)}% paid'
        : null;

    // ── Due date ──────────────────────────────────────────────────────────
    String? dueDateLabel;
    Color? dueDateColor;
    int daysUntil = 0;
    if (debt.dueDay != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
      final clampedDay = debt.dueDay!.clamp(1, daysInCurrentMonth);
      DateTime nextDue = DateTime(now.year, now.month, clampedDay);
      if (!nextDue.isAfter(today)) {
        final daysInNextMonth = DateTime(now.year, now.month + 2, 0).day;
        final clampedDayNext = debt.dueDay!.clamp(1, daysInNextMonth);
        nextDue = DateTime(now.year, now.month + 1, clampedDayNext);
      }
      daysUntil = nextDue.difference(today).inDays;
      if (daysUntil == 0) {
        dueDateLabel = 'Due today';
        dueDateColor = AppColors.error;
      } else if (daysUntil <= 5) {
        dueDateLabel = 'Due in $daysUntil day${daysUntil == 1 ? '' : 's'}';
        dueDateColor = AppColors.warning;
      } else {
        final suffix = _daySuffix(clampedDay);
        dueDateLabel = 'Due on the $clampedDay$suffix';
        dueDateColor = AppColors.textSecondary;
      }
    }

    // ── Interest trap ─────────────────────────────────────────────────────
    String? interestTrapText;
    if (debt.balance > 0 && debt.minimumPayment > 0) {
      final pct = (debt.monthlyInterest / debt.minimumPayment) * 100;
      if (pct >= 50) {
        interestTrapText =
            '${pct.round()}% of your min payment goes to interest';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isFocusDebt
              ? AppColors.brandTeal.withValues(alpha: 0.45)
              : isDark
                  ? AppColors.separatorDark.withValues(alpha: 0.5)
                  : AppColors.separator.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _iconForType(debt.debtType),
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                // Name + type + optional focus chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        debt.debtTypeDisplay,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (isFocusDebt && focusReason.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTeal.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: AppColors.brandTeal.withValues(alpha: 0.35),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            focusReason,
                            style: const TextStyle(
                              color: AppColors.brandTeal,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Balance + APR
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(debt.balance),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error),
                    ),
                    Text(
                      '${debt.interestRate.toStringAsFixed(1)}% APR',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.xs),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.separatorDark
                          : AppColors.separator,
                      width: 0.5,
                    ),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'log_payment',
                      child: _MenuRow(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Log Payment',
                        color: AppColors.success,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: 'Edit Debt',
                        color: AppColors.systemBlue,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: _MenuRow(
                        icon: Icons.history_rounded,
                        label: 'Payment History',
                        color: AppColors.brandTeal,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete Debt',
                        isDestructive: true,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'log_payment':
                        onLogPayment();
                      case 'edit':
                        onEdit();
                      case 'history':
                        onHistory();
                      case 'delete':
                        _confirmDelete(context);
                    }
                  },
                ),
              ],
            ),

            // ── Progress bar ──────────────────────────────────────────────
            if (progressValue != null) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 6,
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    paidPercent!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSizes.sm),

            // ── Footer: min payment + months remaining ────────────────────
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Min: ${currencyFormat.format(debt.minimumPayment)}/mo',
                        ),
                        if (monthsLeft != null) ...[
                          const TextSpan(text: '  ·  '),
                          TextSpan(text: '~$monthsLeft mo left'),
                        ],
                      ],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                OutlinedButton(
                  onPressed: onLogPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: const Text(
                    'Log Payment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            // ── Due date chip ─────────────────────────────────────────────
            if (dueDateLabel != null) ...[
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 11, color: dueDateColor),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    dueDateLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: dueDateColor,
                          fontWeight: daysUntil <= 5
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ],

            // ── Interest trap warning ─────────────────────────────────────
            if (interestTrapText != null) ...[
              const SizedBox(height: AppSizes.xs + 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs + 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.warning),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        interestTrapText,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        title: const Text('Delete Debt'),
        content: Text('Remove "${debt.name}" from your debt tracker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = isDestructive
        ? AppColors.error
        : color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: resolvedColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: resolvedColor),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.85)
                : AppColors.textSecondary,
            fontWeight: isDestructive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
