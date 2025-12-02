import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../widgets/notification_card.dart';

/// Page for displaying all notifications
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifications = notificationsState.notifications;
    final isLoading = notificationsState.isLoading;

    // Separate unread and read notifications
    final unreadNotifications =
        notifications.where((n) => !n.isRead).toList();
    final readNotifications = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ref
                    .read(notificationsProvider.notifier)
                    .markAllAsRead();
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).loadNotifications();
        },
        child: isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: const [
                      SizedBox(height: 100),
                      EmptyStateCard(
                        icon: Icons.notifications_none_outlined,
                        title: 'No notifications',
                        message:
                            'You\'re all caught up! Notifications about budgets, bills, and financial insights will appear here.',
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: [
                      // Unread section
                      if (unreadNotifications.isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizes.md),
                          child: Row(
                            children: [
                              const Text(
                                'Unread',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal
                                      .withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                child: Text(
                                  '${unreadNotifications.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...unreadNotifications.map(
                          (notification) => NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () => _handleNotificationDismiss(
                                notification.id),
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // Read section
                      if (readNotifications.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSizes.md),
                          child: Text(
                            'Earlier',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...readNotifications.map(
                          (notification) => NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () => _handleNotificationDismiss(
                                notification.id),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark as read if unread
    if (!notification.isRead) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate to action URL if exists
    if (notification.actionUrl != null && mounted) {
      context.push(notification.actionUrl!);
    }
  }

  Future<void> _handleNotificationDismiss(String notificationId) async {
    await ref
        .read(notificationsProvider.notifier)
        .deleteNotification(notificationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
