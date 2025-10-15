import 'package:equatable/equatable.dart';

enum AlertType {
  spendingIncrease,
  budgetOverage,
  lowBalance,
  unusualTransaction,
  subscriptionChange,
  savingsOpportunity,
  billDue,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class SpendingAlert extends Equatable {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionText;
  final Map<String, dynamic>? actionData;
  final DateTime createdAt;
  final bool isDismissed;

  const SpendingAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionText,
    this.actionData,
    required this.createdAt,
    this.isDismissed = false,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        severity,
        title,
        message,
        actionText,
        actionData,
        createdAt,
        isDismissed,
      ];

  SpendingAlert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? actionText,
    Map<String, dynamic>? actionData,
    DateTime? createdAt,
    bool? isDismissed,
  }) {
    return SpendingAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      actionText: actionText ?? this.actionText,
      actionData: actionData ?? this.actionData,
      createdAt: createdAt ?? this.createdAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'actionText': actionText,
      'actionData': actionData,
      'createdAt': createdAt.toIso8601String(),
      'isDismissed': isDismissed,
    };
  }

  factory SpendingAlert.fromJson(Map<String, dynamic> json) {
    return SpendingAlert(
      id: json['id'] as String,
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
      title: json['title'] as String,
      message: json['message'] as String,
      actionText: json['actionText'] as String?,
      actionData: json['actionData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}
