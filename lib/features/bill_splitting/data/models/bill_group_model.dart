import '../../domain/entities/bill_group_entity.dart';

class BillGroupModel extends BillGroup {
  const BillGroupModel({
    required super.id,
    required super.name,
    super.description,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BillGroupModel.fromJson(Map<String, dynamic> json) {
    return BillGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
