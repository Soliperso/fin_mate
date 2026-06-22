import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
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
    (
      CupertinoIcons.sparkles,
      'Unlimited AI financial insights',
      'Ask anything, get instant answers'
    ),
    (
      CupertinoIcons.camera,
      'Receipt scanning with OCR',
      'Auto-fill transaction details'
    ),
    (
      CupertinoIcons.clock,
      'Unlimited transaction history',
      'Access all your data, forever'
    ),
    (
      CupertinoIcons.chart_bar_square,
      'Advanced analytics & trends',
      'Deeper insights into your money'
    ),
    (
      CupertinoIcons.doc_on_doc,
      'Tax document export',
      'Reports ready for tax season'
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Defer until after first frame so the loading indicator renders before
    // RevenueCat's network + disk-cache work starts on the main thread.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOfferings());
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _loadError = null;
    });

    if (EnvConfig.revenueCatApiKey.isEmpty) {
      setState(() {
        _loadError = 'Subscription plans are coming soon. Check back after the app launches.';
        _isLoadingOfferings = false;
      });
      return;
    }

    try {
      final offerings = await Purchases.getOfferings()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (offerings.current == null) {
        setState(() {
          _loadError = 'No subscription plans are configured yet. Please try again later.';
          _isLoadingOfferings = false;
        });
        return;
      }

      setState(() {
        _offerings = offerings;
        _selectedPackage =
            offerings.current?.annual ?? offerings.current?.monthly;
        _isLoadingOfferings = false;
      });
    } on PurchasesError catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[Paywall] PurchasesError ${e.code}: ${e.message}');
      setState(() {
        _loadError = 'Could not load subscription options. Please try again.';
        _isLoadingOfferings = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[Paywall] PlatformException ${e.code}: ${e.message}');
      setState(() {
        _loadError = 'Could not load subscription options. Please try again.';
        _isLoadingOfferings = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[Paywall] Error loading offerings: $e');
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
        final entitlement = result.customerInfo.entitlements.active['premium']!;
        final isTrial = entitlement.periodType == PeriodType.trial;
        final now = DateTime.now().toUtc().toIso8601String();
        // expirationDate is already an ISO-8601 String? in purchases_flutter
        final endDate = entitlement.expirationDate;

        await supabase.from('user_profiles').update({
          'subscription_tier': 'premium',
          'subscription_status': isTrial ? 'trialing' : 'active',
          'payment_provider': 'apple',
          'subscription_start_date': now,
          'subscription_end_date': endDate,
          'trial_end_date': isTrial ? endDate : null,
        }).eq('id', supabase.auth.currentUser!.id);

        ref.invalidate(isPremiumProvider);
        ref.invalidate(subscriptionTierProvider);
        // Clear the local query count so the banner disappears immediately
        ref.read(aiQueryOperationsProvider).resetQueryCount();

        if (mounted) {
          await _showWelcomeToPremium(isTrial: isTrial);
          if (mounted) context.pop(true);
        }
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

  Future<void> _showWelcomeToPremium({required bool isTrial}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor:
              isDark ? AppColors.secondarySystemBackgroundDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.xl, AppSizes.lg, AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.brandTeal, AppColors.brandTealLight],
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Welcome to Premium!',
                  style:
                      Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  isTrial
                      ? 'Your 7-day free trial is active. Enjoy unlimited AI insights, advanced analytics, and every premium feature.'
                      : 'You now have unlimited AI insights, advanced analytics, and every premium feature.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppColors.systemGray,
                        height: 1.35,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Start Exploring',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restorePurchases() async {
    try {
      final result = await Purchases.restorePurchases();
      ref.invalidate(isPremiumProvider);
      ref.invalidate(subscriptionTierProvider);

      if (result.entitlements.active.containsKey('premium')) {
        if (mounted) context.pop(true);
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
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.xmark,
            onTap: () => context.pop(false),
            backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
            iconColor: Colors.white,
          ),
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

    final reason =
        GoRouterState.of(context).uri.queryParameters['reason'] ?? '';
    final headline = reason == 'ai_limit'
        ? 'You\'ve used all 10 free AI queries'
        : 'Unlock Finmate Premium';
    final subheadline = reason == 'ai_limit'
        ? 'Go Premium to keep asking — no limits, ever.'
        : 'Start your 7-day free trial — cancel anytime.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.20),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandTeal.withValues(alpha: 0.20),
                ),
                child: const Icon(CupertinoIcons.star_fill,
                    size: 26, color: AppColors.brandTeal),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            headline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subheadline,
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
                    const SizedBox(width: AppSizes.sm),
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: AppColors.systemGreen,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandTeal, AppColors.brandTealLight],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.md + 2),
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
    final subtitle = isAnnual
        ? '\$${(pkg.storeProduct.price / 12).toStringAsFixed(2)} / month · $price billed annually · save 58%'
        : '$price / month';

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
