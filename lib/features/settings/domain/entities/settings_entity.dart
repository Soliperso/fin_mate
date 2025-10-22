import 'package:equatable/equatable.dart';

/// Notification preferences entity
class NotificationPreferences extends Equatable {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool soundEnabled;
  final bool budgetAlerts;
  final int budgetThreshold; // percentage
  final bool billReminders;
  final int billReminderDays;
  final bool transactionAlerts;
  final int transactionThreshold;
  final String moneyHealthUpdates; // 'weekly', 'monthly', 'off'
  final String goalNotifications; // 'milestones', 'all', 'off'

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.soundEnabled = true,
    this.budgetAlerts = true,
    this.budgetThreshold = 80,
    this.billReminders = true,
    this.billReminderDays = 1,
    this.transactionAlerts = false,
    this.transactionThreshold = 1000,
    this.moneyHealthUpdates = 'weekly',
    this.goalNotifications = 'milestones',
  });

  @override
  List<Object?> get props => [
        pushEnabled,
        emailEnabled,
        soundEnabled,
        budgetAlerts,
        budgetThreshold,
        billReminders,
        billReminderDays,
        transactionAlerts,
        transactionThreshold,
        moneyHealthUpdates,
        goalNotifications,
      ];

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? soundEnabled,
    bool? budgetAlerts,
    int? budgetThreshold,
    bool? billReminders,
    int? billReminderDays,
    bool? transactionAlerts,
    int? transactionThreshold,
    String? moneyHealthUpdates,
    String? goalNotifications,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      budgetThreshold: budgetThreshold ?? this.budgetThreshold,
      billReminders: billReminders ?? this.billReminders,
      billReminderDays: billReminderDays ?? this.billReminderDays,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      transactionThreshold: transactionThreshold ?? this.transactionThreshold,
      moneyHealthUpdates: moneyHealthUpdates ?? this.moneyHealthUpdates,
      goalNotifications: goalNotifications ?? this.goalNotifications,
    );
  }
}

/// Settings entity for user preferences
class SettingsEntity extends Equatable {
  final String userId;
  final String themeMode; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', 'fr', 'de'
  final NotificationPreferences notificationPreferences;
  final DateTime updatedAt;

  const SettingsEntity({
    required this.userId,
    this.themeMode = 'system',
    this.language = 'en',
    required this.notificationPreferences,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        themeMode,
        language,
        notificationPreferences,
        updatedAt,
      ];

  SettingsEntity copyWith({
    String? userId,
    String? themeMode,
    String? language,
    NotificationPreferences? notificationPreferences,
    DateTime? updatedAt,
  }) {
    return SettingsEntity(
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
