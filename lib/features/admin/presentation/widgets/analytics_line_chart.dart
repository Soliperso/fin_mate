import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> values;
  final String title;
  final Color lineColor;
  final String valuePrefix;
  final bool showGradient;
  final bool compact;
  final bool showTrendBadge;

  /// Optional second series for a dual-line chart (e.g. Income vs Expenses).
  final List<double>? secondValues;
  final Color secondLineColor;

  /// Legend labels — shown when [secondValues] is provided.
  final String? firstLabel;
  final String? secondLabel;

  const AnalyticsLineChart({
    super.key,
    required this.dates,
    required this.values,
    required this.title,
    this.lineColor = AppColors.primaryTeal,
    this.valuePrefix = '',
    this.showGradient = true,
    this.compact = false,
    this.showTrendBadge = true,
    this.secondValues,
    this.secondLineColor = AppColors.systemRed,
    this.firstLabel,
    this.secondLabel,
  });

  bool get _isDual => secondValues != null && secondValues!.isNotEmpty;

  double get _trendPct {
    if (values.length < 2) return 0;
    final first = values.first;
    final last = values.last;
    if (first == 0) return last > 0 ? 100 : 0;
    return ((last - first) / first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty || values.isEmpty) {
      return SizedBox(
        height: compact ? 140 : 220,
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allValues = [...values, if (_isDual) ...secondValues!];
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final safeMinY = range > 0 ? minVal - range * 0.1 : -1.0;
    final safeMaxY = range > 0 ? maxVal + range * 0.15 : 1.0;
    final interval = _interval(safeMaxY - safeMinY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: (compact
                        ? Theme.of(context).textTheme.bodySmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showTrendBadge && !_isDual && values.length >= 2)
              _trendBadge(context),
          ],
        ),

        // ── Legend (dual-line only) ────────────────────────────────────────
        if (_isDual && firstLabel != null && secondLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _legendDot(context, lineColor, firstLabel!),
              const SizedBox(width: AppSizes.md),
              _legendDot(context, secondLineColor, secondLabel!),
            ],
          ),
        ],

        const SizedBox(height: AppSizes.sm),

        // ── Chart ─────────────────────────────────────────────────────────
        SizedBox(
          height: compact ? 140 : 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.textTertiary.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !compact,
                    reservedSize: compact ? 0 : 24,
                    interval: dates.length > 10
                        ? (dates.length / 5).ceilToDouble()
                        : 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= dates.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat(AppDateFormats.shortDate).format(dates[i]),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !compact,
                    reservedSize: compact ? 0 : 52,
                    interval: interval,
                    getTitlesWidget: (v, _) => Text(
                      '$valuePrefix${_fmt(v)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (dates.length - 1).toDouble(),
              minY: safeMinY,
              maxY: safeMaxY,
              lineBarsData: [
                _line(values, lineColor),
                if (_isDual) _line(secondValues!, secondLineColor),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final date = dates[spot.x.toInt()];
                    final isSecond = spot.barIndex == 1;
                    final lbl =
                        isSecond ? (secondLabel ?? '') : (firstLabel ?? '');
                    return LineTooltipItem(
                      '${lbl.isNotEmpty ? '$lbl · ' : ''}'
                      '${DateFormat(AppDateFormats.shortDate).format(date)}\n'
                      '$valuePrefix${_fmt(spot.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(List<double> data, Color color) => LineChartBarData(
        spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: showGradient
            ? BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : BarAreaData(show: false),
      );

  Widget _trendBadge(BuildContext context) {
    final pct = _trendPct;
    final up = pct >= 0;
    final color = up ? AppColors.systemGreen : AppColors.systemRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up
                ? CupertinoIcons.arrow_up_right
                : CupertinoIcons.arrow_down_right,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      );

  double _interval(double range) {
    final raw = range / 4;
    if (raw <= 0) return 1;
    if (raw < 5) return 5;
    if (raw < 10) return 10;
    if (raw < 25) return 25;
    if (raw < 50) return 50;
    if (raw < 100) return 100;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    return (raw / 1000).ceilToDouble() * 1000;
  }

  String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}
