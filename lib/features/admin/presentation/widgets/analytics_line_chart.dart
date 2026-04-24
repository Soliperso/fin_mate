import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  const AnalyticsLineChart({
    super.key,
    required this.dates,
    required this.values,
    required this.title,
    this.lineColor = AppColors.primaryTeal,
    this.valuePrefix = '',
    this.showGradient = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty || values.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs();
    final safeMinY = range > 0 ? minValue * 0.9 : -1.0;
    final safeMaxY = range > 0 ? maxValue * 1.1 : 1.0;

    final interval = _calculateInterval(safeMaxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (compact
                  ? Theme.of(context).textTheme.bodySmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.secondaryLabelDark
                : AppColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: compact ? 120 : 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.textTertiary.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !compact,
                    reservedSize: compact ? 0 : 24,
                    interval: dates.length > 10 ? (dates.length / 5).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dates.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          DateFormat('MM/dd').format(dates[index]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '$valuePrefix${_formatValue(value)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (dates.length - 1).toDouble(),
              minY: safeMinY,
              maxY: safeMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (index) => FlSpot(index.toDouble(), values[index]),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: lineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: showGradient
                      ? BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              lineColor.withValues(alpha: 0.2),
                              lineColor.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        )
                      : BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = dates[spot.x.toInt()];
                      return LineTooltipItem(
                        '${DateFormat('MMM dd').format(date)}\n$valuePrefix${_formatValue(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateInterval(double maxY) {
    final raw = maxY / 4;
    if (raw <= 0) return 1;
    if (raw < 100) return 100;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    return (raw / 1000).ceilToDouble() * 1000;
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
