import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/glass_container.dart';

enum ChartType { line, bar }

class CashFlowChart extends StatefulWidget {
  final List<MonthlyFlowData> flowData;

  const CashFlowChart({
    super.key,
    required this.flowData,
  });

  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> {
  ChartType _selectedChartType = ChartType.line;

  @override
  Widget build(BuildContext context) {
    if (widget.flowData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);

    return GlassContainer(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartTypeButton(
                      context,
                      icon: Icons.show_chart,
                      type: ChartType.line,
                      isSelected: _selectedChartType == ChartType.line,
                    ),
                    _buildChartTypeButton(
                      context,
                      icon: Icons.bar_chart,
                      type: ChartType.bar,
                      isSelected: _selectedChartType == ChartType.bar,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              _buildLegendItem(
                context,
                color: AppColors.success,
                label: 'Income',
              ),
              const SizedBox(width: AppSizes.md),
              _buildLegendItem(
                context,
                color: AppColors.error,
                label: 'Expenses',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedChartType == ChartType.line
                  ? _buildLineChart(currencyFormat)
                  : _buildBarChart(currencyFormat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(
    BuildContext context, {
    required IconData icon,
    required ChartType type,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emeraldGreen.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLineChart(NumberFormat currencyFormat) {
    return LineChart(
      key: const ValueKey('line_chart'),
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textTertiary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: _calculateInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  currencyFormat.format(value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.flowData.length) {
                  final data = widget.flowData[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(data.month),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                return const SizedBox.shrink();
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
        maxX: (widget.flowData.length - 1).toDouble(),
        minY: 0,
        maxY: _calculateMaxY(),
        lineBarsData: [
          // Income line
          LineChartBarData(
            spots: widget.flowData
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.income,
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.success,
                  strokeWidth: 2,
                  strokeColor: AppColors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Expenses line
          LineChartBarData(
            spots: widget.flowData
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.expenses,
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.error,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.error,
                  strokeWidth: 2,
                  strokeColor: AppColors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.2),
                  AppColors.error.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
                final isIncome = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIncome ? 'Income' : 'Expenses'}\n${format.format(spot.y)}',
                  TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(NumberFormat currencyFormat) {
    return BarChart(
      key: const ValueKey('bar_chart'),
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
              final isIncome = rodIndex == 0;
              return BarTooltipItem(
                '${isIncome ? 'Income' : 'Expenses'}\n${format.format(rod.toY)}',
                TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.flowData.length) {
                  final data = widget.flowData[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(data.month),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: _calculateInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  currencyFormat.format(value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textTertiary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.flowData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.income,
                color: AppColors.success,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: data.expenses,
                color: AppColors.error,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, {required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  double _calculateMaxY() {
    double maxValue = 0;
    for (final data in widget.flowData) {
      if (data.income > maxValue) maxValue = data.income;
      if (data.expenses > maxValue) maxValue = data.expenses;
    }
    // Add 20% padding to max value
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    // Aim for about 4-5 grid lines
    final rawInterval = maxY / 4;
    // Round to nice numbers
    if (rawInterval < 100) return 100;
    if (rawInterval < 500) return 500;
    if (rawInterval < 1000) return 1000;
    if (rawInterval < 5000) return 5000;
    return (rawInterval / 1000).ceil() * 1000;
  }
}

/// Data model for monthly cash flow
class MonthlyFlowData {
  final DateTime month;
  final double income;
  final double expenses;

  const MonthlyFlowData({
    required this.month,
    required this.income,
    required this.expenses,
  });

  double get netBalance => income - expenses;
}
