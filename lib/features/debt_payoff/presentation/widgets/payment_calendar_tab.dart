import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../providers/debt_providers.dart';
import 'log_payment_bottom_sheet.dart';

class PaymentCalendarTab extends ConsumerStatefulWidget {
  const PaymentCalendarTab({super.key});

  @override
  ConsumerState<PaymentCalendarTab> createState() => _PaymentCalendarTabState();
}

class _PaymentCalendarTabState extends ConsumerState<PaymentCalendarTab> {
  late DateTime _displayMonth;

  static const int _maxMonthsAhead = 12;
  static const int _maxMonthsBehind = 24;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _canGoPrev {
    final limit =
        DateTime(_currentMonth.year, _currentMonth.month - _maxMonthsBehind);
    return _displayMonth.isAfter(limit);
  }

  bool get _canGoNext {
    final limit =
        DateTime(_currentMonth.year, _currentMonth.month + _maxMonthsAhead);
    return _displayMonth.isBefore(limit);
  }

  void _prevMonth() {
    if (_canGoPrev) {
      setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (_canGoNext) {
      setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      });
    }
  }

  void _goToToday() {
    setState(() => _displayMonth = _currentMonth);
  }

  Future<void> _openLogPayment(DebtEntity debt) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogPaymentBottomSheet(debt: debt),
    );
    if (result == true) {
      ref.invalidate(allDebtPaymentsProvider);
    }
  }

  void _onDayTapped(int day, List<DebtEntity> debts) {
    final dueDebts = debts.where((d) => d.dueDay == day).toList();
    if (dueDebts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(
        day: day,
        displayMonth: _displayMonth,
        dueDebts: dueDebts,
        onPay: _openLogPayment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final paymentsAsync = ref.watch(allDebtPaymentsProvider);
    final currencyFormat = ref.watch(currencyFormat2Provider);

    final debts = debtsAsync.valueOrNull ?? [];
    final payments = paymentsAsync.valueOrNull ?? [];

    final paymentDates = _paymentDatesInMonth(payments, _displayMonth);
    final dueDays =
        debts.where((d) => d.dueDay != null).map((d) => d.dueDay!).toSet();
    final upcoming = _upcomingPayments(debts);
    final pastDue = _pastDuePayments(debts, payments);
    final isCurrentMonth = _displayMonth == _currentMonth;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(debtsProvider);
        ref.invalidate(allDebtPaymentsProvider);
      },
      color: AppColors.brandTeal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.md, AppSizes.md, AppSizes.md, 100),
        children: [
          _CalendarCard(
            displayMonth: _displayMonth,
            paymentDates: paymentDates,
            dueDays: dueDays,
            onPrev: _canGoPrev ? _prevMonth : null,
            onNext: _canGoNext ? _nextMonth : null,
            isCurrentMonth: isCurrentMonth,
            onGoToToday: _goToToday,
            onDayTap: (day) => _onDayTapped(day, debts),
          ),
          const SizedBox(height: AppSizes.md),
          if (pastDue.isNotEmpty) ...[
            _SectionLabel(
              label: 'track.pastDue'.tr(),
              color: AppColors.error,
              icon: CupertinoIcons.exclamationmark_circle_fill,
            ),
            const SizedBox(height: AppSizes.xs),
            ...pastDue.map((d) => _PaymentRow(
                  debt: d,
                  isPastDue: true,
                  currencyFormat: currencyFormat,
                  onTap: () => _openLogPayment(d),
                )),
            const SizedBox(height: AppSizes.md),
          ],
          _SectionLabel(
            label: 'track.upcoming'.tr(),
            color: AppColors.brandTeal,
            icon: CupertinoIcons.calendar,
          ),
          const SizedBox(height: AppSizes.xs),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Center(
                child: Text(
                  'track.noDueDates'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...upcoming.map((item) => _PaymentRow(
                  debt: item.$1,
                  daysUntil: item.$2,
                  isPastDue: false,
                  currencyFormat: currencyFormat,
                )),
        ],
      ),
    );
  }

  Set<int> _paymentDatesInMonth(
      List<DebtPaymentEntity> payments, DateTime month) {
    return payments
        .where((p) =>
            p.paymentDate.year == month.year &&
            p.paymentDate.month == month.month)
        .map((p) => p.paymentDate.day)
        .toSet();
  }

  List<(DebtEntity, int)> _upcomingPayments(List<DebtEntity> debts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <(DebtEntity, int)>[];
    for (final d in debts) {
      if (d.dueDay == null) continue;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final clamped = d.dueDay!.clamp(1, daysInMonth);
      DateTime nextDue = DateTime(now.year, now.month, clamped);
      if (!nextDue.isAfter(today)) {
        final daysInNext = DateTime(now.year, now.month + 2, 0).day;
        final clampedNext = d.dueDay!.clamp(1, daysInNext);
        nextDue = DateTime(now.year, now.month + 1, clampedNext);
      }
      result.add((d, nextDue.difference(today).inDays));
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result;
  }

  List<DebtEntity> _pastDuePayments(
      List<DebtEntity> debts, List<DebtPaymentEntity> payments) {
    final now = DateTime.now();
    final result = <DebtEntity>[];
    for (final d in debts) {
      if (d.dueDay == null) continue;
      if (d.dueDay! >= now.day) continue;
      final hasPaidThisMonth = payments.any((p) =>
          p.debtId == d.id &&
          p.paymentDate.year == now.year &&
          p.paymentDate.month == now.month);
      if (!hasPaidThisMonth) result.add(d);
    }
    return result;
  }
}

// ── Calendar card ─────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final DateTime displayMonth;
  final Set<int> paymentDates;
  final Set<int> dueDays;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool isCurrentMonth;
  final VoidCallback onGoToToday;
  final void Function(int day) onDayTap;

  const _CalendarCard({
    required this.displayMonth,
    required this.paymentDates,
    required this.dueDays,
    required this.onPrev,
    required this.onNext,
    required this.isCurrentMonth,
    required this.onGoToToday,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.secondarySystemBackground;

    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    // weekday: 1=Mon … 7=Sun; offset to 0=Sun
    final startOffset = (firstDay.weekday % 7);
    final today = DateTime.now();
    final isViewingCurrentMonth =
        displayMonth.year == today.year && displayMonth.month == today.month;

    final monthLabel = DateFormat('MMMM yyyy').format(displayMonth);
    const dayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(CupertinoIcons.chevron_left, size: 16),
                color: onPrev != null
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (!isCurrentMonth) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: onGoToToday,
                        child: Text(
                          'track.today'.tr(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.brandTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(CupertinoIcons.chevron_right, size: 16),
                color: onNext != null
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Day headers
          Row(
            children: dayLabels
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSizes.xs),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final isToday = isViewingCurrentMonth && day == today.day;
              final hasPayment = paymentDates.contains(day);
              final isDue = dueDays.contains(day);
              final isTappable = isDue;

              return GestureDetector(
                onTap: isTappable ? () => onDayTap(day) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: isToday
                          ? BoxDecoration(
                              color:
                                  AppColors.brandTeal.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            )
                          : null,
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppColors.brandTeal : null,
                            ),
                      ),
                    ),
                    if (hasPayment || isDue)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasPayment)
                            Container(
                              width: 5,
                              height: 5,
                              margin: isDue
                                  ? const EdgeInsets.only(right: 2)
                                  : EdgeInsets.zero,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (isDue)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'track.paymentLogged'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSizes.md),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'track.paymentDue'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day detail sheet ──────────────────────────────────────────────────────────

class _DayDetailSheet extends ConsumerWidget {
  final int day;
  final DateTime displayMonth;
  final List<DebtEntity> dueDebts;
  final Future<void> Function(DebtEntity) onPay;

  const _DayDetailSheet({
    required this.day,
    required this.displayMonth,
    required this.dueDebts,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPayments = ref.watch(allDebtPaymentsProvider).valueOrNull ?? [];
    final paidDebtIds = allPayments
        .where((p) =>
            p.paymentDate.year == displayMonth.year &&
            p.paymentDate.month == displayMonth.month &&
            p.paymentDate.day == day)
        .map((p) => p.debtId)
        .toSet();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'track.dayDetails'.tr(namedArgs: {'day': '$day'}),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            DateFormat('MMMM yyyy').format(displayMonth),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.md),
          if (dueDebts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(
                child: Text(
                  'track.nothingOnThisDay'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...dueDebts.map((debt) {
              final isPaid = paidDebtIds.contains(debt.id);
              return _DayDebtRow(
                debt: debt,
                isPaid: isPaid,
                onPay: isPaid
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await onPay(debt);
                      },
              );
            }),
        ],
      ),
    );
  }
}

class _DayDebtRow extends StatelessWidget {
  final DebtEntity debt;
  final bool isPaid;
  final VoidCallback? onPay;

  const _DayDebtRow({required this.debt, required this.isPaid, this.onPay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  debt.debtTypeDisplay,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isPaid)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  'track.alreadyPaid'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const StadiumBorder(),
              ),
              onPressed: onPay,
              child: Text(
                'track.markAsPaid'.tr(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SectionLabel({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSizes.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

// ── Payment row ───────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final DebtEntity debt;
  final bool isPastDue;
  final int? daysUntil;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  const _PaymentRow({
    required this.debt,
    required this.isPastDue,
    required this.currencyFormat,
    this.daysUntil,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPastDue ? AppColors.error : AppColors.textSecondary;
    final bgColor = isPastDue
        ? AppColors.error.withValues(alpha: 0.07)
        : Colors.transparent;

    String subtitle;
    if (isPastDue) {
      subtitle = 'track.missedThisMonth'.tr();
    } else if (daysUntil == 0) {
      subtitle = 'track.dueToday'.tr();
    } else if (daysUntil == 1) {
      subtitle = 'track.dueTomorrow'.tr();
    } else {
      subtitle = 'track.dueInDays'.tr(namedArgs: {'days': '$daysUntil'});
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isPastDue
                ? AppColors.error.withValues(alpha: 0.25)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            if (isPastDue)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(debt.minimumPayment),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                  ),
                  Text(
                    'track.markAsPaid'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              )
            else
              Text(
                currencyFormat.format(debt.minimumPayment),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
