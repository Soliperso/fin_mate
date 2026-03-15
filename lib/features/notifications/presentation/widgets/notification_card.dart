import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
          CupertinoIcons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          enableGlass: false,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              ),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: AppSizes.iconContainer,
                    height: AppSizes.iconContainer,
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type)
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: _getTypeColor(notification.type),
                      size: AppSizes.iconSm,
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.brandTeal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Message
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            if (notification.actionLabel != null)
                              Text(
                                notification.actionLabel!,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppColors.brandTeal,
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
        return CupertinoIcons.chart_pie;
      case NotificationType.billReminder:
        return CupertinoIcons.calendar;
      case NotificationType.transactionAlert:
        return CupertinoIcons.doc_text;
      case NotificationType.moneyHealthUpdate:
        return CupertinoIcons.arrow_up_right;
      case NotificationType.goalProgress:
        return CupertinoIcons.money_dollar_circle;
      case NotificationType.systemMessage:
        return CupertinoIcons.info_circle;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return AppColors.warning;
      case NotificationType.billReminder:
        return AppColors.brandTeal;
      case NotificationType.transactionAlert:
        return AppColors.error;
      case NotificationType.moneyHealthUpdate:
        return AppColors.success;
      case NotificationType.goalProgress:
        return AppColors.brandTeal;
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
        return AppColors.brandTeal;
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
