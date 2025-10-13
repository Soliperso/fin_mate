import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/group_member_entity.dart';

class MembersSection extends ConsumerWidget {
  final String groupId;
  final List<GroupMember> members;
  final String currentUserId;
  final VoidCallback? onAddMember;

  const MembersSection({
    super.key,
    required this.groupId,
    required this.members,
    required this.currentUserId,
    this.onAddMember,
  });

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return AppColors.slateBlue;
      case MemberRole.member:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort members: current user first, then admins, then members
    final sortedMembers = List<GroupMember>.from(members);
    sortedMembers.sort((a, b) {
      if (a.userId == currentUserId) return -1;
      if (b.userId == currentUserId) return 1;
      if (a.role == MemberRole.admin && b.role != MemberRole.admin) return -1;
      if (b.role == MemberRole.admin && a.role != MemberRole.admin) return 1;
      return 0;
    });

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${members.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (onAddMember != null)
                TextButton.icon(
                  onPressed: onAddMember,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMembers.length,
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              final isCurrentUser = member.userId == currentUserId;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentUser
                        ? AppColors.slateBlue.withValues(alpha: 0.2)
                        : AppColors.lightGray,
                    child: Text(
                      _getInitials(member.fullName),
                      style: TextStyle(
                        color: isCurrentUser ? AppColors.slateBlue : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentUser
                              ? 'You'
                              : member.fullName ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(member.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          member.role.value.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _getRoleColor(member.role),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: member.email != null
                      ? Text(
                          member.email!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        )
                      : null,
                  trailing: isCurrentUser
                      ? Icon(
                          Icons.person,
                          color: AppColors.slateBlue.withValues(alpha: 0.5),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
