import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

enum NotificationType {
  budgetAlert('budget_alert'),
  billReminder('bill_reminder'),
  transactionAlert('transaction_alert'),
  moneyHealthUpdate('money_health_update'),
  goalProgress('goal_progress'),
  systemMessage('system_message');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemMessage,
    );
  }
}

enum NotificationPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  final String value;
  const NotificationPriority(this.value);

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? actionUrl;
  final String? actionLabel;
  final bool isRead;
  final bool isArchived;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.actionUrl,
    this.actionLabel,
    required this.isRead,
    required this.isArchived,
    this.metadata,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      priority: NotificationPriority.fromString(json['priority'] as String? ?? 'medium'),
      title: json['title'] as String,
      message: json['message'] as String,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      archivedAt: json['archived_at'] != null ? DateTime.parse(json['archived_at'] as String) : null,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    String? actionUrl,
    String? actionLabel,
    bool? isRead,
    bool? isArchived,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? archivedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get all notifications for the current user
  Future<List<AppNotification>> getNotifications({
    bool? isRead,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('notifications').select();

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final result = await _supabase.rpc('get_unread_notification_count');
      return result as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final result = await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final result = await _supabase.rpc('mark_all_notifications_read');
      return result as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Archive a notification
  Future<bool> archiveNotification(String notificationId) async {
    try {
      final result = await _supabase.rpc('archive_notification', params: {
        'p_notification_id': notificationId,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a notification (for testing or system use)
  Future<String?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _supabase.rpc('create_notification', params: {
        'p_user_id': userId,
        'p_type': type.value,
        'p_title': title,
        'p_message': message,
        'p_priority': priority.value,
        'p_action_url': actionUrl,
        'p_action_label': actionLabel,
        'p_metadata': metadata,
      });
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check budgets and create alerts
  Future<int> checkBudgetAlerts() async {
    try {
      final result = await _supabase.rpc('check_budget_alerts');
      return result as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Create bill reminder notifications
  Future<int> createBillReminders() async {
    try {
      final result = await _supabase.rpc('create_bill_reminders');
      return result as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications({
    required void Function(AppNotification) onNotification,
  }) {
    final channel = _supabase
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _supabase.auth.currentUser?.id,
          ),
          callback: (payload) {
            final notification = AppNotification.fromJson(payload.newRecord);
            onNotification(notification);
          },
        )
        .subscribe();

    return channel;
  }
}
