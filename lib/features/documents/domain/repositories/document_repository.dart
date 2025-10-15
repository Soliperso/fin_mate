import 'dart:io';
import '../entities/document_entity.dart';

abstract class DocumentRepository {
  /// Upload a document file
  Future<DocumentEntity> uploadDocument({
    required File file,
    required DocumentType fileType,
    String? transactionId,
    String? title,
    String? description,
    String? category,
    double? amount,
    DateTime? documentDate,
    int? taxYear,
    TaxCategory? taxCategory,
    bool isTaxDeductible = false,
  });

  /// Get all documents for the current user
  Future<List<DocumentEntity>> getDocuments({
    DocumentType? fileType,
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get document by ID
  Future<DocumentEntity> getDocumentById(String documentId);

  /// Get documents for a specific transaction
  Future<List<DocumentEntity>> getDocumentsByTransaction(String transactionId);

  /// Update document metadata
  Future<DocumentEntity> updateDocument({
    required String documentId,
    String? title,
    String? description,
    String? category,
    double? amount,
    DateTime? documentDate,
    int? taxYear,
    TaxCategory? taxCategory,
    bool? isTaxDeductible,
  });

  /// Delete a document
  Future<void> deleteDocument(String documentId);

  /// Download document file
  Future<File> downloadDocument(String documentId);

  /// Get signed URL for viewing document
  Future<String> getDocumentUrl(String documentId, {int expiresInSeconds = 3600});

  /// Export documents to CSV for tax purposes
  Future<File> exportToCsv({
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Export documents to PDF report
  Future<File> exportToPdf({
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  });
}
