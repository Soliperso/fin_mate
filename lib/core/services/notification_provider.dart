import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// State for notifications list
class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier for managing notifications
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _service;
  RealtimeChannel? _realtimeChannel;

  NotificationsNotifier(this._service) : super(const NotificationsState()) {
    _init();
  }

  Future<void> _init() async {
    await loadNotifications();
    await updateUnreadCount();
    _subscribeToRealtimeUpdates();
  }

  /// Load notifications
  Future<void> loadNotifications({
    bool? isRead,
    bool includeArchived = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _service.getNotifications(
        isRead: isRead,
        includeArchived: includeArchived,
      );

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update unread count
  Future<void> updateUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail - don't update state
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _service.markAsRead(notificationId);
      if (success) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final count = await _service.markAllAsRead();
      if (count > 0) {
        await loadNotifications();
        state = state.copyWith(unreadCount: 0);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      final success = await _service.archiveNotification(notificationId);
      if (success) {
        // Remove from local state
        final updatedNotifications = state.notifications
            .where((n) => n.id != notificationId)
            .toList();

        state = state.copyWith(notifications: updatedNotifications);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final success = await _service.deleteNotification(notificationId);
      if (success) {
        // Remove from local state
        final updatedNotifications = state.notifications
            .where((n) => n.id != notificationId)
            .toList();

        // Update unread count if the deleted notification was unread
        final wasUnread = state.notifications
            .firstWhere((n) => n.id == notificationId)
            .isRead == false;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: wasUnread && state.unreadCount > 0
              ? state.unreadCount - 1
              : state.unreadCount,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for budget alerts
  Future<void> checkBudgetAlerts() async {
    try {
      await _service.checkBudgetAlerts();
      await loadNotifications();
      await updateUnreadCount();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Create bill reminders
  Future<void> createBillReminders() async {
    try {
      await _service.createBillReminders();
      await loadNotifications();
      await updateUnreadCount();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Subscribe to real-time notification updates
  void _subscribeToRealtimeUpdates() {
    _realtimeChannel = _service.subscribeToNotifications(
      onNotification: (notification) {
        // Add new notification to the list
        final updatedNotifications = [notification, ...state.notifications];
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount + 1,
        );
      },
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

/// Provider for notifications state
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationsNotifier(service);
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

/// Provider for checking if there are unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationCountProvider) > 0;
});
