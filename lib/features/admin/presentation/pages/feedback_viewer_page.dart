import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../providers/admin_providers.dart';

final _feedbackCategoryProvider = StateProvider<String?>((ref) => null);

final _feedbackProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, category) {
  return ref
      .read(adminRemoteDataSourceProvider)
      .getFeedback(category: category);
});

class FeedbackViewerPage extends ConsumerWidget {
  const FeedbackViewerPage({super.key});

  static const _categories = ['bug', 'suggestion', 'other'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCategory = ref.watch(_feedbackCategoryProvider);
    final feedbackAsync = ref.watch(_feedbackProvider(selectedCategory));

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
        title: const Text('User Feedback'),
      ),
      body: Column(
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selectedCategory == null,
                  onTap: () => ref
                      .read(_feedbackCategoryProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: _label(c),
                        selected: selectedCategory == c,
                        onTap: () => ref
                            .read(_feedbackCategoryProvider.notifier)
                            .state = c,
                        color: _categoryColor(c),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: feedbackAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load feedback'),
                    const SizedBox(height: AppSizes.sm),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(_feedbackProvider(selectedCategory)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No feedback yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  );
                }
                final cardColor = isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground;
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (_, i) => _FeedbackCard(
                    data: items[i],
                    cardColor: cardColor,
                    onToggleReviewed: () async {
                      final reviewed =
                          items[i]['reviewed'] as bool? ?? false;
                      await ref
                          .read(adminRemoteDataSourceProvider)
                          .setFeedbackReviewed(
                            items[i]['id'] as String,
                            reviewed: !reviewed,
                          );
                      ref.invalidate(_feedbackProvider(selectedCategory));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String c) => switch (c) {
        'bug' => 'Bug',
        'suggestion' => 'Suggestion',
        _ => 'Other',
      };

  static Color _categoryColor(String c) => switch (c) {
        'bug' => Colors.red,
        'suggestion' => AppColors.brandTeal,
        _ => AppColors.textSecondary,
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandTeal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color cardColor;
  final VoidCallback onToggleReviewed;

  const _FeedbackCard({
    required this.data,
    required this.cardColor,
    required this.onToggleReviewed,
  });

  Color get _catColor => switch (data['category'] as String? ?? 'other') {
        'bug' => Colors.red,
        'suggestion' => AppColors.brandTeal,
        _ => AppColors.textSecondary,
      };

  String get _catLabel => switch (data['category'] as String? ?? 'other') {
        'bug' => 'Bug',
        'suggestion' => 'Suggestion',
        _ => 'Other',
      };

  String _fmt(dynamic val) {
    if (val == null) return '—';
    try {
      return DateFormat('MMM d, y · h:mm a')
          .format(DateTime.parse(val as String).toLocal());
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewed = data['reviewed'] as bool? ?? false;
    final email = data['user_email'] as String?;
    final platform = data['platform'] as String?;
    final version = data['app_version'] as String?;

    return Material(
      color: reviewed
          ? cardColor.withValues(alpha: 0.5)
          : cardColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(label: _catLabel, color: _catColor),
                const SizedBox(width: 6),
                if (platform != null)
                  _Chip(
                    label: platform == 'ios' ? 'iOS' : 'Android',
                    color: AppColors.textSecondary,
                  ),
                if (version != null) ...[
                  const SizedBox(width: 6),
                  _Chip(
                      label: 'v$version',
                      color: AppColors.textSecondary),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onToggleReviewed,
                  child: Icon(
                    reviewed
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: 20,
                    color: reviewed
                        ? AppColors.brandTeal
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['message'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: reviewed
                        ? AppColors.textSecondary
                        : null,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (email != null) email,
                _fmt(data['created_at']),
              ].join(' · '),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
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
