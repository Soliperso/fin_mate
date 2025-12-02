import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../shared/widgets/glass_container.dart';

final paymentMethodsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await PaymentService().getPaymentMethods();
});

class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Payment Methods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addPaymentMethod(context),
            ),
        ],
      ),
      body: paymentMethodsAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (paymentMethods) {
          if (paymentMethods.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(paymentMethodsProvider);
              await ref.read(paymentMethodsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return _buildPaymentMethodCard(context, method);
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
                'Failed to load payment methods',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(paymentMethodsProvider),
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
              Icons.credit_card_off,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'No Payment Methods',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Add a payment method to manage your subscription',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _addPaymentMethod(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, Map<String, dynamic> method) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = method['brand'] as String? ?? 'card';
    final last4 = method['last4'] as String? ?? '****';
    final expMonth = method['expMonth'] as int? ?? 0;
    final expYear = method['expYear'] as int? ?? 0;
    final isDefault = method['isDefault'] as bool? ?? false;

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
                    color: _getCardColor(brand).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    _getCardIcon(brand),
                    color: _getCardColor(brand),
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
                          Text(
                            '${_capitalizeFirst(brand)} •••• $last4',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: AppSizes.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expires ${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'set_default') {
                      _setDefaultPaymentMethod(context, method['id'] as String);
                    } else if (value == 'remove') {
                      _removePaymentMethod(context, method['id'] as String);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: AppSizes.sm),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          SizedBox(width: AppSizes.sm),
                          Text('Remove', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american_express':
        return Icons.credit_card_outlined;
      case 'discover':
        return Icons.credit_card;
      case 'diners':
      case 'diners_club':
        return Icons.payment;
      case 'jcb':
        return Icons.credit_card;
      case 'unionpay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  Color _getCardColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1434CB); // Visa blue
      case 'mastercard':
        return const Color(0xFFEB001B); // Mastercard red
      case 'amex':
      case 'american_express':
        return const Color(0xFF006FCF); // Amex blue
      case 'discover':
        return const Color(0xFFFF6000); // Discover orange
      case 'diners':
      case 'diners_club':
        return const Color(0xFF0079BE); // Diners blue
      case 'jcb':
        return const Color(0xFF0E4C96); // JCB blue
      case 'unionpay':
        return const Color(0xFFE21836); // UnionPay red
      default:
        return AppColors.primaryTeal; // Default to app color
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _addPaymentMethod(BuildContext context) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await PaymentService().presentPaymentMethodSheet();

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.invalidate(paymentMethodsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add payment method'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(BuildContext context, String paymentMethodId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await PaymentService().setDefaultPaymentMethod(paymentMethodId);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.invalidate(paymentMethodsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update default payment method'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _removePaymentMethod(BuildContext context, String paymentMethodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await PaymentService().removePaymentMethod(paymentMethodId);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed'),
            backgroundColor: AppColors.success,
          ),
        );

        ref.invalidate(paymentMethodsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove payment method'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
