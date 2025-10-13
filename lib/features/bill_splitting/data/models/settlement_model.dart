import '../../domain/entities/settlement_entity.dart';

class SettlementModel extends Settlement {
  const SettlementModel({
    required super.id,
    required super.groupId,
    required super.fromUser,
    super.fromUserName,
    required super.toUser,
    super.toUserName,
    required super.amount,
    super.notes,
    super.evidenceUrl,
    required super.settledAt,
    required super.createdAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      fromUser: json['from_user'] as String,
      fromUserName: json['from_user_name'] as String?,
      toUser: json['to_user'] as String,
      toUserName: json['to_user_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      evidenceUrl: json['evidence_url'] as String?,
      settledAt: DateTime.parse(json['settled_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'from_user': fromUser,
      'from_user_name': fromUserName,
      'to_user': toUser,
      'to_user_name': toUserName,
      'amount': amount,
      'notes': notes,
      'evidence_url': evidenceUrl,
      'settled_at': settledAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
