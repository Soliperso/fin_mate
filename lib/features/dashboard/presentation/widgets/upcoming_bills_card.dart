import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class UpcomingBillsCard extends StatelessWidget {
  final List<Map<String, dynamic>> bills;

  const UpcomingBillsCard({
    super.key,
    required this.bills,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Bills',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // context.go('/recurring-transactions'); // [V1.1: Recurring Transactions disabled]
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            if (bills.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 48,
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'No upcoming bills',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length > 3 ? 3 : bills.length,
                separatorBuilder: (context, index) => Divider(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.separatorDark
                      : AppColors.separator,
                ),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final dueDate = DateTime.parse(bill['dueDate'] as String);
                  final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_text,
                        color: AppColors.warning,
                      ),
                    ),
                    title: Text(bill['name'] as String),
                    subtitle: Text(
                      daysUntilDue == 0
                          ? 'Due today'
                          : daysUntilDue == 1
                              ? 'Due tomorrow'
                              : 'Due in $daysUntilDue days',
                      style: TextStyle(
                        color: daysUntilDue <= 3 ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      currencyFormat.format(bill['amount'] as double),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
