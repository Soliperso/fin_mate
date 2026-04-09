import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Card displaying current subscription status
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return subscriptionStatus.when(
      data: (status) {
        if (status == null) {
          return const _LoadingCard();
        }

        final tier = status['subscription_tier'] as String? ?? 'freemium';
        final subscriptionStatus = status['subscription_status'] as String?;
        final endDate = status['subscription_end_date'] as String?;
        final trialEndDate = status['trial_end_date'] as String?;

        final isPremium = tier == 'premium';
        final isTrialing = subscriptionStatus == 'trialing';
        final isCanceled = subscriptionStatus == 'canceled';

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          enableGlass: false,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isPremium ? CupertinoIcons.star_fill : CupertinoIcons.person_crop_circle,
                    color: isPremium ? AppColors.warning : AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Premium Plan' : 'Free Plan',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isTrialing)
                          const Text(
                            'Free Trial Active',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          )
                        else if (isCanceled)
                          const Text(
                            'Canceled',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          )
                        else if (isPremium)
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? AppColors.cardBackgroundDark : AppColors.lightGray),
                          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        ),
                        child: Text(
                          tier.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPremium ? AppColors.warning : AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Subscription details
              if (isPremium && isTrialing && trialEndDate != null) ...[
                _DetailRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Trial ends',
                  value: _formatDate(trialEndDate),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: CupertinoIcons.info_circle,
                  label: 'Status',
                  value: 'You won\'t be charged until trial ends',
                  valueColor: AppColors.textSecondary,
                ),
              ] else if (isPremium && isCanceled && endDate != null) ...[
                _DetailRow(
                  icon: CupertinoIcons.calendar_badge_minus,
                  label: 'Access until',
                  value: _formatDate(endDate),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: CupertinoIcons.info_circle,
                  label: 'Status',
                  value: 'Your subscription will end on this date',
                  valueColor: AppColors.error,
                ),
              ] else if (isPremium && endDate != null) ...[
                _DetailRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Next billing date',
                  value: _formatDate(endDate),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: CupertinoIcons.money_dollar,
                  label: 'Amount',
                  value: '\$9.99/month',
                ),
              ] else if (isPremium) ...[
                // Premium user without billing date (e.g., admin with manual premium)
                const _DetailRow(
                  icon: CupertinoIcons.checkmark_shield,
                  label: 'Status',
                  value: 'All premium features unlocked',
                  valueColor: AppColors.success,
                ),
              ] else ...[
                // Freemium user
                const _DetailRow(
                  icon: CupertinoIcons.info_circle,
                  label: 'Current plan',
                  value: 'Limited features available',
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (error, stack) => GlassContainer(
        padding: const EdgeInsets.all(20),
        enableGlass: false,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Column(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load subscription status',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(subscriptionStatusProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      enableGlass: false,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
