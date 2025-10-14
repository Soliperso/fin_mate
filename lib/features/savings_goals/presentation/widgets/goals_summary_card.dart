import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'package:intl/intl.dart';

class GoalsSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const GoalsSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalGoals = summary['total_goals'] as int? ?? 0;
    final completedGoals = summary['completed_goals'] as int? ?? 0;
    final totalTarget = (summary['total_target'] as num?)?.toDouble() ?? 0.0;
    final totalSaved = (summary['total_saved'] as num?)?.toDouble() ?? 0.0;
    final overallProgress = (summary['overall_progress'] as num?)?.toDouble() ?? 0.0;

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    'Total Goals',
                    totalGoals.toString(),
                    Icons.flag,
                    AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _buildStat(
                    context,
                    'Completed',
                    completedGoals.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Saved',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      currencyFormat.format(totalSaved),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Target',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      currencyFormat.format(totalTarget),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                LinearProgressIndicator(
                  value: overallProgress / 100,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overallProgress >= 100 ? AppColors.success : AppColors.primaryTeal,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${overallProgress.toStringAsFixed(1)}% of total target',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
