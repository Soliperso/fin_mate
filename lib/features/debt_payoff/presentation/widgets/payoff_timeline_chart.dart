import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart';

/// Colours assigned to debts in chart order (cycles if > length).
/// Matches _kScheduleDebtColors in monthly_schedule_list.dart exactly.
const _kDebtColors = [
  AppColors.brandTeal,
  AppColors.systemBlue,
  AppColors.systemIndigo,
  AppColors.systemPurple,
  AppColors.systemPink,
  AppColors.systemOrange,
];

class PayoffTimelineChart extends StatelessWidget {
  final PayoffResult result;
  final List<DebtEntity> debts;

  const PayoffTimelineChart({
    super.key,
    required this.result,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (result.schedule.isEmpty) return const SizedBox.shrink();

    final initialBalance = debts.fold(0.0, (s, d) => s + d.balance);
    final maxY = max(
          initialBalance,
          result.schedule.map((s) => s.totalBalance).reduce(max),
        ) *
        1.1;
    final debtFreeLabel = DateFormat('MMM yyyy').format(result.debtFreeDate);

    final lines = _buildStackedAreas();
    if (lines.isEmpty) return const SizedBox.shrink();

    final pointCount = lines.last.spots.length; // last = smallest cumulative (debt0)

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: const Border(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debt Payoff Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _interval(maxY),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? AppColors.white : AppColors.charcoal)
                        .withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: _interval(maxY),
                      getTitlesWidget: (value, _) => Text(
                        _compactCurrency(value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= pointCount) {
                          return const SizedBox.shrink();
                        }
                        if (idx % 6 != 0 && idx != pointCount - 1) {
                          return const SizedBox.shrink();
                        }
                        final snapIdx =
                            (idx * result.schedule.length / pointCount)
                                .round()
                                .clamp(0, result.schedule.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM yy')
                                .format(result.schedule[snapIdx].date),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (pointCount - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: lines,
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: (isDark ? AppColors.white : AppColors.charcoal)
                              .withValues(alpha: 0.2),
                          strokeWidth: 0.8,
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, idx) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: bar.color ?? AppColors.textSecondary,
                            strokeWidth: 1.5,
                            strokeColor: isDark
                                ? AppColors.secondarySystemBackgroundDark
                                : AppColors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.tertiarySystemBackgroundDark
                        : AppColors.white,
                    tooltipBorder: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                    tooltipRoundedRadius: AppSizes.radiusSm,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final snapIdx =
                            (s.x * result.schedule.length / pointCount)
                                .round()
                                .clamp(0, result.schedule.length - 1);
                        final snap = result.schedule[snapIdx];
                        // lineBarsData is in reversed debt order:
                        // barIndex 0 = debts.last, barIndex N-1 = debts.first
                        final debtIdx = debts.length - 1 - s.barIndex;
                        final debt = (debtIdx >= 0 && debtIdx < debts.length)
                            ? debts[debtIdx]
                            : null;
                        final balance = debt != null
                            ? (snap.debtBalancesAfter[debt.id] ?? 0)
                            : snap.totalBalance;
                        final name = debt?.name ?? 'Total';

                        // First item carries the date header on its own line
                        final datePrefix = i == 0
                            ? '${DateFormat('MMM yyyy').format(snap.date)}\n'
                            : '';

                        return LineTooltipItem(
                          '$datePrefix$name:  \$${NumberFormat('#,##0').format(balance)}',
                          TextStyle(
                            color: isDark
                                ? AppColors.labelDark
                                : AppColors.label,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.left,
                          children: const [],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Legend
          if (debts.length > 1)
            Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.xs,
              children: debts.asMap().entries.map((e) {
                final color = _kDebtColors[e.key % _kDebtColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.value.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                );
              }).toList(),
            ),

          const SizedBox(height: AppSizes.sm),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.flag,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Debt-free: $debtFreeLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds stacked area chart data.
  ///
  /// Each debt gets a cumulative line (debt0, debt0+debt1, ..., all debts).
  /// Lines are added to [lineBarsData] in DECREASING cumulative order so that
  /// fl_chart draws the largest area first (bottom), then each smaller area
  /// covers it — producing the stacked visual effect.
  List<LineChartBarData> _buildStackedAreas() {
    final total = result.schedule.length;
    if (total == 0 || debts.isEmpty) return [];

    final targetCount = total <= 24 ? total : 24;
    final step = total / targetCount;
    final sampledIndices = List.generate(
      targetCount,
      (i) => (i * step).round().clamp(0, total - 1),
    );

    // cum[di][si] = sum of debt[0..di] balances at sample point si
    final cumulativeSpots = <List<FlSpot>>[];

    for (int di = 0; di < debts.length; di++) {
      final spots = <FlSpot>[];
      for (int si = 0; si < sampledIndices.length; si++) {
        final snap = result.schedule[sampledIndices[si]];
        double cum = 0;
        for (int k = 0; k <= di; k++) {
          cum += snap.debtBalancesAfter[debts[k].id] ?? 0.0;
        }
        spots.add(FlSpot(si.toDouble(), cum));
      }
      // Ensure ≥2 points
      if (spots.length < 2) spots.add(FlSpot(1.0, 0.0));
      cumulativeSpots.add(spots);
    }

    // Build in reverse order: largest cumulative first (drawn at bottom)
    final lines = <LineChartBarData>[];
    for (int di = debts.length - 1; di >= 0; di--) {
      final color = _kDebtColors[di % _kDebtColors.length];
      lines.add(LineChartBarData(
        spots: cumulativeSpots[di],
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.75),
        ),
      ));
    }
    return lines;
  }

  double _interval(double maxY) {
    if (maxY <= 0) return 1000;
    final raw = maxY / 4;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    if (raw < 10000) return 10000;
    return (raw / 10000).ceil() * 10000.0;
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(0)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}
