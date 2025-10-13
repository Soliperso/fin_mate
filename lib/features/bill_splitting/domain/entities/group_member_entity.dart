import 'package:equatable/equatable.dart';

enum MemberRole {
  admin,
  member;

  String get value => name;

  static MemberRole fromString(String value) {
    return MemberRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => MemberRole.member,
    );
  }
}

class GroupMember extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String? fullName;
  final String? email;
  final MemberRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.fullName,
    this.email,
    required this.role,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, groupId, userId, fullName, email, role, joinedAt];
}
