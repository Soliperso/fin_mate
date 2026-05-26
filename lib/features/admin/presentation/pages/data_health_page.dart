import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

final _dataHealthProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getDataHealth();
});

class DataHealthPage extends ConsumerWidget {
  const DataHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthAsync = ref.watch(_dataHealthProvider);

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
        title: const Text('Data Health Monitor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.refresh,
              onTap: () => ref.invalidate(_dataHealthProvider),
            ),
          ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to run health checks'),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(_dataHealthProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (checks) {
          final warnings =
              checks.where((c) => c['severity'] != 'ok').toList();
          final ok = checks.where((c) => c['severity'] == 'ok').toList();

          final cardColor = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            children: [
              // Summary banner
              _SummaryBanner(totalIssues: warnings.length),
              const SizedBox(height: AppSizes.md),

              if (warnings.isNotEmpty) ...[
                _sectionLabel(context, 'Needs Attention'),
                const SizedBox(height: AppSizes.sm),
                Material(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: warnings.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _CheckTile(data: warnings[i]),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              if (ok.isNotEmpty) ...[
                _sectionLabel(context, 'All Clear'),
                const SizedBox(height: AppSizes.sm),
                Material(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: ok.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) => _CheckTile(data: ok[i]),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int totalIssues;
  const _SummaryBanner({required this.totalIssues});

  @override
  Widget build(BuildContext context) {
    final isHealthy = totalIssues == 0;
    final color = isHealthy ? AppColors.brandTeal : AppColors.systemOrange;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy
                ? CupertinoIcons.checkmark_shield_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'All systems healthy' : '$totalIssues check${totalIssues == 1 ? '' : 's'} need attention',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  isHealthy
                      ? 'No data integrity issues found.'
                      : 'Review the items below and take corrective action.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CheckTile({required this.data});

  Color get _color => switch (data['severity'] as String? ?? 'ok') {
        'error' => Colors.red,
        'warn' => AppColors.systemOrange,
        _ => AppColors.brandTeal,
      };

  IconData get _icon => switch (data['severity'] as String? ?? 'ok') {
        'error' => CupertinoIcons.xmark_circle_fill,
        'warn' => CupertinoIcons.exclamationmark_circle_fill,
        _ => CupertinoIcons.checkmark_circle_fill,
      };

  @override
  Widget build(BuildContext context) {
    final count = data['issue_count'] as int? ?? 0;
    final isOk = data['severity'] == 'ok';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 4,
      ),
      leading: Icon(_icon, color: _color, size: 22),
      title: Text(
        _friendlyName(data['check_name'] as String? ?? ''),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        data['description'] as String? ?? '',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: isOk
          ? null
          : Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ),
    );
  }

  static String _friendlyName(String key) => switch (key) {
        'orphaned_accounts' => 'Dormant Accounts',
        'uncategorised_transactions' => 'Uncategorised Transactions',
        'goals_no_contributions' => 'Goals Without Contributions',
        'severely_exceeded_budgets' => 'Severely Exceeded Budgets',
        'incomplete_profiles' => 'Incomplete Profiles',
        'stale_debts' => 'Stale Debts',
        _ => key,
      };
}
