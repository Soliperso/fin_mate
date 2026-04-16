import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../widgets/notification_card.dart';

/// Page for displaying all notifications
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  /// Groups notifications into Today / Yesterday / Earlier buckets.
  String _translateGroup(String key) {
    switch (key) {
      case 'Today': return 'common.today'.tr();
      case 'Yesterday': return 'common.yesterday'.tr();
      default: return 'common.earlier'.tr();
    }
  }

  Map<String, List<AppNotification>> _groupByDate(
      List<AppNotification> notifications) {
    final groups = <String, List<AppNotification>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in notifications) {
      final date =
          DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else {
        key = 'Earlier';
      }
      groups.putIfAbsent(key, () => []).add(n);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifications = notificationsState.notifications;
    final isLoading = notificationsState.isLoading;
    final unreadCount =
        notifications.where((n) => !n.isRead).length;

    final grouped = _groupByDate(notifications);
    // Preserve display order
    final groupOrder = ['Today', 'Yesterday', 'Earlier'];
    final presentGroups =
        groupOrder.where((k) => grouped.containsKey(k)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('notifPage.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                await ref
                    .read(notificationsProvider.notifier)
                    .markAllAsRead();
              },
              child: Text(
                'notifPage.markAllRead'.tr(),
                style: const TextStyle(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w400,
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
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pagePadding),
                child: SkeletonList(itemCount: 6, itemHeight: 72),
              )
            : notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: [
                      const SizedBox(height: 100),
                      EmptyStateCard(
                        icon: CupertinoIcons.bell,
                        title: 'notifPage.emptyTitle'.tr(),
                        message: 'notifPage.emptyMessage'.tr(),
                        backgroundColor: AppColors.brandTeal,
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: [
                      for (final group in presentGroups) ...[
                        _buildGroupHeader(context, group, grouped[group] ?? []),
                        ...(grouped[group] ?? []).map(
                          (notification) => NotificationCard(
                            notification: notification,
                            onTap: () =>
                                _handleNotificationTap(notification),
                            onDismiss: () =>
                                _handleNotificationDismiss(notification.id),
                            onMarkAsRead: () =>
                                _handleMarkAsRead(notification.id),
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    String label,
    List<AppNotification> groupNotifications,
  ) {
    final unread = groupNotifications.where((n) => !n.isRead).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        children: [
          Text(_translateGroup(label), style: Theme.of(context).textTheme.titleLarge),
          if (unread > 0) ...[
            const SizedBox(width: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandTeal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(notification.id);
    }
    final actionUrl = notification.actionUrl;
    if (actionUrl != null && mounted) {
      context.push(actionUrl);
    }
  }

  Future<void> _handleMarkAsRead(String notificationId) async {
    await ref
        .read(notificationsProvider.notifier)
        .markAsRead(notificationId);
  }

  Future<void> _handleNotificationDismiss(String notificationId) async {
    await ref
        .read(notificationsProvider.notifier)
        .deleteNotification(notificationId);
  }
}
