import 'package:equatable/equatable.dart';

class Settlement extends Equatable {
  final String id;
  final String groupId;
  final String fromUser;
  final String? fromUserName;
  final String toUser;
  final String? toUserName;
  final double amount;
  final String? notes;
  final String? evidenceUrl;
  final DateTime settledAt;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUser,
    this.fromUserName,
    required this.toUser,
    this.toUserName,
    required this.amount,
    this.notes,
    this.evidenceUrl,
    required this.settledAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        fromUser,
        fromUserName,
        toUser,
        toUserName,
        amount,
        notes,
        evidenceUrl,
        settledAt,
        createdAt,
      ];
}
