import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/proactive_alert.dart';
import '../providers/insights_providers.dart';

class ProactiveInsightStrip extends ConsumerWidget {
  final Function(String prompt) onPromptTap;
  final VoidCallback onViewInsights;

  const ProactiveInsightStrip({
    super.key,
    required this.onPromptTap,
    required this.onViewInsights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(typedProactiveAlertsProvider);
    final dismissedIds = ref.watch(dismissedAlertIdsProvider);

    return alertsAsync.when(
      data: (alerts) {
        final active = alerts
            .where((a) => !dismissedIds.contains(a.id))
            .take(5)
            .toList();

        return _StripContent(
          alerts: active,
          onPromptTap: onPromptTap,
          onViewInsights: onViewInsights,
        );
      },
      loading: () => const _StripSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StripContent extends StatelessWidget {
  final List<ProactiveAlert> alerts;
  final Function(String) onPromptTap;
  final VoidCallback onViewInsights;

  const _StripContent({
    required this.alerts,
    required this.onPromptTap,
    required this.onViewInsights,
  });

  @override
  Widget build(BuildContext context) {
    final chips = alerts.isEmpty
        ? [_allClearChip(context)]
        : alerts.map((a) => _alertChip(context, a)).toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: chips.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSizes.xs + 2),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _allClearChip(BuildContext context) {
    return _InsightChip(
      icon: CupertinoIcons.checkmark_shield_fill,
      label: 'All clear',
      color: AppColors.systemGreen,
      onTap: onViewInsights,
    );
  }

  Widget _alertChip(BuildContext context, ProactiveAlert alert) {
    final color = _severityColor(alert.severity);
    final icon = _alertIcon(alert.type);
    final prompt = _alertPrompt(alert);

    return _InsightChip(
      icon: icon,
      label: alert.title,
      color: color,
      onTap: () => onPromptTap(prompt),
    );
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.systemRed;
      case AlertSeverity.high:
        return AppColors.systemOrange;
      case AlertSeverity.medium:
        return AppColors.brandTeal;
      case AlertSeverity.low:
        return AppColors.systemBlue;
    }
  }

  IconData _alertIcon(AlertType type) {
    switch (type) {
      case AlertType.cashFlowWarning:
        return CupertinoIcons.arrow_down_circle_fill;
      case AlertType.billCollision:
        return CupertinoIcons.calendar_badge_minus;
      case AlertType.lowBalance:
        return CupertinoIcons.exclamationmark_circle_fill;
      case AlertType.unusualSpending:
        return CupertinoIcons.chart_bar_fill;
      case AlertType.unknown:
        return CupertinoIcons.info_circle_fill;
    }
  }

  String _alertPrompt(ProactiveAlert alert) {
    switch (alert.type) {
      case AlertType.cashFlowWarning:
        return 'Tell me about my cash flow situation';
      case AlertType.billCollision:
        return 'What bills are due soon?';
      case AlertType.lowBalance:
        return 'What is my current balance and how can I avoid overdraft?';
      case AlertType.unusualSpending:
        return 'Explain the unusual spending detected in my account';
      case AlertType.unknown:
        return alert.message;
    }
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 2, vertical: AppSizes.xs + 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.08),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSizes.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripSkeleton extends StatelessWidget {
  const _StripSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs + 2),
        itemBuilder: (_, __) => Container(
          width: 110,
          decoration: BoxDecoration(
            color: AppColors.systemGray5,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
      ),
    );
  }
}
