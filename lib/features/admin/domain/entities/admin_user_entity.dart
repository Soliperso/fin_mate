import 'package:equatable/equatable.dart';

/// Admin view of user data with statistics
class AdminUserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final int transactionCount;
  final double totalIncome;
  final double totalExpense;
  final double netWorth;
  final bool isActive; // Has transactions in last 30 days

  const AdminUserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.transactionCount = 0,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netWorth = 0.0,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        role,
        createdAt,
        transactionCount,
        totalIncome,
        totalExpense,
        netWorth,
        isActive,
      ];

  String get displayName => fullName ?? email.split('@').first;

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  bool get isAdmin => role == 'admin';
}
