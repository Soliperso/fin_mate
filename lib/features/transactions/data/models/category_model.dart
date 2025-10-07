import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
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

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      color: json['color'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      // Handle missing updated_at column in database
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      userId: userId,
      name: name,
      type: _parseType(type),
      icon: icon,
      color: color,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static CategoryModel fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type.name,
      icon: entity.icon,
      color: entity.color,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static TransactionType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }
}
