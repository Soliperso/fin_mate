import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;

  DocumentRepositoryImpl({
    required DocumentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
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
  }) async {
    return await _remoteDataSource.uploadDocument(
      file: file,
      fileType: fileType,
      transactionId: transactionId,
      title: title,
      description: description,
      category: category,
      amount: amount,
      documentDate: documentDate,
      taxYear: taxYear,
      taxCategory: taxCategory,
      isTaxDeductible: isTaxDeductible,
    );
  }

  @override
  Future<List<DocumentEntity>> getDocuments({
    DocumentType? fileType,
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _remoteDataSource.getDocuments(
      fileType: fileType,
      taxYear: taxYear,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<DocumentEntity> getDocumentById(String documentId) async {
    return await _remoteDataSource.getDocumentById(documentId);
  }

  @override
  Future<List<DocumentEntity>> getDocumentsByTransaction(String transactionId) async {
    return await _remoteDataSource.getDocumentsByTransaction(transactionId);
  }

  @override
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
  }) async {
    return await _remoteDataSource.updateDocument(
      documentId: documentId,
      title: title,
      description: description,
      category: category,
      amount: amount,
      documentDate: documentDate,
      taxYear: taxYear,
      taxCategory: taxCategory,
      isTaxDeductible: isTaxDeductible,
    );
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _remoteDataSource.deleteDocument(documentId);
  }

  @override
  Future<File> downloadDocument(String documentId) async {
    throw UnimplementedError('Download not yet implemented');
  }

  @override
  Future<String> getDocumentUrl(String documentId, {int expiresInSeconds = 3600}) async {
    return await _remoteDataSource.getDocumentUrl(
      documentId,
      expiresInSeconds: expiresInSeconds,
    );
  }

  @override
  Future<File> exportToCsv({
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final documents = await getDocuments(
        taxYear: taxYear,
        startDate: startDate,
        endDate: endDate,
      );

      final csvContent = StringBuffer();
      // CSV Header
      csvContent.writeln(
        'Date,Title,Type,Category,Amount,Tax Year,Tax Category,Tax Deductible,File Name',
      );

      // CSV Rows
      for (final doc in documents) {
        csvContent.writeln(
          '${doc.documentDate ?? ''},${doc.title ?? ''},${doc.fileType.name},'
          '${doc.category ?? ''},${doc.amount ?? ''},${doc.taxYear ?? ''},'
          '${doc.taxCategory?.name ?? ''},${doc.isTaxDeductible},${doc.fileName}',
        );
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tax_documents_export.csv');
      await file.writeAsString(csvContent.toString());

      return file;
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  @override
  Future<File> exportToPdf({
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // PDF export would require pdf package
    // For MVP, we'll provide CSV export which is more universally compatible
    throw UnimplementedError('PDF export will be implemented in future version');
  }
}
