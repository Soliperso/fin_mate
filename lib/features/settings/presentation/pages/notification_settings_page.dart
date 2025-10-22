import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_providers.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsOperationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (settings) {
          final prefs = settings?.notificationPreferences;
          if (prefs == null) {
            return const Center(child: Text('No settings found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Notifications
                _buildSectionTitle(context, 'General Notifications'),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: prefs.pushEnabled,
                  onChanged: (value) {
                    _updatePreferences(ref, prefs.copyWith(pushEnabled: value));
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Email Notifications',
                  subtitle: 'Receive important updates via email',
                  value: prefs.emailEnabled,
                  onChanged: (value) {
                    _updatePreferences(ref, prefs.copyWith(emailEnabled: value));
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: prefs.soundEnabled,
                  onChanged: (value) {
                    _updatePreferences(ref, prefs.copyWith(soundEnabled: value));
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Budget Alerts
                _buildSectionTitle(context, 'Budget Alerts'),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Budget Alerts',
                  subtitle: 'Get notified when nearing budget limit',
                  value: prefs.budgetAlerts,
                  onChanged: (value) {
                    _updatePreferences(ref, prefs.copyWith(budgetAlerts: value));
                  },
                ),
                if (prefs.budgetAlerts) ...[
                  const SizedBox(height: AppSizes.sm),
                  _buildSliderTile(
                    context,
                    title: 'Budget Threshold',
                    subtitle: 'Alert when budget is ${prefs.budgetThreshold}% spent',
                    value: prefs.budgetThreshold.toDouble(),
                    onChanged: (value) {
                      _updatePreferences(
                        ref,
                        prefs.copyWith(budgetThreshold: value.toInt()),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // Bill Reminders
                _buildSectionTitle(context, 'Bill Reminders'),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Bill Reminders',
                  subtitle: 'Get reminded about upcoming bills',
                  value: prefs.billReminders,
                  onChanged: (value) {
                    _updatePreferences(ref, prefs.copyWith(billReminders: value));
                  },
                ),
                if (prefs.billReminders) ...[
                  const SizedBox(height: AppSizes.sm),
                  _buildSliderTile(
                    context,
                    title: 'Reminder Days Before',
                    subtitle: 'Remind me ${prefs.billReminderDays} day(s) before bill due',
                    value: prefs.billReminderDays.toDouble(),
                    onChanged: (value) {
                      _updatePreferences(
                        ref,
                        prefs.copyWith(billReminderDays: value.toInt()),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // Transaction Alerts
                _buildSectionTitle(context, 'Transaction Alerts'),
                const SizedBox(height: AppSizes.sm),
                _buildSwitchTile(
                  context,
                  title: 'Large Transaction Alerts',
                  subtitle: 'Get notified for large expenses',
                  value: prefs.transactionAlerts,
                  onChanged: (value) {
                    _updatePreferences(
                      ref,
                      prefs.copyWith(transactionAlerts: value),
                    );
                  },
                ),
                if (prefs.transactionAlerts) ...[
                  const SizedBox(height: AppSizes.sm),
                  _buildSliderTile(
                    context,
                    title: 'Amount Threshold',
                    subtitle: 'Alert for transactions over \$${prefs.transactionThreshold}',
                    value: prefs.transactionThreshold.toDouble(),
                    onChanged: (value) {
                      _updatePreferences(
                        ref,
                        prefs.copyWith(transactionThreshold: value.toInt()),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // Money Health & Goals
                _buildSectionTitle(context, 'Money Health & Goals'),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownTile(
                  context,
                  title: 'Money Health Updates',
                  subtitle: 'How often to receive money health insights',
                  value: prefs.moneyHealthUpdates,
                  items: const ['weekly', 'monthly', 'off'],
                  labels: const ['Weekly', 'Monthly', 'Off'],
                  onChanged: (value) {
                    if (value != null) {
                      _updatePreferences(
                        ref,
                        prefs.copyWith(moneyHealthUpdates: value),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _buildDropdownTile(
                  context,
                  title: 'Goal Notifications',
                  subtitle: 'When to be notified about goals',
                  value: prefs.goalNotifications,
                  items: const ['milestones', 'all', 'off'],
                  labels: const ['Milestones Only', 'All Updates', 'Off'],
                  onChanged: (value) {
                    if (value != null) {
                      _updatePreferences(
                        ref,
                        prefs.copyWith(goalNotifications: value),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Slider(
            value: value,
            onChanged: onChanged,
            min: title.contains('Budget') || title.contains('Health')
                ? 10
                : title.contains('Reminder')
                    ? 1
                    : 100,
            max: title.contains('Budget') || title.contains('Health')
                ? 100
                : title.contains('Reminder')
                    ? 7
                    : 10000,
            divisions: title.contains('Budget') || title.contains('Health')
                ? 9
                : title.contains('Reminder')
                    ? 6
                    : 99,
            label: title.contains('Budget') || title.contains('Health')
                ? '${value.toInt()}%'
                : title.contains('Reminder')
                    ? '${value.toInt()} days'
                    : '\$${value.toInt()}',
            activeColor: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required List<String> labels,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: List.generate(
              items.length,
              (index) => DropdownMenuItem(
                value: items[index],
                child: Text(labels[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePreferences(WidgetRef ref, NotificationPreferences newPrefs) {
    ref.read(settingsOperationsProvider.notifier).updateNotificationPreferences(
          newPrefs,
        );
  }
}
