import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Page for scanning receipts and extracting transaction data
/// [MVP: Disabled for initial launch - Shows "Coming Soon" message]
class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  @override
  void initState() {
    super.initState();
    // [MVP: Show "Coming Soon" dialog immediately]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showComingSoonDialog();
    });
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            const Expanded(
              child: Text(
                'Receipt Scanning',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This feature is coming soon!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Receipt scanning with automatic data extraction will be available during beta testing. All features are free for now!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Go back to add transaction page
            },
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
