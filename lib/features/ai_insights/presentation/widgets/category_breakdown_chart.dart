import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'package:intl/intl.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;
  final double maxHeight;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryData,
    this.maxHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    final total = categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: maxHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(total),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 3,
                  child: _buildLegend(context, total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(double total) {
    final colors = [
      AppColors.primaryTeal,
      AppColors.tealDark,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.primaryTeal.withOpacity(0.6),
      AppColors.tealDark.withOpacity(0.6),
    ];

    return List.generate(categoryData.length.clamp(0, 5), (index) {
      final item = categoryData[index];
      final amount = (item['amount'] as num).toDouble();
      final percentage = (amount / total * 100);

      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(BuildContext context, double total) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final colors = [
      AppColors.primaryTeal,
      AppColors.tealDark,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.primaryTeal.withOpacity(0.6),
      AppColors.tealDark.withOpacity(0.6),
    ];

    return ListView.separated(
      shrinkWrap: true,
      itemCount: categoryData.length.clamp(0, 5),
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.xs),
      itemBuilder: (context, index) {
        final item = categoryData[index];
        final category = item['category'] as String;
        final amount = (item['amount'] as num).toDouble();
        final percentage = (amount / total * 100);

        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${currencyFormat.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
