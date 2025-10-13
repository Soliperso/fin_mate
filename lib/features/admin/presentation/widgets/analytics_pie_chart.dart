import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsPieChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (labels.isEmpty || values.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final colorsList = colors ??
        [
          AppColors.primaryTeal,
          AppColors.tealBlue,
          AppColors.slateBlue,
          AppColors.warning,
          AppColors.error,
          AppColors.info,
        ];

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
        Row(
          children: [
            // Pie Chart
            SizedBox(
              height: 200,
              width: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(
                    values.length,
                    (index) {
                      final percentage = (values[index] / values.reduce((a, b) => a + b) * 100);
                      return PieChartSectionData(
                        color: colorsList[index % colorsList.length],
                        value: values[index],
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  labels.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorsList[index % colorsList.length],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatValue(values[index]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
