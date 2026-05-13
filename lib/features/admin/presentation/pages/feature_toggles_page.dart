import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/feature_flag_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

IconData _flagIcon(String key) {
  switch (key) {
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
  // Tracks optimistic toggle state while RPC is in-flight: key → enabled
  final Map<String, bool> _pending = {};

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
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final flag = visible[i];
                  final key = flag['key'] as String;
                  final enabled = _pending.containsKey(key)
                      ? _pending[key]!
                      : flag['enabled'] as bool;
                  final iconBg = isDark
                      ? AppColors.tertiarySystemBackgroundDark
                      : AppColors.brandTeal.withValues(alpha: 0.1);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _flagIcon(key),
                        size: 20,
                        color: enabled
                            ? AppColors.brandTeal
                            : AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      flag['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      flag['description'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    trailing: Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: enabled,
                        onChanged: (v) => _toggle(key, v),
                        activeThumbColor: AppColors.brandTeal,
                        activeTrackColor:
                            AppColors.brandTeal.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
