import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/emergency_fund_status.dart';

class EmergencyFundCard extends StatelessWidget {
  final EmergencyFundStatus status;

  const EmergencyFundCard({
    super.key,
    required this.status,
  });

  Color _getLevelColor() {
    switch (status.level) {
      case EmergencyFundLevel.critical:
        return AppColors.error;
      case EmergencyFundLevel.low:
        return AppColors.warning;
      case EmergencyFundLevel.moderate:
        return AppColors.tealLight;
      case EmergencyFundLevel.good:
        return AppColors.success;
      case EmergencyFundLevel.excellent:
        return AppColors.primaryTeal;
    }
  }

  IconData _getLevelIcon() {
    switch (status.level) {
      case EmergencyFundLevel.critical:
        return Icons.warning_amber_rounded;
      case EmergencyFundLevel.low:
        return Icons.trending_up;
      case EmergencyFundLevel.moderate:
        return Icons.shield_outlined;
      case EmergencyFundLevel.good:
        return Icons.shield;
      case EmergencyFundLevel.excellent:
        return Icons.verified_user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final levelColor = _getLevelColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              levelColor.withValues(alpha: 0.05),
              levelColor.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            _showEmergencyFundDetails(context);
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        _getLevelIcon(),
                        color: levelColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Fund',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.statusMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // Amount Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(status.currentAmount),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: levelColor,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Target (6 months)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(status.targetRecommended),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${status.readinessScore.toStringAsFixed(0)}% Ready',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: levelColor,
                              ),
                        ),
                        Text(
                          '${status.monthsCovered.toStringAsFixed(1)} months covered',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: LinearProgressIndicator(
                        value: (status.readinessScore / 100).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: AppColors.lightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // Primary Recommendation
                if (status.recommendations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: AppColors.tealLight.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.tealLight,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            status.recommendations.first,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.deepNavy,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.md),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/goals');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add to Emergency Fund'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: levelColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmergencyFundDetails(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: _getLevelColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    Icons.shield,
                    color: _getLevelColor(),
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Fund Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        status.statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),

            // Breakdown
            _buildDetailRow(
              context,
              'Current Emergency Fund',
              currencyFormat.format(status.currentAmount),
              _getLevelColor(),
            ),
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              'Minimum Goal (3 months)',
              currencyFormat.format(status.minimumRecommended),
              AppColors.textSecondary,
            ),
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              'Target Goal (6 months)',
              currencyFormat.format(status.targetRecommended),
              AppColors.textSecondary,
            ),
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              'Monthly Expenses (avg)',
              currencyFormat.format(status.averageMonthlyExpenses),
              AppColors.textSecondary,
            ),
            const Divider(height: AppSizes.lg),
            _buildDetailRow(
              context,
              'Months Covered',
              '${status.monthsCovered.toStringAsFixed(1)} months',
              _getLevelColor(),
            ),
            const SizedBox(height: AppSizes.xl),

            // Recommendations
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            ...status.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _getLevelColor(),
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        rec,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getLevelColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                child: const Text('Got it'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
