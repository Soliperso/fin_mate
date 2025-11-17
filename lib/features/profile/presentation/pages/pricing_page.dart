import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/subscription_provider.dart';

/// Pricing page showing freemium and premium plans
class PricingPage extends ConsumerWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionTier = ref.watch(subscriptionTierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        elevation: 0,
      ),
      body: subscriptionTier.when(
        data: (tier) => _buildContent(context, ref, tier),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String? tier) {
    final isPremium = tier == 'premium';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Unlock powerful features to manage your finances better',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Freemium Plan
            _buildPlanCard(
              context,
              title: 'Freemium',
              price: 'Free',
              description: 'Perfect for getting started',
              features: const [
                'Track expenses and income',
                'Budget management',
                'Basic analytics',
                'Multi-account support',
              ],
              isSelected: !isPremium,
              onTap: () {}, // Already on this plan
              buttonLabel: isPremium ? 'Downgrade?' : 'Current Plan',
              buttonEnabled: isPremium,
            ),
            const SizedBox(height: AppSizes.md),

            // Premium Plan
            _buildPlanCard(
              context,
              title: 'Premium',
              price: '\$4.99',
              priceSubtitle: '/month',
              description: 'Everything you need to master finances',
              features: const [
                'All Freemium features',
                '📱 Receipt scanning & organization',
                '🤖 AI-powered expense insights',
                '📊 Advanced analytics & forecasting',
                'Unlimited transaction categories',
                'Priority support',
              ],
              isSelected: isPremium,
              onTap: isPremium ? null : () => _showUpgradeDialog(context),
              buttonLabel: isPremium ? 'Your Plan' : 'Upgrade Now',
              buttonEnabled: !isPremium,
              isPremium: true,
            ),
            const SizedBox(height: AppSizes.lg),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSizes.md),

            _buildFaqItem(
              context,
              question: 'Can I cancel anytime?',
              answer: 'Yes, you can cancel your subscription at any time.',
            ),
            _buildFaqItem(
              context,
              question: 'Is there a free trial?',
              answer: 'We offer a 7-day free trial for Premium features.',
            ),
            _buildFaqItem(
              context,
              question: 'What payment methods do you accept?',
              answer:
                  'We accept all major credit cards and payment methods through our secure payment processor.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    String? priceSubtitle,
    required String description,
    required List<String> features,
    required bool isSelected,
    required VoidCallback? onTap,
    required String buttonLabel,
    required bool buttonEnabled,
    bool isPremium = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primaryTeal : AppColors.textTertiary.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: isSelected
            ? AppColors.primaryTeal.withValues(alpha: 0.05)
            : AppColors.white,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    if (isSelected)
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
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (priceSubtitle != null) ...[
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        priceSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Features
                Column(
                  children: features
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppColors.primaryTeal,
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSizes.md),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: buttonEnabled ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.primaryTeal : AppColors.white,
                      foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryTeal : AppColors.textTertiary,
                      ),
                      disabledBackgroundColor: isSelected ? AppColors.primaryTeal : AppColors.lightGray,
                      disabledForegroundColor: AppColors.textSecondary,
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppSizes.radiusMd),
                    bottomLeft: Radius.circular(AppSizes.radiusMd),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Coming Soon'),
        content: const Text(
          'Payment integration is coming soon. For now, please contact our support team to upgrade to Premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
