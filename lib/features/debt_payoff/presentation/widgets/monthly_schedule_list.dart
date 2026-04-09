import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart';

/// Matches _kDebtColors in payoff_timeline_chart.dart exactly.
const _kScheduleDebtColors = [
  AppColors.brandTeal,
  AppColors.systemBlue,
  AppColors.systemIndigo,
  AppColors.systemPurple,
  AppColors.systemPink,
  AppColors.systemOrange,
];

class MonthlyScheduleList extends ConsumerStatefulWidget {
  final PayoffResult result;
  final List<DebtEntity> debts;
  final int monthsToShow;

  const MonthlyScheduleList({
    super.key,
    required this.result,
    required this.debts,
    this.monthsToShow = 3,
  });

  @override
  ConsumerState<MonthlyScheduleList> createState() => _MonthlyScheduleListState();
}

class _MonthlyScheduleListState extends ConsumerState<MonthlyScheduleList> {
  bool _expanded = false;
  final Set<int> _expandedRows = {};

  void _toggleRow(int month) {
    setState(() {
      if (_expandedRows.contains(month)) {
        _expandedRows.remove(month);
      } else {
        _expandedRows.add(month);
      }
    });
  }

  Color _rowBg(bool isEven, bool isDark) {
    return isEven
        ? (isDark ? const Color(0xFF141416) : AppColors.systemGray5)
        : (isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemGray6);
  }

  List<Widget> _buildListItems({
    required List<MonthlySnapshot> months,
    required bool isDark,
    required NumberFormat currencyLarge,
    required NumberFormat currencyDetail,
    required DateFormat dateFormat,
    required Map<String, String> idToName,
    required Map<String, String> nameToId,
    required Map<String, Color> debtColorMap,
  }) {
    final items = <Widget>[];
    Map<String, double> prevBalances = {};
    int rowIndex = 0;

    for (int i = 0; i < months.length; i++) {
      final snap = months[i];

      // Year separator (only when totalMonths > 12 and year changes)
      if (i > 0 &&
          snap.date.year != months[i - 1].date.year &&
          widget.result.totalMonths > 12) {
        items.add(_YearSeparatorRow(year: snap.date.year, isDark: isDark));
      }

      // Paid-off milestone detection
      for (final entry in snap.debtBalancesAfter.entries) {
        final balBefore = prevBalances[entry.key] ?? -1.0;
        if (entry.value <= 0.001 && balBefore > 0.001) {
          items.add(_PaidOffMilestoneRow(
            debtName: idToName[entry.key] ?? entry.key,
          ));
        }
      }

      // Data row
      final isEven = rowIndex % 2 == 0;
      items.add(_ScheduleRow(
        snap: snap,
        isFirst: snap.month == 1,
        rowBg: _rowBg(isEven, isDark),
        isExpanded: _expandedRows.contains(snap.month),
        onToggle: () => _toggleRow(snap.month),
        idToName: idToName,
        nameToId: nameToId,
        debtColorMap: debtColorMap,
        currencyLarge: currencyLarge,
        currencyDetail: currencyDetail,
        dateFormat: dateFormat,
        isDark: isDark,
      ));
      rowIndex++;
      prevBalances = Map<String, double>.from(snap.debtBalancesAfter);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyLarge = ref.watch(currencyFormat0Provider);
    final currencyDetail = ref.watch(currencyFormat2Provider);
    final dateFormat = DateFormat('MMM yyyy', context.locale.languageCode);

    final visibleCount =
        _expanded ? widget.result.schedule.length : widget.monthsToShow;
    final months = widget.result.schedule.take(visibleCount).toList();

    if (months.isEmpty) return const SizedBox.shrink();

    // Build debt name lookup and color map
    final idToName = <String, String>{
      for (final d in widget.debts) d.id: d.name
    };
    final nameToId = <String, String>{
      for (final d in widget.debts) d.name: d.id
    };
    final debtColorMap = <String, Color>{
      for (int i = 0; i < widget.debts.length; i++)
        widget.debts[i].id: _kScheduleDebtColors[i % _kScheduleDebtColors.length]
    };

    final listItems = _buildListItems(
      months: months,
      isDark: isDark,
      currencyLarge: currencyLarge,
      currencyDetail: currencyDetail,
      dateFormat: dateFormat,
      idToName: idToName,
      nameToId: nameToId,
      debtColorMap: debtColorMap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'schedule.title'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'schedule.totalMonths'.tr(namedArgs: {'months': '${widget.result.totalMonths}'}),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        // ── Column Headers ─────────────────────────────────────────────────
        _ColumnHeadersRow(isDark: isDark),
        const SizedBox(height: AppSizes.xs),

        // ── Schedule rows ──────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Column(children: listItems),
        ),

        // ── Summary footer (when expanded) ─────────────────────────────────
        if (_expanded) ...[
          const SizedBox(height: AppSizes.sm),
          _SummaryFooter(
            totalInterest: widget.result.totalInterestPaid,
            totalPaid: widget.result.totalPaid,
            currencyLarge: currencyLarge,
            isDark: isDark,
          ),
        ],

        // ── Expand / Collapse toggle ───────────────────────────────────────
        if (widget.result.totalMonths > widget.monthsToShow) ...[
          const SizedBox(height: AppSizes.xs),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 13,
                color: AppColors.textSecondary,
              ),
              label: Text(
                _expanded
                    ? 'schedule.showLess'.tr()
                    : 'schedule.seeFullSchedule'.tr(namedArgs: {'months': '${widget.result.totalMonths}'}),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Column header row
class _ColumnHeadersRow extends StatelessWidget {
  final bool isDark;

  const _ColumnHeadersRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs + 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: _headerLabel('schedule.month'.tr()),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            flex: 2,
            child: _headerLabel('schedule.focusDebt'.tr()),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _headerLabel('schedule.balance'.tr()),
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: _headerLabel('schedule.interest'.tr()),
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          SizedBox(
            width: 62,
            child: Align(
              alignment: Alignment.centerRight,
              child: _headerLabel('schedule.payment'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Main data row with optional expandable breakdown
class _ScheduleRow extends StatelessWidget {
  final MonthlySnapshot snap;
  final bool isFirst;
  final Color rowBg;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Map<String, String> idToName;
  final Map<String, String> nameToId;
  final Map<String, Color> debtColorMap;
  final NumberFormat currencyLarge;
  final NumberFormat currencyDetail;
  final DateFormat dateFormat;
  final bool isDark;

  const _ScheduleRow({
    required this.snap,
    required this.isFirst,
    required this.rowBg,
    required this.isExpanded,
    required this.onToggle,
    required this.idToName,
    required this.nameToId,
    required this.debtColorMap,
    required this.currencyLarge,
    required this.currencyDetail,
    required this.dateFormat,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Get the focus debt ID to determine row color
    final focusDebtId = nameToId[snap.focusDebtName];
    final focusDebtColor =
        (focusDebtId != null ? debtColorMap[focusDebtId] : null) ??
            AppColors.brandTeal;

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            decoration: BoxDecoration(
              color: rowBg,
              border: Border(
                left: BorderSide(
                  color: focusDebtColor,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 2,
            ),
            child: Row(
              children: [
                // Month label
                SizedBox(
                  width: 52,
                  child: Text(
                    dateFormat.format(snap.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isFirst
                              ? AppColors.brandTeal
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),

                // Focus debt label with dot
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: focusDebtColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          snap.focusDebtName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total balance remaining
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyLarge.format(snap.totalBalance),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),

                // Interest this month
                SizedBox(
                  width: 52,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyDetail.format(snap.interestThisMonth),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.systemOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),

                // Total payment with chevron
                SizedBox(
                  width: 62,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          currencyLarge.format(snap.totalPaymentThisMonth),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.labelDark
                                        : AppColors.label,
                                  ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable breakdown panel
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? _BreakdownPanel(
                  debtPayments: snap.debtPayments,
                  idToName: idToName,
                  debtColorMap: debtColorMap,
                  currencyDetail: currencyDetail,
                  isDark: isDark,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Per-debt payment breakdown panel
class _BreakdownPanel extends StatelessWidget {
  final Map<String, double> debtPayments;
  final Map<String, String> idToName;
  final Map<String, Color> debtColorMap;
  final NumberFormat currencyDetail;
  final bool isDark;

  const _BreakdownPanel({
    required this.debtPayments,
    required this.idToName,
    required this.debtColorMap,
    required this.currencyDetail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF0E0E10) : AppColors.systemGray5,
      padding: EdgeInsets.fromLTRB(
        AppSizes.md + 52 + AppSizes.sm,
        AppSizes.xs + 2,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in debtPayments.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: debtColorMap[entry.key] ?? AppColors.brandTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(
                      idToName[entry.key] ?? entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    currencyDetail.format(entry.value),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.labelDark
                              : AppColors.label,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Year separator row (e.g., "── 2026 ──")
class _YearSeparatorRow extends StatelessWidget {
  final int year;
  final bool isDark;

  const _YearSeparatorRow({
    required this.year,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs + 2,
      ),
      color: isDark
          ? const Color(0xFF0A0A0C)
          : AppColors.systemGray5.withValues(alpha: 0.7),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 0.5,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: Text(
              '  $year  ',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).dividerColor,
              thickness: 0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paid-off milestone row (green celebration banner)
class _PaidOffMilestoneRow extends StatelessWidget {
  final String debtName;

  const _PaidOffMilestoneRow({required this.debtName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      color: AppColors.systemGreen.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: AppColors.systemGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_alt,
              size: 12,
              color: AppColors.systemGreen,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'schedule.paidOff'.tr(namedArgs: {'name': debtName}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.systemGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary footer showing totals
class _SummaryFooter extends StatelessWidget {
  final double totalInterest;
  final double totalPaid;
  final NumberFormat currencyLarge;
  final bool isDark;

  const _SummaryFooter({
    required this.totalInterest,
    required this.totalPaid,
    required this.currencyLarge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.tertiarySystemBackgroundDark
            : AppColors.systemGray6,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(
            label: 'schedule.totalInterest'.tr(),
            value: currencyLarge.format(totalInterest),
            color: AppColors.systemOrange,
          ),
          VerticalDivider(
            width: 1,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _SummaryItem(
            label: 'schedule.totalPaid'.tr(),
            value: currencyLarge.format(totalPaid),
            color: isDark ? AppColors.labelDark : AppColors.label,
          ),
        ],
      ),
    );
  }
}

/// Single summary value + label pair
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
