import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../providers/admin_providers.dart';
import '../widgets/user_list_item.dart';

enum _SortOrder { aToZ, zToA }

enum _FilterType {
  all,
  admin,
  active,
  inactive;

  String get label => switch (this) {
        _FilterType.all => 'All',
        _FilterType.admin => 'Admin',
        _FilterType.active => 'Active',
        _FilterType.inactive => 'Inactive',
      };
}

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  _SortOrder _sortOrder = _SortOrder.aToZ;
  _FilterType _activeFilter = _FilterType.all;
  List<AdminUserEntity> _sourceUsers = [];
  List<AdminUserEntity> _displayUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _sourceUsers = [];
      _displayUsers = [];
    });
  }

  List<AdminUserEntity> _applySort(List<AdminUserEntity> users) {
    final copy = [...users];
    copy.sort((a, b) => _sortOrder == _SortOrder.aToZ
        ? a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())
        : b.displayName.toLowerCase().compareTo(a.displayName.toLowerCase()));
    return copy;
  }

  List<AdminUserEntity> _filterUsers(List<AdminUserEntity> users) =>
      switch (_activeFilter) {
        _FilterType.all => [...users],
        _FilterType.admin => users.where((u) => u.isAdmin).toList(),
        _FilterType.active => users.where((u) => u.isActive).toList(),
        _FilterType.inactive => users.where((u) => !u.isActive).toList(),
      };

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final list = List<AdminUserEntity>.from(_displayUsers);
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _displayUsers = list;
    });
  }

  Future<bool?> _handleSwipeAction(
    DismissDirection direction,
    AdminUserEntity user,
  ) async {
    if (direction == DismissDirection.endToStart) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disable Account'),
          content: Text('Disable ${user.displayName}\'s account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Disable',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        try {
          await ref.read(adminRepositoryProvider).disableUserAccount(user.id);
          ref.invalidate(usersListProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.displayName}\'s account disabled')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset Password'),
          content: Text('Send a password reset email to ${user.email}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send Reset'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        try {
          await ref.read(adminRepositoryProvider).resetUserPassword(user.email);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset email sent')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
    return false;
  }

  Widget _buildSwipeBackground({required bool isStart}) {
    return Container(
      alignment: isStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      decoration: BoxDecoration(
        color: isStart ? AppColors.systemBlue : AppColors.error,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isStart ? CupertinoIcons.lock : CupertinoIcons.xmark_circle,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            isStart ? 'Reset\nPwd' : 'Disable',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider(UsersFilter(
      searchQuery: _searchQuery,
    )));
    final statsAsync = ref.watch(systemStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sync fresh provider data into local source + filtered lists
    ref.listen<AsyncValue<List<AdminUserEntity>>>(
      usersListProvider(UsersFilter(searchQuery: _searchQuery)),
      (_, next) => next.whenData((users) {
        if (mounted) {
          setState(() {
            _sourceUsers = _applySort(users);
            _displayUsers = _filterUsers(_sourceUsers);
          });
        }
      }),
    );

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('User Management'),
            if (_sourceUsers.isNotEmpty)
              Text(
                _activeFilter == _FilterType.all
                    ? '${_displayUsers.length} users'
                    : '${_displayUsers.length} of ${_sourceUsers.length} users',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: CircularIconButton(
                icon: _sortOrder == _SortOrder.aToZ
                    ? CupertinoIcons.sort_down
                    : CupertinoIcons.sort_up,
                onTap: () => setState(() {
                  _sortOrder = _sortOrder == _SortOrder.aToZ
                      ? _SortOrder.zToA
                      : _SortOrder.aToZ;
                  if (_sourceUsers.isNotEmpty) {
                    _sourceUsers = _applySort(_sourceUsers);
                    _displayUsers = _filterUsers(_sourceUsers);
                  }
                }),
              ),
            ),
          ),
        ],
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
              8,
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

          // ── Filter Chips ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              0,
              AppSizes.pagePadding,
              10,
            ),
            child: Row(
              children: _FilterType.values.map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _activeFilter = filter;
                      _displayUsers = _filterUsers(_sourceUsers);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandTeal
                            : (isDark
                                ? AppColors.secondarySystemBackgroundDark
                                : AppColors.systemBackground),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandTeal
                              : (isDark
                                  ? AppColors.separatorDark
                                      .withValues(alpha: 0.4)
                                  : AppColors.separator
                                      .withValues(alpha: 0.25)),
                          width: 0.7,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterIcon(filter),
                            size: 13,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.labelDark
                                    : AppColors.label),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.labelDark
                                      : AppColors.label),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Users List ──────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // On first load / after search reset, seed both lists
                if (_sourceUsers.isEmpty && users.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _sourceUsers.isEmpty) {
                      setState(() {
                        _sourceUsers = _applySort(users);
                        _displayUsers = _filterUsers(_sourceUsers);
                      });
                    }
                  });
                }

                final sourceToUse = _sourceUsers.isNotEmpty
                    ? _sourceUsers
                    : _applySort(users);
                final display = _displayUsers.isNotEmpty
                    ? _displayUsers
                    : _filterUsers(sourceToUse);

                if (display.isEmpty) {
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
                            _searchQuery != null || _activeFilter != _FilterType.all
                                ? 'No users found'
                                : 'No users yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (_searchQuery != null ||
                              _activeFilter != _FilterType.all) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Try a different search or filter',
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
                  onRefresh: () async {
                    setState(() {
                      _sourceUsers = [];
                      _displayUsers = [];
                    });
                    ref.invalidate(usersListProvider);
                  },
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      0,
                      AppSizes.pagePadding,
                      AppSizes.xl,
                    ),
                    onReorderItem: _onReorderItem,
                    itemCount: display.length,
                    itemBuilder: (context, index) {
                      final user = display[index];
                      return Dismissible(
                        key: ValueKey(user.id),
                        background: _buildSwipeBackground(isStart: true),
                        secondaryBackground:
                            _buildSwipeBackground(isStart: false),
                        confirmDismiss: (direction) =>
                            _handleSwipeAction(direction, user),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: UserListItem(user: user),
                        ),
                      );
                    },
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 9),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Watermark icon
          Icon(
            icon,
            size: 58,
            color: iconColor.withValues(alpha: 0.10),
          ),
          // Centred label + value
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  IconData _filterIcon(_FilterType filter) => switch (filter) {
        _FilterType.all => CupertinoIcons.person_2,
        _FilterType.admin => CupertinoIcons.shield,
        _FilterType.active => CupertinoIcons.checkmark_circle_fill,
        _FilterType.inactive => CupertinoIcons.xmark_circle,
      };

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
