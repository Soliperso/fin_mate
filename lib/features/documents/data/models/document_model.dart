import '../../domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.userId,
    super.transactionId,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.mimeType,
    required super.storagePath,
    super.title,
    super.description,
    super.category,
    super.amount,
    super.documentDate,
    super.taxYear,
    super.taxCategory,
    super.isTaxDeductible,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionId: json['transaction_id'] as String?,
      fileName: json['file_name'] as String,
      fileType: _parseFileType(json['file_type'] as String),
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      storagePath: json['storage_path'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      documentDate: json['document_date'] != null
          ? DateTime.parse(json['document_date'] as String)
          : null,
      taxYear: json['tax_year'] as int?,
      taxCategory: json['tax_category'] != null
          ? _parseTaxCategory(json['tax_category'] as String)
          : null,
      isTaxDeductible: json['is_tax_deductible'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_id': transactionId,
      'file_name': fileName,
      'file_type': _fileTypeToString(fileType),
      'file_size': fileSize,
      'mime_type': mimeType,
      'storage_path': storagePath,
      'title': title,
      'description': description,
      'category': category,
      'amount': amount,
      'document_date': documentDate?.toIso8601String().split('T')[0],
      'tax_year': taxYear,
      'tax_category': taxCategory != null ? _taxCategoryToString(taxCategory!) : null,
      'is_tax_deductible': isTaxDeductible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DocumentType _parseFileType(String type) {
    switch (type) {
      case 'receipt':
        return DocumentType.receipt;
      case 'invoice':
        return DocumentType.invoice;
      case 'tax_document':
        return DocumentType.taxDocument;
      default:
        return DocumentType.other;
    }
  }

  static String _fileTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return 'receipt';
      case DocumentType.invoice:
        return 'invoice';
      case DocumentType.taxDocument:
        return 'tax_document';
      case DocumentType.other:
        return 'other';
    }
  }

  static TaxCategory _parseTaxCategory(String category) {
    switch (category) {
      case 'income':
        return TaxCategory.income;
      case 'expense':
        return TaxCategory.expense;
      case 'deduction':
        return TaxCategory.deduction;
      default:
        return TaxCategory.other;
    }
  }

  static String _taxCategoryToString(TaxCategory category) {
    switch (category) {
      case TaxCategory.income:
        return 'income';
      case TaxCategory.expense:
        return 'expense';
      case TaxCategory.deduction:
        return 'deduction';
      case TaxCategory.other:
        return 'other';
    }
  }
}
