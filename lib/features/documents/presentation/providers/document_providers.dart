import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';

// Repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: DocumentRemoteDataSource(),
  );
});

// Documents list provider
final documentsProvider = FutureProvider.autoDispose<List<DocumentEntity>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  return await repository.getDocuments();
});

// Documents by type provider
final documentsByTypeProvider = FutureProvider.autoDispose
    .family<List<DocumentEntity>, DocumentType>((ref, fileType) async {
  final repository = ref.watch(documentRepositoryProvider);
  return await repository.getDocuments(fileType: fileType);
});

// Documents by tax year provider
final documentsByTaxYearProvider =
    FutureProvider.autoDispose.family<List<DocumentEntity>, int>((ref, taxYear) async {
  final repository = ref.watch(documentRepositoryProvider);
  return await repository.getDocuments(taxYear: taxYear);
});

// Documents by transaction provider
final documentsByTransactionProvider =
    FutureProvider.autoDispose.family<List<DocumentEntity>, String>((ref, transactionId) async {
  final repository = ref.watch(documentRepositoryProvider);
  return await repository.getDocumentsByTransaction(transactionId);
});

// Document operations notifier
class DocumentOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final DocumentRepository _repository;

  DocumentOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

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
    state = const AsyncValue.loading();
    try {
      final document = await _repository.uploadDocument(
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
      state = const AsyncValue.data(null);
      return document;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteDocument(String documentId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDocument(documentId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<File> exportToCsv({
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final file = await _repository.exportToCsv(
        taxYear: taxYear,
        startDate: startDate,
        endDate: endDate,
      );
      state = const AsyncValue.data(null);
      return file;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final documentOperationsProvider =
    StateNotifierProvider<DocumentOperationsNotifier, AsyncValue<void>>((ref) {
  return DocumentOperationsNotifier(ref.watch(documentRepositoryProvider));
});
