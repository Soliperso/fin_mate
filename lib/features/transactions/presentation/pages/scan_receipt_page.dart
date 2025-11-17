import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/receipt_ocr_service.dart';
import '../../data/services/receipt_categorizer_service.dart';
import '../../domain/entities/receipt_data.dart';

/// Page for scanning receipts and extracting transaction data
class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  final _ocrService = ReceiptOcrService();
  final _imagePicker = ImagePicker();
  ReceiptData? _extractedData;
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
        _error = null;
      });

      // Pick image
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Process receipt
      final receiptData = await _ocrService.processReceipt(pickedFile.path);

      final extracted = ReceiptData(
        fullText: receiptData['text'] ?? '',
        amount: (receiptData['amount'] ?? 0.0).toDouble(),
        merchant: receiptData['merchant'] ?? 'Receipt Item',
        date: receiptData['date'] ?? DateTime.now(),
        items: List<String>.from(receiptData['items'] ?? []),
      );

      setState(() {
        _extractedData = extracted;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to scan receipt: $e';
        _isProcessing = false;
      });
    }
  }

  void _confirmAndNavigate() {
    if (_extractedData == null) return;

    // Navigate back to AddTransactionPage with extracted data
    context.pop(_extractedData);
  }

  @override
  Widget build(BuildContext context) {
    if (_extractedData != null) {
      return _buildReviewScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildScannerUI(),
    );
  }

  Widget _buildScannerUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 50,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              'Scan Your Receipt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),

            // Description
            Text(
              'Take a photo of your receipt to automatically extract transaction details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Camera button
            ElevatedButton.icon(
              onPressed: () => _scanReceipt(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Or divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Text(
                    'OR',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Gallery button
            OutlinedButton.icon(
              onPressed: () => _scanReceipt(ImageSource.gallery),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    final data = _extractedData!;
    final suggestedCategory =
        ReceiptCategorizerService.suggestCategory(data.merchant, data.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _extractedData = null);
            },
            child: Text(
              'Retake',
              style: TextStyle(color: AppColors.primaryTeal),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount (editable)
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      '\$${data.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Merchant
              _buildInfoField('Merchant', data.merchant),
              const SizedBox(height: AppSizes.md),

              // Date
              _buildInfoField('Date', _formatDate(data.date)),
              const SizedBox(height: AppSizes.md),

              // Suggested Category
              _buildInfoField('Category', suggestedCategory.substring(0, 1).toUpperCase() + suggestedCategory.substring(1)),
              const SizedBox(height: AppSizes.lg),

              // Items (if any)
              if (data.items.isNotEmpty) ...[
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Column(
                    children: data.items
                        .take(5) // Show first 5 items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.primaryTeal,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Text(
                                    item.length > 50 ? '${item.substring(0, 47)}...' : item,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  ),
                  child: const Text(
                    'Use This Receipt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
