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

  const AnalyticsLineChart({
    super.key,
    required this.dates,
    required this.values,
    required this.title,
    this.lineColor = AppColors.primaryTeal,
    this.valuePrefix = '',
    this.showGradient = true,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxValue - minValue) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.borderLight.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
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
                    reservedSize: 30,
                    interval: dates.length > 10 ? dates.length / 5 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dates.length) {
                        return const Text('');
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MM/dd').format(dates[index]),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: (maxValue - minValue) / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '$valuePrefix${_formatValue(value)}',
                        style: const TextStyle(
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
              minY: minValue * 0.9,
              maxY: maxValue * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (index) => FlSpot(index.toDouble(), values[index]),
                  ),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: dates.length <= 7,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: showGradient
                      ? BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              lineColor.withOpacity(0.3),
                              lineColor.withOpacity(0.0),
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

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
