import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final insights = [
      {
        'title': 'Spending Alert',
        'description': 'You\'ve spent 20% more on dining out this month compared to last month.',
        'type': 'warning',
        'icon': Icons.trending_up,
      },
      {
        'title': 'Great Job!',
        'description': 'You\'re on track to save \$500 this month. Keep it up!',
        'type': 'success',
        'icon': Icons.celebration,
      },
      {
        'title': 'Bill Reminder',
        'description': 'Your electric bill is typically higher in winter. Consider budgeting an extra \$50.',
        'type': 'info',
        'icon': Icons.lightbulb,
      },
    ];

    final categories = [
      {'name': 'Food & Dining', 'amount': 450.0, 'percentage': 28.0},
      {'name': 'Transportation', 'amount': 280.0, 'percentage': 18.0},
      {'name': 'Shopping', 'amount': 320.0, 'percentage': 20.0},
      {'name': 'Bills & Utilities', 'amount': 550.0, 'percentage': 34.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh insights
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insights Section
            Text(
              'Personalized Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            ...insights.map((insight) => _buildInsightCard(context, insight)),
            const SizedBox(height: AppSizes.lg),

            // Spending Breakdown
            Text(
              'Spending Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    // Pie chart placeholder
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          'Spending Chart\n(To be implemented)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category['name'] as String),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                category['name'] as String,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${category['percentage']}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              '\$${(category['amount'] as double).toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Weekly Digest
            Text(
              'Weekly Digest',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.emeraldGreen),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'This Week\'s Summary',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildDigestItem(context, 'Total Spent', '\$387.50'),
                    _buildDigestItem(context, 'Top Category', 'Food & Dining'),
                    _buildDigestItem(context, 'Transactions', '23'),
                    _buildDigestItem(context, 'Avg per Day', '\$55.36'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight) {
    Color color;
    Color bgColor;

    switch (insight['type']) {
      case 'warning':
        color = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case 'success':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case 'info':
      default:
        color = AppColors.info;
        bgColor = AppColors.info.withValues(alpha: 0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                insight['icon'] as IconData,
                color: color,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    insight['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigestItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
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
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return AppColors.emeraldGreen;
      case 'Transportation':
        return AppColors.tealBlue;
      case 'Shopping':
        return AppColors.royalPurple;
      case 'Bills & Utilities':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }
}
