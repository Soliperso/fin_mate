import 'package:equatable/equatable.dart';
import 'transaction_entity.dart';

/// Category entity for transaction categorization
class CategoryEntity extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final TransactionType type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        icon,
        color,
        isDefault,
        createdAt,
        updatedAt,
      ];

  CategoryEntity copyWith({
    String? id,
    String? userId,
    String? name,
    TransactionType? type,
    String? icon,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
