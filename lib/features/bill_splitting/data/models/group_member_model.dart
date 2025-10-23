import '../../domain/entities/group_member_entity.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.id,
    required super.groupId,
    required super.userId,
    super.fullName,
    super.email,
    super.avatarUrl,
    required super.role,
    required super.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: MemberRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role.value,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
