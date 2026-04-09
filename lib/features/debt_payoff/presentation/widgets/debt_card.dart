import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/debt_entity.dart';

class DebtCard extends ConsumerWidget {
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
        return CupertinoIcons.creditcard;
      case 'student_loan':
        return CupertinoIcons.book;
      case 'auto_loan':
        return CupertinoIcons.car_detailed;
      case 'mortgage':
        return CupertinoIcons.house;
      case 'medical':
        return CupertinoIcons.heart;
      case 'personal_loan':
        return CupertinoIcons.creditcard;
      default:
        return CupertinoIcons.money_dollar_circle;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = ref.watch(currencyFormat2Provider);
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
        dueDateLabel = 'debtCard.dueToday'.tr();
        dueDateColor = AppColors.error;
      } else if (daysUntil <= 5) {
        dueDateLabel = daysUntil == 1
            ? 'debtCard.dueInDays'.tr(namedArgs: {'days': '$daysUntil'})
            : 'debtCard.dueInDaysPlural'.tr(namedArgs: {'days': '$daysUntil'});
        dueDateColor = AppColors.warning;
      } else {
        final suffix = _daySuffix(clampedDay);
        dueDateLabel = 'debtCard.dueOnThe'.tr(namedArgs: {'day': '$clampedDay$suffix'});
        dueDateColor = AppColors.textSecondary;
      }
    }

    // ── Interest trap ─────────────────────────────────────────────────────
    String? interestTrapText;
    if (debt.balance > 0 && debt.minimumPayment > 0) {
      final pct = (debt.monthlyInterest / debt.minimumPayment) * 100;
      if (pct >= 50) {
        interestTrapText =
            'debtCard.interestTrap'.tr(namedArgs: {'pct': '${pct.round()}'});
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTeal,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_up_circle_fill,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'debtCard.nextUp'.tr(namedArgs: {'reason': focusReason}),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
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
                    CupertinoIcons.ellipsis_vertical,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'log_payment',
                      child: _MenuRow(
                        icon: CupertinoIcons.add_circled,
                        label: 'debtCard.logPayment'.tr(),
                        color: AppColors.success,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: CupertinoIcons.pencil,
                        label: 'debtCard.editDebt'.tr(),
                        color: AppColors.systemBlue,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: _MenuRow(
                        icon: CupertinoIcons.clock,
                        label: 'debtCard.paymentHistory'.tr(),
                        color: AppColors.brandTeal,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: CupertinoIcons.trash,
                        label: 'debtCard.deleteDebt'.tr(),
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progressValue),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.success,
                          ),
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
                          text: 'debtCard.minPayment'.tr(namedArgs: {'amount': currencyFormat.format(debt.minimumPayment)}),
                        ),
                        if (monthsLeft != null) ...[
                          const TextSpan(text: '  ·  '),
                          TextSpan(
                            text: 'debtCard.monthsLeft'.tr(namedArgs: {'months': '$monthsLeft'}),
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
                  child: Text(
                    'debtCard.logPayment'.tr(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            // ── Due date chip ─────────────────────────────────────────────
            if (dueDateLabel != null) ...[
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Icon(CupertinoIcons.calendar,
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
                    Icon(CupertinoIcons.exclamationmark_triangle,
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
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(CupertinoIcons.trash_fill, color: AppColors.error, size: 28),
        title: Text('debtCard.deleteTitle'.tr()),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        content: Text('debtCard.deleteMessage'.tr(namedArgs: {'name': debt.name})),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('debtCard.delete'.tr()),
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
