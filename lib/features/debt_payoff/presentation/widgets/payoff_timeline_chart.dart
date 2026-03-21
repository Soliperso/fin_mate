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
const _kDebtColors = [
  AppColors.error,
  AppColors.info,
  AppColors.warning,
  AppColors.success,
  AppColors.primaryTeal,
  AppColors.systemGray,
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

    // Build per-debt line data. Fall back to a single total line when no
    // per-debt data is available (e.g. empty debtBalancesAfter).
    final lines = _buildLines();
    if (lines.isEmpty) return const SizedBox.shrink();

    // x-axis point count comes from the first line
    final pointCount = lines.first.spots.length;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: const Border(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payoff Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSizes.xs,
                  runSpacing: 4,
                  children: debts.asMap().entries.map((e) {
                    final color = _kDebtColors[e.key % _kDebtColors.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          e.value.name,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
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
                              fontSize: 9,
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
                                  fontSize: 9,
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
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.secondarySystemBackgroundDark
                        : AppColors.secondarySystemBackground,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final snapIdx =
                            (s.x * result.schedule.length / pointCount)
                                .round()
                                .clamp(0, result.schedule.length - 1);
                        final snap = result.schedule[snapIdx];
                        final debtIdx = s.barIndex;
                        final debtName = debtIdx < debts.length
                            ? debts[debtIdx].name
                            : 'Total';
                        final balance = debtIdx < debts.length
                            ? (snap.debtBalancesAfter[debts[debtIdx].id] ?? 0)
                            : snap.totalBalance;
                        return LineTooltipItem(
                          '${DateFormat('MMM yyyy').format(snap.date)}\n'
                          '$debtName: \$${NumberFormat('#,##0').format(balance)}',
                          TextStyle(
                            color: isDark
                                ? AppColors.labelDark
                                : AppColors.label,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
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

  /// Builds one [LineChartBarData] per debt using per-debt balance history.
  List<LineChartBarData> _buildLines() {
    final total = result.schedule.length;
    if (total == 0) return [];

    final targetCount = total <= 24 ? total : 24;
    final step = total / targetCount;

    // Sampled schedule indices
    final sampledIndices = List.generate(targetCount, (i) {
      return (i * step).round().clamp(0, total - 1);
    });

    return debts.asMap().entries.map((entry) {
      final debt = entry.value;
      final color = _kDebtColors[entry.key % _kDebtColors.length];

      final spots = <FlSpot>[];
      for (int i = 0; i < sampledIndices.length; i++) {
        final snap = result.schedule[sampledIndices[i]];
        final balance = snap.debtBalancesAfter[debt.id] ?? 0.0;
        spots.add(FlSpot(i.toDouble(), balance));
      }
      // Only drop to zero if the debt is actually fully paid off in the schedule
      final lastBalance =
          result.schedule.last.debtBalancesAfter[debt.id] ?? 0.0;
      if (spots.isNotEmpty && spots.last.y > 0.01 && lastBalance < 0.01) {
        spots.add(FlSpot(targetCount.toDouble(), 0));
      }
      // fl_chart needs ≥ 2 points to draw a line
      if (spots.length < 2) spots.add(FlSpot(1.0, 0.0));

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.10),
              color.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();
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
