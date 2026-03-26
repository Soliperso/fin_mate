import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';

class CategoryBreakdownChart extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> categoryData;
  final double maxHeight;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryData,
    this.maxHeight = 200,
  });

  @override
  ConsumerState<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends ConsumerState<CategoryBreakdownChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) return const SizedBox.shrink();

    final total = widget.categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final chartSize = (screenWidth * 0.6).clamp(240.0, 280.0);

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: SizedBox(
                height: chartSize,
                width: chartSize,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(total),
                    centerSpaceRadius: chartSize * 0.28, // Proportional to chart size
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = null;
                            return;
                          }
                          final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          // Validate the index is within bounds
                          if (index >= 0 && index < widget.categoryData.length) {
                            _touchedIndex = index;
                          } else {
                            _touchedIndex = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_touchedIndex != null) ...[
            const SizedBox(height: AppSizes.md),
            _buildTouchedSectionDetails(context, total, ref),
          ],
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
      AppColors.primaryTeal.withValues(alpha: 0.6),
      AppColors.tealDark.withValues(alpha: 0.6),
    ];

    return List.generate(widget.categoryData.length.clamp(0, 5), (index) {
      final item = widget.categoryData[index];
      final amount = (item['amount'] as num).toDouble();
      final percentage = (amount / total * 100);
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: isTouched ? 75 : 65,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        badgePositionPercentageOffset: 0.98,
      );
    });
  }

  Widget _buildTouchedSectionDetails(BuildContext context, double total, WidgetRef ref) {
    if (_touchedIndex == null ||
        _touchedIndex! < 0 ||
        _touchedIndex! >= widget.categoryData.length) {
      return const SizedBox.shrink();
    }

    final currencyFormat = ref.watch(currencyFormat2Provider);
    final colors = [
      AppColors.primaryTeal,
      AppColors.tealDark,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.primaryTeal.withValues(alpha: 0.6),
      AppColors.tealDark.withValues(alpha: 0.6),
    ];

    final item = widget.categoryData[_touchedIndex!];
    final category = item['category'] as String;
    final amount = (item['amount'] as num).toDouble();
    final percentage = (amount / total * 100);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colors[_touchedIndex! % colors.length].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: colors[_touchedIndex! % colors.length].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: colors[_touchedIndex! % colors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${currencyFormat.format(amount)} (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
