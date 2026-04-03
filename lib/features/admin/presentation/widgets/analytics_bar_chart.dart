import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String title;
  final Color barColor;
  final String valuePrefix;

  const AnalyticsBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    this.barColor = AppColors.tealBlue,
    this.valuePrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || values.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeInterval = maxValue > 0 ? _calculateInterval(maxValue) : 1.0;
    final safeMaxY = maxValue > 0 ? maxValue * 1.2 : 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        );
    final bgRodColor = isDark
        ? AppColors.tertiarySystemBackgroundDark
        : AppColors.systemGray6.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.secondaryLabelDark
                    : AppColors.secondaryLabel,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMaxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[group.x.toInt()]}\n$valuePrefix${_formatValue(rod.toY)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
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
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          _truncateLabel(labels[index]),
                          style: axisLabelStyle,
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '$valuePrefix${_formatValue(value)}',
                        style: axisLabelStyle,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                values.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index],
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: safeMaxY,
                        color: bgRodColor,
                      ),
                    ),
                  ],
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.textTertiary.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateInterval(double maxValue) {
    final raw = (maxValue * 1.2) / 4;
    if (raw < 100) return 100;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    return (raw / 1000).ceilToDouble() * 1000;
  }

  String _truncateLabel(String label) {
    if (label.length > 10) {
      return '${label.substring(0, 8)}...';
    }
    return label;
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
