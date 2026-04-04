import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsPieChart extends StatefulWidget {
  final List<String> labels;
  final List<double> values;
  final String title;
  final List<Color>? colors;

  const AnalyticsPieChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    this.colors,
  });

  @override
  State<AnalyticsPieChart> createState() => _AnalyticsPieChartState();
}

class _AnalyticsPieChartState extends State<AnalyticsPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty || widget.values.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorsList = widget.colors ??
        [
          AppColors.brandTeal,
          AppColors.tealBlue,
          AppColors.systemBlue,
          AppColors.systemOrange,
          AppColors.systemRed,
          AppColors.systemPurple,
        ];

    final total = widget.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.secondaryLabelDark
                    : AppColors.secondaryLabel,
              ),
        ),
        const SizedBox(height: AppSizes.md),
        Center(
          child: SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: List.generate(widget.values.length, (index) {
                      final isTouched = index == _touchedIndex;
                      final percentage = widget.values[index] / total * 100;
                      return PieChartSectionData(
                        color: colorsList[index % colorsList.length],
                        value: widget.values[index],
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: isTouched ? 70 : 58,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 13 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
                // Center label — shows selected category or total
                _touchedIndex >= 0 && _touchedIndex < widget.labels.length
                    ? _buildCenterLabel(
                        context,
                        isDark,
                        widget.labels[_touchedIndex],
                        widget.values[_touchedIndex],
                        widget.values[_touchedIndex] / total * 100,
                        colorsList[_touchedIndex % colorsList.length],
                      )
                    : _buildCenterTotal(context, isDark, total),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        // Legend — full width below the chart, no truncation
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.labels.length,
            (index) {
              final isSelected = index == _touchedIndex;
              return GestureDetector(
                onTap: () => setState(
                  () => _touchedIndex = isSelected ? -1 : index,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  padding: isSelected
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: 4)
                      : EdgeInsets.zero,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: colorsList[index % colorsList.length]
                              .withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        )
                      : null,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 14 : 12,
                        height: isSelected ? 14 : 12,
                        decoration: BoxDecoration(
                          color: colorsList[index % colorsList.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          widget.labels[index],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ),
                      Text(
                        _formatValue(widget.values[index]),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorsList[index % colorsList.length]
                                  : (isDark
                                      ? AppColors.secondaryLabelDark
                                      : AppColors.secondaryLabel),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCenterLabel(
    BuildContext context,
    bool isDark,
    String label,
    double value,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 15,
                ),
          ),
          Text(
            _formatValue(value),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTotal(
    BuildContext context,
    bool isDark,
    double total,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatValue(total),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.labelDark : AppColors.label,
              ),
        ),
        Text(
          'total',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.secondaryLabelDark
                    : AppColors.secondaryLabel,
              ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}
