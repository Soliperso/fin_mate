import 'package:equatable/equatable.dart';

enum DocumentType {
  receipt,
  invoice,
  taxDocument,
  other,
}

enum TaxCategory {
  income,
  expense,
  deduction,
  other,
}

class DocumentEntity extends Equatable {
  final String id;
  final String userId;
  final String? transactionId;

  // File metadata
  final String fileName;
  final DocumentType fileType;
  final int fileSize;
  final String mimeType;
  final String storagePath;

  // Document details
  final String? title;
  final String? description;
  final String? category;
  final double? amount;
  final DateTime? documentDate;

  // Tax-related
  final int? taxYear;
  final TaxCategory? taxCategory;
  final bool isTaxDeductible;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentEntity({
    required this.id,
    required this.userId,
    this.transactionId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    this.title,
    this.description,
    this.category,
    this.amount,
    this.documentDate,
    this.taxYear,
    this.taxCategory,
    this.isTaxDeductible = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  @override
  List<Object?> get props => [
        id,
        userId,
        transactionId,
        fileName,
        fileType,
        fileSize,
        mimeType,
        storagePath,
        title,
        description,
        category,
        amount,
        documentDate,
        taxYear,
        taxCategory,
        isTaxDeductible,
        createdAt,
        updatedAt,
      ];
}
