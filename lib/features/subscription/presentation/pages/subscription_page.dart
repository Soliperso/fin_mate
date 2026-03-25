import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/subscription_status_card.dart';

/// Page for managing subscription and billing
class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Subscription'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: subscriptionStatus.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (status) {
          if (status == null) {
            return const Center(
              child: Text('Unable to load subscription status'),
            );
          }

          final tier = status['subscription_tier'] as String? ?? 'freemium';
          final isPremium = tier == 'premium';

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh subscription data
              ref.invalidate(subscriptionStatusProvider);
              await ref.read(subscriptionStatusProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription Status Card
                  const SubscriptionStatusCard(),

                  const SizedBox(height: AppSizes.xl),

                  // Actions Section
                  if (isPremium) ...[
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.creditcard,
                      title: 'Payment Methods',
                      subtitle: 'Manage your payment methods',
                      onTap: () => context.push('/profile/subscription/payment-methods'),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.doc_text,
                      title: 'Billing History',
                      subtitle: 'View invoices and payment history',
                      onTap: () => context.push('/profile/subscription/billing-history'),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.xmark_circle,
                      title: 'Cancel Subscription',
                      subtitle: 'Cancel your premium subscription',
                      isDestructive: true,
                      onTap: () => _showCancelDialog(context, ref),
                    ),
                  ] else ...[
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.star_fill,
                      title: 'Upgrade to Premium',
                      subtitle: 'Unlock unlimited AI insights and more',
                      onTap: () => context.push('/pricing'),
                    ),
                  ],

                  const SizedBox(height: AppSizes.xl),

                  // Features Section
                  Text(
                    isPremium ? 'Your Premium Features' : 'Premium Features',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),

                  _buildFeaturesList(isPremium),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error, size: 48),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Failed to load subscription',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(subscriptionStatusProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: EdgeInsets.zero,
      enableGlass: false,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1)
                : AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primaryTeal,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(CupertinoIcons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeaturesList(bool isPremium) {
    final features = [
      _FeatureItem(
        icon: CupertinoIcons.chat_bubble,
        title: 'Unlimited AI Insights',
        description: 'Ask unlimited questions about your finances',
        isActive: isPremium,
      ),
      _FeatureItem(
        icon: CupertinoIcons.doc_text,
        title: 'Receipt Scanning',
        description: 'Scan and store receipts automatically',
        isActive: isPremium,
      ),
      _FeatureItem(
        icon: CupertinoIcons.clock,
        title: 'Unlimited History',
        description: 'Access all your financial data, forever',
        isActive: isPremium,
      ),
      _FeatureItem(
        icon: CupertinoIcons.money_dollar_circle,
        title: 'Savings Goals',
        description: 'Track and achieve your savings targets',
        isActive: isPremium,
      ),
      _FeatureItem(
        icon: CupertinoIcons.chart_bar,
        title: 'Advanced Analytics',
        description: 'Detailed insights and forecasting',
        isActive: isPremium,
      ),
      _FeatureItem(
        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
        title: 'Priority Support',
        description: 'Get help faster when you need it',
        isActive: isPremium,
      ),
    ];

    return Column(
      children: features.map((feature) => _buildFeatureItem(feature)).toList(),
    );
  }

  Widget _buildFeatureItem(_FeatureItem feature) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSizes.lg),
            enableGlass: false,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: feature.isActive
                        ? AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? AppColors.cardBackgroundDark : AppColors.lightGray),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    feature.icon,
                    color: feature.isActive ? AppColors.success : AppColors.textSecondary,
                    size: 24,
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
                              feature.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (feature.isActive)
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
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
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
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    // Capture the page context before showing dialog
    final pageContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Are you sure you want to cancel your premium subscription? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Premium'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Use page context, not dialog context
              _cancelSubscription(pageContext, ref);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription(BuildContext context, WidgetRef ref) async {
    // Get user first
    final user = ref.read(authNotifierProvider).user;
    if (user == null) {
      if (mounted && context.mounted) {
        _showError(context, 'User not authenticated');
      }
      return;
    }

    // Show loading dialog
    if (!mounted || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      // Cancel subscription via Edge Function
      final paymentService = PaymentService();
      final result = await paymentService.cancelSubscription(user.id);

      // Dismiss loading dialog
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Small delay for UI stability
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted || !context.mounted) return;

      // Parse response
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown error';
      final statusCode = result['statusCode'] as int?;

      if (success) {
        ref.invalidate(subscriptionStatusProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Handle error response
        String errorMessage = message;

        if (statusCode == 403 || message.contains('Admin users')) {
          errorMessage = 'Admin subscriptions cannot be canceled through this interface. '
              'Your premium access is managed by the system.';
        } else if (statusCode == 404 || message.contains('No active subscription')) {
          errorMessage = 'No active subscription found to cancel.';
        }

        _showError(context, errorMessage);
      }
    } catch (e) {
      // Dismiss loading on error
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted && context.mounted) {
        _showError(context, 'An error occurred: ${e.toString()}');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    debugPrint('[SubscriptionPage] Showing error dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Cancel'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
  });
}
