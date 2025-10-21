import 'package:equatable/equatable.dart';

enum AlertType {
  cashFlowWarning, // Balance will drop below safe level
  billCollision, // Multiple bills due on same day
  lowBalance, // Balance critically low
  unusualSpending, // Spending spike detected
  unknown;

  String get displayName {
    switch (this) {
      case AlertType.cashFlowWarning:
        return 'Cash Flow Warning';
      case AlertType.billCollision:
        return 'Bill Collision';
      case AlertType.lowBalance:
        return 'Low Balance Alert';
      case AlertType.unusualSpending:
        return 'Unusual Spending';
      case AlertType.unknown:
        return 'Alert';
    }
  }

  String get emoji {
    switch (this) {
      case AlertType.cashFlowWarning:
        return '⚠️';
      case AlertType.billCollision:
        return '🚨';
      case AlertType.lowBalance:
        return '🔴';
      case AlertType.unusualSpending:
        return '📊';
      case AlertType.unknown:
        return 'ℹ️';
    }
  }
}

enum AlertSeverity {
  low, // Informational
  medium, // Should review
  high, // Action recommended
  critical; // Immediate action needed

  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}

/// Base class for all proactive alerts
class ProactiveAlert extends Equatable {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? dismissedAt;
  final Map<String, dynamic>? actionData; // For quick actions
  final bool isRead;

  const ProactiveAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.dismissedAt,
    this.actionData,
    this.isRead = false,
  });

  bool get isDismissed => dismissedAt != null;
  bool get isActive => !isDismissed && createdAt.add(const Duration(days: 7)).isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        type,
        severity,
        title,
        message,
        createdAt,
        dismissedAt,
        actionData,
        isRead,
      ];

  ProactiveAlert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? dismissedAt,
    Map<String, dynamic>? actionData,
    bool? isRead,
  }) {
    return ProactiveAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      actionData: actionData ?? this.actionData,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'dismissed_at': dismissedAt?.toIso8601String(),
      'action_data': actionData,
      'is_read': isRead,
    };
  }

  factory ProactiveAlert.fromJson(Map<String, dynamic> json) {
    return ProactiveAlert(
      id: json['id'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.unknown,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      dismissedAt: json['dismissed_at'] != null ? DateTime.parse(json['dismissed_at'] as String) : null,
      actionData: json['action_data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
