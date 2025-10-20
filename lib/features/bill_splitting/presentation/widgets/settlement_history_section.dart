import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/settlement_entity.dart';

class SettlementHistorySection extends ConsumerWidget {
  final String groupId;
  final List<Settlement> settlements;
  final String currentUserId;

  const SettlementHistorySection({
    super.key,
    required this.groupId,
    required this.settlements,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (settlements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () => _showFullHistory(context, settlements),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Show last 3 settlements
          ...settlements.take(3).map((settlement) {
            return _buildSettlementItem(context, settlement);
          }),
        ],
      ),
    );
  }

  Widget _buildSettlementItem(BuildContext context, Settlement settlement) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final isCurrentUserPayer = settlement.fromUser == currentUserId;
    final isCurrentUserReceiver = settlement.toUser == currentUserId;

    String description;
    Color indicatorColor;
    IconData icon;

    if (isCurrentUserPayer) {
      description = 'You paid ${settlement.toUserName}';
      indicatorColor = AppColors.error;
      icon = Icons.arrow_upward;
    } else if (isCurrentUserReceiver) {
      description = '${settlement.fromUserName} paid you';
      indicatorColor = AppColors.success;
      icon = Icons.arrow_downward;
    } else {
      description = '${settlement.fromUserName} paid ${settlement.toUserName}';
      indicatorColor = AppColors.textSecondary;
      icon = Icons.swap_horiz;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: indicatorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            color: indicatorColor,
            size: 20,
          ),
        ),
        title: Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(settlement.settledAt)} at ${timeFormat.format(settlement.settledAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                settlement.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          currencyFormat.format(settlement.amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: indicatorColor,
              ),
        ),
        onTap: () => _showSettlementDetails(context, settlement),
      ),
    );
  }

  void _showFullHistory(BuildContext context, List<Settlement> settlements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Settlements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSizes.sm),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: settlements.length,
                    itemBuilder: (context, index) {
                      return _buildSettlementItem(context, settlements[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettlementDetails(BuildContext context, Settlement settlement) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateTimeFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: AppColors.primaryTeal),
            SizedBox(width: AppSizes.sm),
            Text('Settlement Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                'From',
                settlement.fromUserName ?? 'Unknown',
                Icons.person,
              ),
              const SizedBox(height: AppSizes.md),
              _buildDetailRow(
                context,
                'To',
                settlement.toUserName ?? 'Unknown',
                Icons.person_outline,
              ),
              const SizedBox(height: AppSizes.md),
              _buildDetailRow(
                context,
                'Amount',
                currencyFormat.format(settlement.amount),
                Icons.attach_money,
              ),
              const SizedBox(height: AppSizes.md),
              _buildDetailRow(
                context,
                'Date',
                dateTimeFormat.format(settlement.settledAt),
                Icons.calendar_today,
              ),
              if (settlement.notes != null && settlement.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                _buildDetailRow(
                  context,
                  'Notes',
                  settlement.notes!,
                  Icons.note,
                ),
              ],
              if (settlement.evidenceUrl != null && settlement.evidenceUrl!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                _buildDetailRow(
                  context,
                  'Evidence',
                  'View Receipt',
                  Icons.receipt_long,
                  onTap: () {
                    // TODO: Open evidence URL
                    ErrorSnackbar.show(context, message: 'Receipt viewing coming soon');
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryTeal),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onTap != null ? AppColors.primaryTeal : null,
                        ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.open_in_new, size: 16, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }
}
