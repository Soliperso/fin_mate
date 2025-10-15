import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/document_providers.dart';
import '../widgets/upload_document_bottom_sheet.dart';
import '../../domain/entities/document_entity.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportOptions(context, ref),
            tooltip: 'Export Tax Documents',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(documentsProvider);
        },
        child: documentsAsync.when(
          data: (documents) {
            if (documents.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const EmptyState(
                    icon: Icons.folder_outlined,
                    title: 'No Documents Yet',
                    message: 'Upload receipts, invoices, and tax documents to keep everything organized',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _buildDocumentCard(context, ref, doc);
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSizes.md),
              child: SkeletonCard(height: 100),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSizes.md),
                Text('Failed to load documents'),
                const SizedBox(height: AppSizes.sm),
                ElevatedButton(
                  onPressed: () => ref.invalidate(documentsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadSheet(context, ref),
        backgroundColor: AppColors.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, WidgetRef ref, DocumentEntity doc) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: _getTypeColor(doc.fileType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            _getTypeIcon(doc.fileType),
            color: _getTypeColor(doc.fileType),
          ),
        ),
        title: Text(
          doc.title ?? doc.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${doc.fileType.name} • ${doc.fileSizeFormatted}'),
            if (doc.documentDate != null)
              Text('Date: ${dateFormat.format(doc.documentDate!)}'),
            if (doc.amount != null)
              Text('Amount: \$${doc.amount!.toStringAsFixed(2)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              await _deleteDocument(context, ref, doc.id);
            }
          },
        ),
      ),
    );
  }

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.invoice:
        return Icons.description;
      case DocumentType.taxDocument:
        return Icons.account_balance;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return AppColors.success;
      case DocumentType.invoice:
        return AppColors.tealLight;
      case DocumentType.taxDocument:
        return AppColors.primaryTeal;
      case DocumentType.other:
        return AppColors.textSecondary;
    }
  }

  void _showUploadSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UploadDocumentBottomSheet(),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Tax Documents'),
        content: const Text('Export all your tax documents to CSV format?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportDocuments(context, ref);
            },
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDocuments(BuildContext context, WidgetRef ref) async {
    try {
      final file = await ref
          .read(documentOperationsProvider.notifier)
          .exportToCsv(taxYear: DateTime.now().year);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(BuildContext context, WidgetRef ref, String documentId) async {
    try {
      await ref.read(documentOperationsProvider.notifier).deleteDocument(documentId);
      ref.invalidate(documentsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}
