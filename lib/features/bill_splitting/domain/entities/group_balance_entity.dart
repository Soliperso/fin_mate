import 'package:equatable/equatable.dart';

class GroupBalance extends Equatable {
  final String userId;
  final String? fullName;
  final String? email;
  final double balance;

  const GroupBalance({
    required this.userId,
    this.fullName,
    this.email,
    required this.balance,
  });

  bool get isOwed => balance > 0;
  bool get owes => balance < 0;
  bool get isSettled => balance == 0;

  @override
  List<Object?> get props => [userId, fullName, email, balance];
}
