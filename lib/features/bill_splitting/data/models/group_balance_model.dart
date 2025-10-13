import '../../domain/entities/group_balance_entity.dart';

class GroupBalanceModel extends GroupBalance {
  const GroupBalanceModel({
    required super.userId,
    super.fullName,
    super.email,
    required super.balance,
  });

  factory GroupBalanceModel.fromJson(Map<String, dynamic> json) {
    return GroupBalanceModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'balance': balance,
    };
  }
}
