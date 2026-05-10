import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/admin_user_entity.dart';

class UserListItem extends StatelessWidget {
  final AdminUserEntity user;

  const UserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final statusColor = user.isAdmin
        ? AppColors.brandTeal
        : user.isActive
            ? AppColors.systemGreen
            : (isDark ? AppColors.tertiaryLabelDark : AppColors.systemGray3);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: statusColor),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/admin/users/${user.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.brandTeal.withValues(alpha: 0.15),
                          backgroundImage: user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child:
                              user.avatarUrl == null || user.avatarUrl!.isEmpty
                                  ? Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: AppColors.brandTeal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                        ),
                        const SizedBox(width: AppSizes.md),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.xs),
                                  if (user.isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandTeal
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                            AppSizes.radiusSm),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.shield,
                                            size: 12,
                                            color: AppColors.brandTeal,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Admin',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppColors.brandTeal,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!user.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.systemRed
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppSizes.radiusSm),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.lock_fill,
                                            size: 11,
                                            color: AppColors.systemRed,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Disabled',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppColors.systemRed,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.secondaryLabelDark
                                          : AppColors.secondaryLabel,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatJoinDate(user.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.secondaryLabelDark
                                      : AppColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat.compactCurrency(symbol: '\$')
                                  .format(user.netWorth),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.labelDark
                                    : AppColors.label,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user.transactionCount} txns',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.secondaryLabelDark
                                    : AppColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // Arrow Icon
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: isDark
                              ? AppColors.tertiaryLabelDark
                              : AppColors.systemGray3,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ), // InkWell
              ), // Material
            ), // Expanded
          ], // outer Row children
        ), // outer Row
      ), // IntrinsicHeight
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return 'Joined ${DateFormat('MMM d').format(date)}';
    }
    return 'Joined ${DateFormat('MMM d, y').format(date)}';
  }
}
