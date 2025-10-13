import 'package:equatable/equatable.dart';

enum SplitType {
  equal,
  custom,
  percentage;

  String get value => name;

  static SplitType fromString(String value) {
    return SplitType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SplitType.equal,
    );
  }
}

class GroupExpense extends Equatable {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final String? paidByName;
  final DateTime date;
  final String? category;
  final String? notes;
  final SplitType splitType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    this.paidByName,
    required this.date,
    this.category,
    this.notes,
    required this.splitType,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        description,
        amount,
        paidBy,
        paidByName,
        date,
        category,
        notes,
        splitType,
        createdAt,
        updatedAt,
      ];
}
