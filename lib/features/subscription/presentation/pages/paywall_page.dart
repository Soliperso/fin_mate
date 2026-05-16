import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoadingOfferings = true;
  bool _isPurchasing = false;
  String? _loadError;

  static const _benefits = [
    (CupertinoIcons.sparkles, 'Unlimited AI Insights', 'vs. 10/month on free'),
    (
      CupertinoIcons.camera,
      'Receipt scanning with OCR',
      'Auto-fill transaction details'
    ),
    (
      CupertinoIcons.doc_on_doc,
      'Document storage & tax exports',
      'Receipts saved forever'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _loadError = null;
    });
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        _offerings = offerings;
        _selectedPackage =
            offerings.current?.annual ?? offerings.current?.monthly;
        _isLoadingOfferings = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load pricing. Please try again.';
        _isLoadingOfferings = false;
      });
    }
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null || _isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(_selectedPackage!),
      );
      if (result.customerInfo.entitlements.active.containsKey('premium')) {
        await supabase.from('user_profiles').update({
          'subscription_tier': 'premium',
          'subscription_status': 'active',
        }).eq('id', supabase.auth.currentUser!.id);

        ref.invalidate(isPremiumProvider);
        ref.invalidate(subscriptionTierProvider);

        if (mounted) Navigator.of(context).pop(true);
      }
    } on PurchasesError catch (e) {
      if (e.code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
      if (mounted) setState(() => _isPurchasing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      final result = await Purchases.restorePurchases();
      ref.invalidate(isPremiumProvider);
      ref.invalidate(subscriptionTierProvider);

      if (result.entitlements.active.containsKey('premium')) {
        if (mounted) Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.splashTeal : const Color(0xFFF0FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark,
              color: isDark ? Colors.white70 : AppColors.brandTeal),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: _isLoadingOfferings
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildError()
                : _buildContent(isDark),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 48, color: AppColors.systemRed),
            const SizedBox(height: AppSizes.md),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.systemRed)),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final current = _offerings?.current;
    final annualPkg = current?.annual;
    final monthlyPkg = current?.monthly;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.15),
            ),
            child: const Icon(CupertinoIcons.star_fill,
                size: 36, color: AppColors.brandTeal),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Unlock Finmate Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Start your 7-day free trial — cancel anytime.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.systemGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Benefits ──────────────────────────────────────────────
          ..._benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(b.$1, color: AppColors.brandTeal, size: 20),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(b.$3,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.systemGray)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSizes.lg),

          // ── Pricing cards ─────────────────────────────────────────
          if (annualPkg != null) _buildPriceCard(annualPkg, isAnnual: true),
          if (annualPkg != null && monthlyPkg != null)
            const SizedBox(height: AppSizes.sm),
          if (monthlyPkg != null) _buildPriceCard(monthlyPkg, isAnnual: false),
          const SizedBox(height: AppSizes.xl),

          // ── CTA ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md + 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: _isPurchasing
                  ? const LoadingIndicator(color: Colors.white)
                  : const Text(
                      'Start 7-Day Free Trial',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Cancel anytime. Billed through the App Store.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.systemGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              'Restore Purchase',
              style: TextStyle(color: AppColors.systemGray, fontSize: 13),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Package pkg, {required bool isAnnual}) {
    final isSelected = _selectedPackage?.identifier == pkg.identifier;
    final price = pkg.storeProduct.priceString;
    final title = isAnnual ? 'Annual' : 'Monthly';
    final subtitle = isAnnual ? '$price / year — save 58%' : '$price / month';

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = pkg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.brandTeal : AppColors.systemGray4,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          color: isSelected
              ? AppColors.brandTeal.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.brandTeal : AppColors.systemGray3,
                  width: 2,
                ),
                color: isSelected ? AppColors.brandTeal : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (isAnnual) ...[
                        const SizedBox(width: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandTeal,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Text(
                            'Most Popular',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.systemGray)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
