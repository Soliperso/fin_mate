import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String title;
  final Color barColor;
  final String valuePrefix;
  final bool showTrendBadge;

  const AnalyticsBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    this.barColor = AppColors.tealBlue,
    this.valuePrefix = '',
    this.showTrendBadge = false,
  });

  double get _trendPct {
    if (values.length < 2) return 0;
    final first = values.first;
    final last = values.last;
    if (first == 0) return last > 0 ? 100 : 0;
    return ((last - first) / first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || values.isEmpty) {
      return SizedBox(
        height: 220,
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
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxValue > 0 ? maxValue * 1.2 : 1.0;
    final safeInterval = maxValue > 0 ? _interval(safeMaxY) : 1.0;

    final axisStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        );
    final bgRodColor = isDark
        ? AppColors.tertiarySystemBackgroundDark
        : AppColors.systemGray6.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showTrendBadge && values.length >= 2) _trendBadge(context),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // ── Chart ────────────────────────────────────────────────────────────
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMaxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${labels[group.x]}\n$valuePrefix${_fmt(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _truncate(labels[i]),
                          style: axisStyle,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: safeInterval,
                    getTitlesWidget: (v, _) => Text(
                      '$valuePrefix${_fmt(v)}',
                      style: axisStyle,
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.textTertiary.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                values.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      gradient: LinearGradient(
                        colors: [
                          barColor,
                          barColor.withValues(alpha: 0.70),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4.5)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: safeMaxY,
                        color: bgRodColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  double _interval(double maxY) {
    final raw = maxY / 4;
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

  String _truncate(String label) =>
      label.length > 10 ? '${label.substring(0, 8)}…' : label;

  String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}
