import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/feature_flag_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

IconData _flagIcon(String key) {
  switch (key) {
    case 'maintenance_mode':
      return CupertinoIcons.wrench;
    case 'receipt_scanner':
      return CupertinoIcons.camera;
    case 'csv_export':
      return CupertinoIcons.arrow_down_to_line;
    case 'savings_goals':
      return CupertinoIcons.flag;
    case 'debt_payoff':
      return CupertinoIcons.creditcard;
    case 'recurring_transactions':
      return CupertinoIcons.repeat;
    case 'ai_insights':
      return CupertinoIcons.lightbulb;
    case 'ads':
      return CupertinoIcons.rectangle_3_offgrid;
    case 'net_worth_tracking':
      return CupertinoIcons.chart_bar;
    case 'budget_alerts':
      return CupertinoIcons.bell;
    case 'biometric_login':
      return CupertinoIcons.lock_shield;
    case 'data_export_json':
      return CupertinoIcons.square_arrow_up;
    case 'emergency_fund':
      return CupertinoIcons.shield;
    case 'in_app_review':
      return CupertinoIcons.star;
    default:
      return CupertinoIcons.slider_horizontal_3;
  }
}

class FeatureTogglesPage extends ConsumerStatefulWidget {
  final bool betaOnly;
  const FeatureTogglesPage({super.key, this.betaOnly = false});

  @override
  ConsumerState<FeatureTogglesPage> createState() => _FeatureTogglesPageState();
}

class _FeatureTogglesPageState extends ConsumerState<FeatureTogglesPage> {
  // Optimistic toggle state while RPC is in-flight
  final Map<String, bool> _pending = {};
  // Optimistic rollout % while RPC is in-flight
  final Map<String, int> _pendingPct = {};
  // Debounce timers for rollout slider (one per flag key)
  final Map<String, Timer> _debounceTimers = {};

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _toggle(String key, bool newValue) async {
    setState(() => _pending[key] = newValue);
    try {
      await ref.read(adminRemoteDataSourceProvider).setFeatureFlag(key, newValue);
      ref.invalidate(featureFlagsProvider);
      ref.invalidate(appFeatureFlagsProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _pending.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update flag. Please try again.')),
        );
      }
    }
  }

  void _onRolloutSliderChanged(String key, double value) {
    final pct = value.round();
    setState(() => _pendingPct[key] = pct);
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 600), () {
      _commitRollout(key, pct);
    });
  }

  Future<void> _commitRollout(String key, int pct) async {
    try {
      await ref.read(adminRemoteDataSourceProvider).setRolloutPercentage(key, pct);
      ref.invalidate(featureFlagsProvider);
      ref.invalidate(appFeatureFlagsProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _pendingPct.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update rollout. Please try again.')),
        );
      }
    }
  }

  String _formatUpdatedAt(dynamic updatedAt) {
    if (updatedAt == null) return '';
    try {
      final dt = DateTime.parse(updatedAt as String).toLocal();
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flagsAsync = ref.watch(featureFlagsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        title: Text(widget.betaOnly ? 'Beta Features' : 'Feature Toggles'),
      ),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load flags'),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(featureFlagsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (flags) {
          final visible = widget.betaOnly
              ? flags.where((f) => f['is_beta'] == true).toList()
              : flags;
          final cardColor = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.md,
            ),
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _buildFlagItem(visible[i], isDark),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlagItem(Map<String, dynamic> flag, bool isDark) {
    final key = flag['key'] as String;
    final name = flag['name'] as String;
    final description = flag['description'] as String? ?? '';
    final isBeta = flag['is_beta'] as bool? ?? false;
    final isMaintenance = key == 'maintenance_mode';
    final updatedBy = flag['updated_by'] as String?;
    final updatedAt = flag['updated_at'];
    final rawPct = (flag['rollout_percentage'] as int?) ?? 100;

    final enabled = _pending.containsKey(key) ? _pending[key]! : flag['enabled'] as bool;
    final pct = _pendingPct.containsKey(key) ? _pendingPct[key]! : rawPct;

    // Maintenance mode uses red; enabled flags use teal; disabled use secondary.
    final Color iconColor;
    final Color iconBg;
    if (isMaintenance && enabled) {
      iconColor = Colors.red;
      iconBg = Colors.red.withValues(alpha: 0.12);
    } else if (enabled) {
      iconColor = AppColors.brandTeal;
      iconBg = isDark
          ? AppColors.tertiarySystemBackgroundDark
          : AppColors.brandTeal.withValues(alpha: 0.1);
    } else {
      iconColor = AppColors.textSecondary;
      iconBg = isDark
          ? AppColors.tertiarySystemBackgroundDark
          : AppColors.brandTeal.withValues(alpha: 0.06);
    }

    final dateStr = _formatUpdatedAt(updatedAt);
    final metaLine = updatedBy != null && updatedBy.isNotEmpty
        ? 'Changed by $updatedBy${dateStr.isNotEmpty ? ' · $dateStr' : ''}'
        : (dateStr.isNotEmpty ? 'Changed $dateStr' : null);

    final showSlider = enabled && key != 'ads' && !isMaintenance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_flagIcon(key), size: 20, color: iconColor),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isMaintenance && enabled ? Colors.red : null,
                  ),
                ),
              ),
              if (isBeta) ...[
                const SizedBox(width: 6),
                _Chip(label: 'Beta', color: AppColors.brandTeal),
              ],
              if (isMaintenance && enabled) ...[
                const SizedBox(width: 6),
                _Chip(label: 'LIVE', color: Colors.red),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (metaLine != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    metaLine,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                  ),
                ),
            ],
          ),
          trailing: Transform.scale(
            scale: 0.75,
            child: Switch(
              value: enabled,
              onChanged: (v) => _toggle(key, v),
              activeThumbColor:
                  isMaintenance ? Colors.red : AppColors.brandTeal,
              activeTrackColor: isMaintenance
                  ? Colors.red.withValues(alpha: 0.5)
                  : AppColors.brandTeal.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (showSlider)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.md + 52,
              right: AppSizes.md,
              bottom: 10,
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_2,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: pct.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.brandTeal,
                      inactiveColor:
                          AppColors.brandTeal.withValues(alpha: 0.2),
                      onChanged: (v) => _onRolloutSliderChanged(key, v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
