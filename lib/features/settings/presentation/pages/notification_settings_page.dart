import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_providers.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  // Local slider values so the slider and subtitle update smoothly while
  // dragging, without firing a DB write on every position.
  double? _budgetThreshold;
  double? _billReminderDays;
  double? _transactionThreshold;

  Future<void> _updatePreferences(NotificationPreferences newPrefs) async {
    final success = await ref
        .read(settingsOperationsProvider.notifier)
        .updateNotificationPreferences(newPrefs);

    if (!mounted) return;
    if (success) {
      SuccessSnackbar.show(context, message: 'notificationSettings.saved'.tr());
    } else {
      ErrorSnackbar.show(context, message: 'notificationSettings.failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsOperationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('notificationSettings.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.md),
              Text('settings.failedToLoad'.tr()),
              const SizedBox(height: AppSizes.md),
              FilledButton(
                onPressed: () => ref.invalidate(settingsOperationsProvider),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (settings) {
          final prefs = settings?.notificationPreferences;
          if (prefs == null) {
            return Center(child: Text('common.noData'.tr()));
          }

          // Initialise local slider values on first build
          _budgetThreshold ??= prefs.budgetThreshold.toDouble();
          _billReminderDays ??= prefs.billReminderDays.toDouble();
          _transactionThreshold ??= prefs.transactionThreshold.toDouble();

          final pushOn = prefs.pushEnabled;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── General ───────────────────────────────────────────────
                _sectionTitle(context, 'notificationSettings.title'.tr()),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.pushNotifications'.tr(),
                  subtitle: 'notificationSettings.pushSub'.tr(),
                  value: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(pushEnabled: v)),
                ),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.emailNotifications'.tr(),
                  subtitle: 'notificationSettings.emailSub'.tr(),
                  value: prefs.emailEnabled,
                  enabled: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(emailEnabled: v)),
                ),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.sound'.tr(),
                  subtitle: 'notificationSettings.soundSub'.tr(),
                  value: prefs.soundEnabled,
                  enabled: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(soundEnabled: v)),
                ),
                const SizedBox(height: AppSizes.lg),

                // ── Budget Alerts ─────────────────────────────────────────
                _sectionTitle(
                    context, 'notificationSettings.budgetAlerts'.tr()),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.budgetAlerts'.tr(),
                  subtitle: 'notificationSettings.budgetAlertsSub'.tr(
                    namedArgs: {'threshold': prefs.budgetThreshold.toString()},
                  ),
                  value: prefs.budgetAlerts,
                  enabled: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(budgetAlerts: v)),
                ),
                if (prefs.budgetAlerts && pushOn) ...[
                  const SizedBox(height: AppSizes.sm),
                  _sliderTile(
                    context,
                    title: 'notificationSettings.budgetAlerts'.tr(),
                    subtitle: 'notificationSettings.budgetAlertsSub'.tr(
                      namedArgs: {
                        'threshold': _budgetThreshold!.toInt().toString()
                      },
                    ),
                    value: _budgetThreshold!,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '${_budgetThreshold!.toInt()}%',
                    onChanged: (v) => setState(() => _budgetThreshold = v),
                    onChangeEnd: (v) => _updatePreferences(
                      prefs.copyWith(budgetThreshold: v.toInt()),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // ── Bill Reminders ────────────────────────────────────────
                _sectionTitle(
                    context, 'notificationSettings.billReminders'.tr()),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.billReminders'.tr(),
                  subtitle: 'notificationSettings.billRemindersSub'.tr(
                    namedArgs: {'days': prefs.billReminderDays.toString()},
                  ),
                  value: prefs.billReminders,
                  enabled: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(billReminders: v)),
                ),
                if (prefs.billReminders && pushOn) ...[
                  const SizedBox(height: AppSizes.sm),
                  _sliderTile(
                    context,
                    title: 'notificationSettings.billReminders'.tr(),
                    subtitle: 'notificationSettings.billRemindersSub'.tr(
                      namedArgs: {
                        'days': _billReminderDays!.toInt().toString()
                      },
                    ),
                    value: _billReminderDays!,
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '${_billReminderDays!.toInt()}d',
                    onChanged: (v) => setState(() => _billReminderDays = v),
                    onChangeEnd: (v) => _updatePreferences(
                      prefs.copyWith(billReminderDays: v.toInt()),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // ── Transaction Alerts ────────────────────────────────────
                _sectionTitle(
                    context, 'notificationSettings.transactionAlerts'.tr()),
                const SizedBox(height: AppSizes.sm),
                _switchTile(
                  context,
                  title: 'notificationSettings.transactionAlerts'.tr(),
                  subtitle: 'notificationSettings.transactionAlertsSub'.tr(
                    namedArgs: {'amount': '\$${prefs.transactionThreshold}'},
                  ),
                  value: prefs.transactionAlerts,
                  enabled: pushOn,
                  onChanged: (v) =>
                      _updatePreferences(prefs.copyWith(transactionAlerts: v)),
                ),
                if (prefs.transactionAlerts && pushOn) ...[
                  const SizedBox(height: AppSizes.sm),
                  _sliderTile(
                    context,
                    title: 'notificationSettings.transactionAlerts'.tr(),
                    subtitle: 'notificationSettings.transactionAlertsSub'.tr(
                      namedArgs: {
                        'amount': '\$${_transactionThreshold!.toInt()}'
                      },
                    ),
                    value: _transactionThreshold!,
                    min: 100,
                    max: 10000,
                    divisions: 99,
                    label: '\$${_transactionThreshold!.toInt()}',
                    onChanged: (v) => setState(() => _transactionThreshold = v),
                    onChangeEnd: (v) => _updatePreferences(
                      prefs.copyWith(transactionThreshold: v.toInt()),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // ── Money Health & Goals ──────────────────────────────────
                _sectionTitle(
                    context, 'notificationSettings.healthUpdates'.tr()),
                const SizedBox(height: AppSizes.sm),
                _dropdownTile(
                  context,
                  title: 'notificationSettings.healthUpdates'.tr(),
                  subtitle: 'notificationSettings.healthUpdates'.tr(),
                  value: prefs.moneyHealthUpdates,
                  items: const ['weekly', 'monthly', 'off'],
                  labels: const ['Weekly', 'Monthly', 'Off'],
                  enabled: pushOn,
                  onChanged: (v) {
                    if (v != null) {
                      _updatePreferences(prefs.copyWith(moneyHealthUpdates: v));
                    }
                  },
                ),
                const SizedBox(height: AppSizes.sm),
                _dropdownTile(
                  context,
                  title: 'notificationSettings.goalNotifications'.tr(),
                  subtitle: 'notificationSettings.goalNotifications'.tr(),
                  value: prefs.goalNotifications,
                  items: const ['milestones', 'all', 'off'],
                  labels: const ['Milestones Only', 'All Updates', 'Off'],
                  enabled: pushOn,
                  onChanged: (v) {
                    if (v != null) {
                      _updatePreferences(prefs.copyWith(goalNotifications: v));
                    }
                  },
                ),
                // [AI Insights - Commented out]
                // const SizedBox(height: AppSizes.sm),
                // _dropdownTile(
                //   context,
                //   title: 'AI Insights Frequency',
                //   subtitle: 'How often to refresh spending insights',
                //   value: prefs.aiInsightsFrequency,
                //   items: const ['daily', 'weekly', 'monthly'],
                //   labels: const ['Daily', 'Weekly', 'Monthly'],
                //   enabled: pushOn,
                //   onChanged: (v) {
                //     if (v != null) {
                //       _updatePreferences(prefs.copyWith(aiInsightsFrequency: v));
                //     }
                //   },
                // ),
                const SizedBox(height: AppSizes.lg),

                // ── Data & Backup ─────────────────────────────────────────
                _sectionTitle(context, 'notificationSettings.autoBackup'.tr()),
                const SizedBox(height: AppSizes.sm),
                _dropdownTile(
                  context,
                  title: 'notificationSettings.autoBackup'.tr(),
                  subtitle: 'notificationSettings.autoBackup'.tr(),
                  value: prefs.autoBackupSchedule,
                  items: const ['off', 'daily', 'weekly'],
                  labels: const ['Off', 'Daily', 'Weekly'],
                  onChanged: (v) {
                    if (v != null) {
                      _updatePreferences(prefs.copyWith(autoBackupSchedule: v));
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

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            activeColor: AppColors.primaryTeal,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required List<String> labels,
    bool enabled = true,
    required ValueChanged<String?> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                onChanged: onChanged,
                items: List.generate(
                  items.length,
                  (i) => DropdownMenuItem(
                    value: items[i],
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
