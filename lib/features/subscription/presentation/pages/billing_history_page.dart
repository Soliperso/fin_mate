import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../shared/widgets/glass_container.dart';

final invoicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await PaymentService().getInvoices();
});

class BillingHistoryPage extends ConsumerWidget {
  const BillingHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Billing History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: invoicesAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (invoices) {
          if (invoices.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoicesProvider);
              await ref.read(invoicesProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _buildInvoiceCard(context, invoice);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Failed to load billing history',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(invoicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'No Billing History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Your invoices will appear here once you subscribe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = invoice['status'] as String? ?? 'unknown';
    final paid = invoice['paid'] as bool? ?? false;
    final amountPaid = invoice['amountPaid'] as int? ?? 0;
    final currency = invoice['currency'] as String? ?? 'usd';
    final created = invoice['created'] as int?;
    final number = invoice['number'] as String?;
    final description = invoice['description'] as String? ?? 'Subscription';
    final periodStart = invoice['periodStart'] as int?;
    final periodEnd = invoice['periodEnd'] as int?;
    final invoicePdf = invoice['invoicePdf'] as String?;
    final hostedInvoiceUrl = invoice['hostedInvoiceUrl'] as String?;

    final formattedAmount = _formatAmount(amountPaid, currency);
    final formattedDate = created != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(created * 1000))
        : 'Unknown date';

    final statusColor = paid ? AppColors.success : AppColors.warning;
    final statusText = paid ? 'Paid' : _capitalizeFirst(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSizes.lg),
        enableGlass: false,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    paid ? Icons.check_circle : Icons.schedule,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formattedAmount,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (number != null) ...[
                        const Text(
                          'Invoice Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          number,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                      ],
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (periodStart != null && periodEnd != null) ...[
                        const SizedBox(height: AppSizes.sm),
                        const Text(
                          'Billing Period',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM dd').format(DateTime.fromMillisecondsSinceEpoch(periodStart * 1000))} - ${DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(periodEnd * 1000))}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (invoicePdf != null || hostedInvoiceUrl != null) ...[
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  if (invoicePdf != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadInvoice(context, invoicePdf, number ?? 'invoice'),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                        ),
                      ),
                    ),
                  if (invoicePdf != null && hostedInvoiceUrl != null)
                    const SizedBox(width: AppSizes.sm),
                  if (hostedInvoiceUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(hostedInvoiceUrl),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View Online'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amountCents, String currency) {
    final amount = amountCents / 100;
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      default:
        return currency.toUpperCase();
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _downloadInvoice(BuildContext context, String pdfUrl, String invoiceNumber) async {
    try {
      // Show loading indicator
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Downloading invoice...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Download the PDF
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download invoice');
      }

      // Get the appropriate directory based on platform
      Directory? directory;

      if (Platform.isAndroid) {
        // Request storage permission on Android
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try with manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception('Storage permission denied');
          }
        }

        // Use Downloads directory on Android
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Use app documents directory on iOS
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Use downloads directory for other platforms
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file name
      final fileName = 'FinMate_$invoiceNumber.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice saved to ${Platform.isAndroid ? 'Downloads' : 'Documents'}'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _launchUrl(pdfUrl),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download invoice: ${e.toString()}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'View Online',
            textColor: Colors.white,
            onPressed: () => _launchUrl(pdfUrl),
          ),
        ),
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
