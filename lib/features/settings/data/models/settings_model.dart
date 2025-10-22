import '../../domain/entities/settings_entity.dart';

/// Model for notification preferences
class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    super.pushEnabled = true,
    super.emailEnabled = false,
    super.soundEnabled = true,
    super.budgetAlerts = true,
    super.budgetThreshold = 80,
    super.billReminders = true,
    super.billReminderDays = 1,
    super.transactionAlerts = false,
    super.transactionThreshold = 1000,
    super.moneyHealthUpdates = 'weekly',
    super.goalNotifications = 'milestones',
  });

  /// Create from JSON
  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      budgetAlerts: json['budget_alerts'] as bool? ?? true,
      budgetThreshold: json['budget_threshold'] as int? ?? 80,
      billReminders: json['bill_reminders'] as bool? ?? true,
      billReminderDays: json['bill_reminder_days'] as int? ?? 1,
      transactionAlerts: json['transaction_alerts'] as bool? ?? false,
      transactionThreshold: json['transaction_threshold'] as int? ?? 1000,
      moneyHealthUpdates: json['money_health_updates'] as String? ?? 'weekly',
      goalNotifications: json['goal_notifications'] as String? ?? 'milestones',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sound_enabled': soundEnabled,
      'budget_alerts': budgetAlerts,
      'budget_threshold': budgetThreshold,
      'bill_reminders': billReminders,
      'bill_reminder_days': billReminderDays,
      'transaction_alerts': transactionAlerts,
      'transaction_threshold': transactionThreshold,
      'money_health_updates': moneyHealthUpdates,
      'goal_notifications': goalNotifications,
    };
  }

  /// Convert to entity
  NotificationPreferences toEntity() {
    return NotificationPreferences(
      pushEnabled: pushEnabled,
      emailEnabled: emailEnabled,
      soundEnabled: soundEnabled,
      budgetAlerts: budgetAlerts,
      budgetThreshold: budgetThreshold,
      billReminders: billReminders,
      billReminderDays: billReminderDays,
      transactionAlerts: transactionAlerts,
      transactionThreshold: transactionThreshold,
      moneyHealthUpdates: moneyHealthUpdates,
      goalNotifications: goalNotifications,
    );
  }
}

/// Settings model for data layer
class SettingsModel extends SettingsEntity {
  const SettingsModel({
    required super.userId,
    super.themeMode = 'system',
    super.language = 'en',
    required super.notificationPreferences,
    required super.updatedAt,
  });

  /// Create from JSON (from database)
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      userId: json['id'] as String,
      themeMode: (json['theme_mode'] as String?) ?? 'system',
      language: (json['language'] as String?) ?? 'en',
      notificationPreferences: NotificationPreferencesModel.fromJson(
        (json['notification_preferences'] as Map<String, dynamic>?) ?? {},
      ),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'theme_mode': themeMode,
      'language': language,
      'notification_preferences': (notificationPreferences as NotificationPreferencesModel).toJson(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      userId: userId,
      themeMode: themeMode,
      language: language,
      notificationPreferences: notificationPreferences,
      updatedAt: updatedAt,
    );
  }

  /// Create from entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      userId: entity.userId,
      themeMode: entity.themeMode,
      language: entity.language,
      notificationPreferences: entity.notificationPreferences as NotificationPreferencesModel,
      updatedAt: entity.updatedAt,
    );
  }
}
