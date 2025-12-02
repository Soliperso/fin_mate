import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Card widget for displaying individual notifications
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          enableGlass: false,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              decoration: BoxDecoration(
                border: !notification.isRead
                    ? Border(
                        left: BorderSide(
                          color: _getPriorityColor(notification.priority),
                          width: 4,
                        ),
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type)
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: _getTypeColor(notification.type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and unread indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Message
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Time and action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(notification.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (notification.actionLabel != null)
                              Text(
                                notification.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.billReminder:
        return Icons.event_outlined;
      case NotificationType.transactionAlert:
        return Icons.receipt_long_outlined;
      case NotificationType.moneyHealthUpdate:
        return Icons.trending_up;
      case NotificationType.goalProgress:
        return Icons.savings_outlined;
      case NotificationType.systemMessage:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return AppColors.warning;
      case NotificationType.billReminder:
        return AppColors.primaryTeal;
      case NotificationType.transactionAlert:
        return AppColors.error;
      case NotificationType.moneyHealthUpdate:
        return AppColors.success;
      case NotificationType.goalProgress:
        return AppColors.primaryTeal;
      case NotificationType.systemMessage:
        return AppColors.textSecondary;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return AppColors.error;
      case NotificationPriority.high:
        return AppColors.warning;
      case NotificationPriority.medium:
        return AppColors.primaryTeal;
      case NotificationPriority.low:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
