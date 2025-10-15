import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/document_model.dart';
import '../../domain/entities/document_entity.dart';

class DocumentRemoteDataSource {
  final SupabaseClient _supabase;
  static const String _bucketName = 'documents';

  DocumentRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  Future<DocumentModel> uploadDocument({
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
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$timestamp-$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: false));

      // Create document record in database
      final response = await _supabase.from('documents').insert({
        'user_id': userId,
        'transaction_id': transactionId,
        'file_name': fileName,
        'file_type': _fileTypeToString(fileType),
        'file_size': await file.length(),
        'mime_type': _getMimeType(fileExtension),
        'storage_path': storagePath,
        'title': title,
        'description': description,
        'category': category,
        'amount': amount,
        'document_date': documentDate?.toIso8601String().split('T')[0],
        'tax_year': taxYear,
        'tax_category': taxCategory != null ? _taxCategoryToString(taxCategory) : null,
        'is_tax_deductible': isTaxDeductible,
      }).select().single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<List<DocumentModel>> getDocuments({
    DocumentType? fileType,
    int? taxYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query = _supabase.from('documents').select().eq('user_id', userId);

      if (fileType != null) {
        query = query.eq('file_type', _fileTypeToString(fileType));
      }
      if (taxYear != null) {
        query = query.eq('tax_year', taxYear);
      }
      if (startDate != null) {
        query = query.gte('document_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('document_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<DocumentModel> getDocumentById(String documentId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('id', documentId)
          .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  Future<List<DocumentModel>> getDocumentsByTransaction(String transactionId) async {
    try {
      final response = await _supabase
          .from('documents')
          .select()
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => DocumentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<DocumentModel> updateDocument({
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
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (amount != null) updates['amount'] = amount;
      if (documentDate != null) {
        updates['document_date'] = documentDate.toIso8601String().split('T')[0];
      }
      if (taxYear != null) updates['tax_year'] = taxYear;
      if (taxCategory != null) {
        updates['tax_category'] = _taxCategoryToString(taxCategory);
      }
      if (isTaxDeductible != null) updates['is_tax_deductible'] = isTaxDeductible;

      final response = await _supabase
          .from('documents')
          .update(updates)
          .eq('id', documentId)
          .select()
          .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      // Get document to find storage path
      final doc = await getDocumentById(documentId);

      // Delete file from storage
      await _supabase.storage.from(_bucketName).remove([doc.storagePath]);

      // Delete record from database
      await _supabase.from('documents').delete().eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<String> getDocumentUrl(String documentId, {int expiresInSeconds = 3600}) async {
    try {
      final doc = await getDocumentById(documentId);
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(doc.storagePath, expiresInSeconds);
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get document URL: $e');
    }
  }

  String _fileTypeToString(DocumentType type) {
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

  String _taxCategoryToString(TaxCategory category) {
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

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }
}
