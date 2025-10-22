import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/emergency_fund_status.dart';
import '../../data/services/emergency_fund_service.dart';
import '../providers/emergency_fund_provider.dart';

class EmergencyFundCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            _showEmergencyFundDetails(context, ref);
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
                      context.pushNamed('emergency-fund');
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

  void _showEmergencyFundDetails(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draggable Handle
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    _showSetTargetDialog(context, ref, currencyFormat);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Set target amount',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),

            // Circular Progress Indicator
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.lightGray,
                              width: 8,
                            ),
                          ),
                        ),
                        // Progress circle
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: (status.readinessScore / 100).clamp(0, 1),
                            strokeWidth: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                            backgroundColor: AppColors.lightGray,
                          ),
                        ),
                        // Center text
                        Text(
                          '${status.readinessScore.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    '${status.monthsCovered.toStringAsFixed(1)} months covered',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Your Fund Status Section
            Text(
              'YOUR FUND STATUS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            // Fund Status Card
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Current Emergency Fund
                  _buildMetricRowWithIcon(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Current Emergency Fund',
                    currencyFormat.format(status.currentAmount),
                    _getLevelColor(),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Your Target
                  _buildMetricRowWithIcon(
                    context,
                    Icons.flag_outlined,
                    'Your Target',
                    currencyFormat.format(status.targetRecommended),
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Progress Bar
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child: LinearProgressIndicator(
                      value: (status.readinessScore / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${status.readinessScore.toStringAsFixed(0)}% Ready',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getLevelColor(),
                            ),
                      ),
                      Text(
                        '${status.monthsCovered.toStringAsFixed(1)} months',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Breakdown Section
            Text(
              'BREAKDOWN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            // Breakdown Metrics
            _buildMetricRowWithIcon(
              context,
              Icons.calendar_today_outlined,
              'Months Covered',
              '${status.monthsCovered.toStringAsFixed(1)} months',
              _getLevelColor(),
            ),
            const SizedBox(height: AppSizes.md),

            _buildMetricRowWithIcon(
              context,
              Icons.receipt_long_outlined,
              'Monthly Expenses (avg)',
              currencyFormat.format(status.averageMonthlyExpenses),
              AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.md),

            _buildMetricRowWithIcon(
              context,
              Icons.check_circle_outline,
              'Minimum Goal (3 months)',
              currencyFormat.format(status.minimumRecommended),
              AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.xl),

            // Recommendations
            Text(
              'RECOMMENDATIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
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
      ),
    );
  }

  void _showSetTargetDialog(BuildContext context, WidgetRef ref, NumberFormat currencyFormat) {
    final targetController = TextEditingController(
      text: status.targetRecommended.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Emergency Fund Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your desired emergency fund target amount.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Recommended: 3-6 months of expenses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = double.tryParse(targetController.text);
              if (target != null && target > 0) {
                try {
                  final userId = supabase.auth.currentUser?.id;
                  if (userId != null) {
                    final service = EmergencyFundService(supabase);
                    await service.saveEmergencyFundTarget(userId, target);

                    // Refresh the emergency fund status
                    ref.invalidate(emergencyFundStatusProvider);

                    if (context.mounted) {
                      Navigator.pop(context);
                      SuccessSnackbar.show(
                        context,
                        message: 'Emergency fund target updated!',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ErrorSnackbar.show(
                      context,
                      message: 'Failed to save target. Please try again.',
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ErrorSnackbar.show(
                    context,
                    message: 'Please enter a valid amount.',
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRowWithIcon(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
