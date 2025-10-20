import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/document_entity.dart';
import '../providers/document_providers.dart';

class UploadDocumentBottomSheet extends ConsumerStatefulWidget {
  final String? transactionId;

  const UploadDocumentBottomSheet({super.key, this.transactionId});

  @override
  ConsumerState<UploadDocumentBottomSheet> createState() =>
      _UploadDocumentBottomSheetState();
}

class _UploadDocumentBottomSheetState
    extends ConsumerState<UploadDocumentBottomSheet> {
  File? _selectedFile;
  DocumentType _selectedType = DocumentType.receipt;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  bool _isTaxDeductible = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Please select a file');
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(documentOperationsProvider.notifier).uploadDocument(
            file: _selectedFile!,
            fileType: _selectedType,
            transactionId: widget.transactionId,
            title: _titleController.text.isNotEmpty ? _titleController.text : null,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            amount: _amountController.text.isNotEmpty
                ? double.tryParse(_amountController.text)
                : null,
            documentDate: _selectedDate,
            taxYear: _selectedDate?.year ?? DateTime.now().year,
            isTaxDeductible: _isTaxDeductible,
          );

      ref.invalidate(documentsProvider);

      if (mounted) {
        Navigator.pop(context);
        SuccessSnackbar.show(context, message: 'Document uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: 'Upload failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      padding: EdgeInsets.only(
        top: AppSizes.xl,
        left: AppSizes.xl,
        right: AppSizes.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Document',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),

            // File selection
            if (_selectedFile == null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Choose File (PDF, Images)'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppColors.primaryTeal),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        _selectedFile!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedFile = null),
                    ),
                  ],
                ),
              ),

            if (_selectedFile != null) ...[
              const SizedBox(height: AppSizes.lg),

              // Document type
              DropdownButtonFormField<DocumentType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                items: DocumentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: AppSizes.md),

              // Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Optional)',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Document Date (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Tax deductible
              CheckboxListTile(
                title: const Text('Tax Deductible'),
                value: _isTaxDeductible,
                onChanged: (value) {
                  setState(() => _isTaxDeductible = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSizes.lg),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Upload Document'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
