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

  const DebtCard({
    super.key,
    required this.debt,
    required this.onLogPayment,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final monthsLeft = debt.monthsToPayoffAtMinimum;

    // Progress: how much has been paid off
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isDark
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
                // Name + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        debt.debtTypeDisplay,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                // Balance + overflow menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(debt.balance),
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                    ),
                    Text(
                      '${debt.interestRate.toStringAsFixed(1)}% APR',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: _MenuRow(
                        icon: Icons.history_rounded,
                        label: 'Payment History',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        isDestructive: true,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
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
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
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
                          text: 'Min: ${currencyFormat.format(debt.minimumPayment)}/mo',
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

  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.error : Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSizes.sm),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
