import '../../domain/entities/admin_user_entity.dart';

/// Data model for admin user view
class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    required super.role,
    required super.createdAt,
    super.transactionCount,
    super.totalIncome,
    super.totalExpense,
    super.netWorth,
    super.isActive,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] as String?) ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      transactionCount: (json['transaction_count'] as int?) ?? 0,
      totalIncome: ((json['total_income'] as num?) ?? 0).toDouble(),
      totalExpense: ((json['total_expense'] as num?) ?? 0).toDouble(),
      netWorth: ((json['net_worth'] as num?) ?? 0).toDouble(),
      isActive: (json['is_active'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'transaction_count': transactionCount,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net_worth': netWorth,
      'is_active': isActive,
    };
  }
}
