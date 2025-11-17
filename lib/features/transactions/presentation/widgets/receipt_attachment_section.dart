import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/widgets/premium_feature_dialog.dart';
import '../../../documents/presentation/widgets/upload_document_bottom_sheet.dart';

/// Widget to show receipt attachments and allow uploading receipts
class ReceiptAttachmentSection extends ConsumerWidget {
  final String transactionId;
  final List<dynamic>? attachedDocuments;
  final VoidCallback? onDocumentUploaded;

  const ReceiptAttachmentSection({
    super.key,
    required this.transactionId,
    this.attachedDocuments,
    this.onDocumentUploaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return isPremium.when(
      data: (premium) => premium
          ? _buildPremiumContent(context, ref)
          : _buildFreemiumContent(context),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildFreemiumContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        bottom: AppSizes.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.05),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Receipt Scanning',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Unlock receipt scanning to organize your receipts and extract expense details automatically.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPremiumDialog(context),
                icon: const Icon(Icons.star_outline),
                label: const Text('Learn More'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumContent(BuildContext context, WidgetRef ref) {
    final hasDocuments = attachedDocuments != null && attachedDocuments!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Receipts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showUploadSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Receipt'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        if (!hasDocuments)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'No receipts yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Tap "Add Receipt" to upload',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            child: Column(
              children: attachedDocuments!
                  .map((doc) => _buildReceiptItem(context, doc))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReceiptItem(BuildContext context, dynamic document) {
    // Assuming document has these fields
    final fileName = document['file_name'] ?? 'Receipt';
    final fileSize = document['file_size'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${(fileSize / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => UploadDocumentBottomSheet(
        transactionId: transactionId,
      ),
      isScrollControlled: true,
      useSafeArea: true,
    );
  }

  void _showPremiumDialog(BuildContext context) {
    PremiumFeatureDialog.show(
      context,
      featureName: 'Receipt Scanning',
      benefits: const [
        'Scan and organize receipts',
        'Extract expense details automatically',
        'Tax-deductible expense tracking',
        'Digital receipt storage',
      ],
    );
  }
}
