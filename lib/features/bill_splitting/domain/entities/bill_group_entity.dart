import 'package:equatable/equatable.dart';

class BillGroup extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, description, createdBy, createdAt, updatedAt];
}
