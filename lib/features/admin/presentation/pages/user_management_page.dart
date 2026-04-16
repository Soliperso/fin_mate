import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/admin_providers.dart';
import '../widgets/user_list_item.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider(UsersFilter(
      searchQuery: _searchQuery,
    )));
    final statsAsync = ref.watch(systemStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: const Text('User Management'),
      ),
      body: Column(
        children: [
          // ── Stats Bar ───────────────────────────────────────────────────
          statsAsync.when(
            data: (stats) => _buildStatsBar(context, isDark, stats),
            loading: () => _buildStatsBarSkeleton(context, isDark),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              12,
              AppSizes.pagePadding,
              12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(
                  color: isDark
                      ? AppColors.separatorDark.withValues(alpha: 0.4)
                      : AppColors.separator.withValues(alpha: 0.25),
                  width: 0.7,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.secondaryLabel,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
          ),

          // ── Users List ──────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: const Icon(
                              CupertinoIcons.person_2,
                              size: 32,
                              color: AppColors.brandTeal,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            _searchQuery != null
                                ? 'No users found'
                                : 'No users yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (_searchQuery != null) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.secondaryLabelDark
                                        : AppColors.secondaryLabel,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.brandTeal,
                  onRefresh: () async => ref.invalidate(usersListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      0,
                      AppSizes.pagePadding,
                      AppSizes.xl,
                    ),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) =>
                        UserListItem(user: users[index]),
                  ),
                );
              },
              loading: () => _buildSkeleton(isDark),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'Failed to load users',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.secondaryLabelDark
                                  : AppColors.secondaryLabel,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(usersListProvider),
                        icon: const Icon(
                            CupertinoIcons.arrow_counterclockwise,
                            size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    bool isDark,
    dynamic stats,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        12,
        AppSizes.pagePadding,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statChip(
              context,
              isDark,
              icon: CupertinoIcons.person_2,
              iconColor: AppColors.brandTeal,
              label: 'Total',
              value: stats.totalUsers?.toString() ?? '0',
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _statChip(
              context,
              isDark,
              icon: CupertinoIcons.checkmark_circle,
              iconColor: AppColors.systemGreen,
              label: 'Active',
              value: stats.activeUsers?.toString() ?? '0',
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _statChip(
              context,
              isDark,
              icon: CupertinoIcons.star,
              iconColor: AppColors.systemBlue,
              label: 'New',
              value: stats.newUsersThisMonth?.toString() ?? '0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.25),
          width: 0.7,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 13),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 8.5,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.labelDark : AppColors.label,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBarSkeleton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        12,
        AppSizes.pagePadding,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: LoadingSkeleton(
              height: 78,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LoadingSkeleton(
              height: 78,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LoadingSkeleton(
              height: 78,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        0,
        AppSizes.pagePadding,
        AppSizes.xl,
      ),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    width: 140,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 3),
                  LoadingSkeleton(
                    width: 200,
                    height: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      LoadingSkeleton(
                        width: 55,
                        height: 18,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      const SizedBox(width: 4),
                      LoadingSkeleton(
                        width: 65,
                        height: 18,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
