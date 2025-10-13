import '../../domain/entities/category_breakdown_entity.dart';

class CategoryBreakdownModel extends CategoryBreakdownEntity {
  const CategoryBreakdownModel({
    required super.categoryId,
    required super.categoryName,
    required super.categoryType,
    required super.totalAmount,
    required super.transactionCount,
    required super.percentageOfTotal,
  });

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownModel(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryType: json['category_type'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
      percentageOfTotal: (json['percentage_of_total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_type': categoryType,
      'total_amount': totalAmount,
      'transaction_count': transactionCount,
      'percentage_of_total': percentageOfTotal,
    };
  }
}
