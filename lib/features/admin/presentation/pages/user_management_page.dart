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
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              AppSizes.sm,
              AppSizes.pagePadding,
              AppSizes.md,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondarySystemBackgroundDark
                    : AppColors.systemBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                        const SizedBox(height: AppSizes.sm),
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    width: 140,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  LoadingSkeleton(
                    width: 200,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      LoadingSkeleton(
                        width: 60,
                        height: 20,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      LoadingSkeleton(
                        width: 70,
                        height: 20,
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
